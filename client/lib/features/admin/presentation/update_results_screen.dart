import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/network/api_client.dart';
import '../../../core/constants/api_constants.dart';
import '../../../shared/widgets/cream_scaffold.dart';
import '../../../shared/widgets/empty_state.dart';
import '../data/admin_repository.dart';

enum _Action { advance, eliminate, noShow }

class UpdateResultsScreen extends StatefulWidget {
  final String tournamentId;
  const UpdateResultsScreen({super.key, required this.tournamentId});

  @override
  State<UpdateResultsScreen> createState() => _UpdateResultsScreenState();
}

class _UpdateResultsScreenState extends State<UpdateResultsScreen> {
  // Simulated participant data — real app loads from API
  final List<_AdminParticipant> _participants = List.generate(
    12,
    (i) => _AdminParticipant(
      id: 'p_$i',
      queueNumber: i + 1,
      name: 'Player ${i + 1}',
      status: 'active',
    ),
  );

  int _currentRound = 1;
  bool _isBroadcasting = false;
  final _announcementController = TextEditingController();

  @override
  void dispose() {
    _announcementController.dispose();
    super.dispose();
  }

  Future<void> _updateStatus(
      _AdminParticipant participant, _Action action) async {
    final newStatus = switch (action) {
      _Action.advance => 'advancing',
      _Action.eliminate => 'eliminated',
      _Action.noShow => 'eliminated',
    };

    final confirmed = await _confirm(
      context,
      title: '${_actionLabel(action)} ${participant.name}?',
      body: _actionDescription(action, participant.name),
      confirmLabel: _actionLabel(action),
      confirmColor: _actionColor(action),
    );
    if (!confirmed || !mounted) return;

    setState(() => participant.status = newStatus);
    // In real app: await adminRepo.updateParticipantStatus(participant.id, newStatus);
    // WebSocket broadcast happens server-side after the PATCH
  }

  Future<void> _postAnnouncement() async {
    if (_announcementController.text.trim().isEmpty) return;
    setState(() => _isBroadcasting = true);
    await Future.delayed(const Duration(milliseconds: 800)); // Simulated
    setState(() {
      _isBroadcasting = false;
      _announcementController.clear();
    });
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Announcement broadcast to all viewers'),
          backgroundColor: AppColors.success,
        ),
      );
    }
  }

  Future<void> _endTournament() async {
    final winner = _participants.firstWhere(
        (p) => p.status == 'advancing',
        orElse: () => _participants.first);

    final confirmed = await _confirm(
      context,
      title: 'End Tournament?',
      body: 'This will mark the tournament as completed. '
          '${winner.name} will be declared the winner.',
      confirmLabel: 'End Tournament',
      confirmColor: AppColors.primaryBrand,
    );
    if (!confirmed) return;
    setState(() => winner.status = 'winner');
    if (mounted) context.pop();
  }

  @override
  Widget build(BuildContext context) {
    final active =
        _participants.where((p) => p.status == 'active').length;
    final eliminated =
        _participants.where((p) => p.status == 'eliminated').length;

    return CreamScaffold(
      appBar: AppBar(
        title: Text('Live Control', style: AppTypography.titleLarge),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.go('/admin');
            }
          },
        ),
        actions: [
          _LiveIndicator(activeCount: active),
          const SizedBox(width: 12),
        ],
      ),
      body: Column(
        children: [
          // ── Summary strip ──────────────────────────────────────
          Container(
            color: AppColors.surface,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            child: Row(
              children: [
                _SummaryPill(
                    label: 'Active', count: active, color: AppColors.success),
                const SizedBox(width: 8),
                _SummaryPill(
                    label: 'Out',
                    count: eliminated,
                    color: AppColors.eliminated),
                const Spacer(),
                // Round selector
                Row(
                  children: [
                    Text('Round', style: AppTypography.labelMedium),
                    const SizedBox(width: 6),
                    DropdownButton<int>(
                      value: _currentRound,
                      underline: const SizedBox(),
                      isDense: true,
                      style: AppTypography.labelLarge
                          .copyWith(color: AppColors.primaryBrand),
                      items: List.generate(
                          3,
                          (i) => DropdownMenuItem(
                              value: i + 1,
                              child: Text('${i + 1}'))),
                      onChanged: (v) =>
                          setState(() => _currentRound = v ?? 1),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // ── Participant list ────────────────────────────────────
          Expanded(
            child: _participants.isEmpty
                ? EmptyState.noParticipants()
                : ListView.builder(
                    padding: const EdgeInsets.only(top: 8, bottom: 100),
                    itemCount: _participants.length,
                    itemBuilder: (_, i) =>
                        _AdminParticipantTile(
                          participant: _participants[i],
                          onAdvance: _participants[i].status == 'active'
                              ? () => _updateStatus(
                                  _participants[i], _Action.advance)
                              : null,
                          onEliminate: _participants[i].status == 'active'
                              ? () => _updateStatus(
                                  _participants[i], _Action.eliminate)
                              : null,
                          onNoShow: _participants[i].status == 'active'
                              ? () => _updateStatus(
                                  _participants[i], _Action.noShow)
                              : null,
                        ),
                  ),
          ),

          // ── Bottom control panel ────────────────────────────────
          Container(
            padding: EdgeInsets.fromLTRB(
                16, 12, 16, MediaQuery.of(context).padding.bottom + 12),
            decoration: BoxDecoration(
              color: AppColors.surface,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.08),
                  blurRadius: 12,
                  offset: const Offset(0, -4),
                )
              ],
            ),
            child: Column(
              children: [
                // Announcement field
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _announcementController,
                        decoration: const InputDecoration(
                          hintText: 'Post a round update...',
                          isDense: true,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    IconButton(
                      icon: _isBroadcasting
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: AppColors.primaryBrand),
                            )
                          : const Icon(Icons.send_rounded,
                              color: AppColors.primaryBrand),
                      onPressed:
                          _isBroadcasting ? null : _postAnnouncement,
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _endTournament,
                    icon: const Icon(Icons.flag_rounded),
                    label: const Text('End Tournament'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.error,
                      minimumSize: const Size(double.infinity, 46),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _actionLabel(_Action a) => switch (a) {
        _Action.advance => 'Advance',
        _Action.eliminate => 'Eliminate',
        _Action.noShow => 'No Show',
      };

  String _actionDescription(_Action a, String name) => switch (a) {
        _Action.advance =>
          'Mark $name as advancing to the next round. This will be broadcast live.',
        _Action.eliminate =>
          'Mark $name as eliminated. This will be broadcast live to all viewers.',
        _Action.noShow =>
          'Mark $name as a no-show. They will be eliminated from the tournament.',
      };

  Color _actionColor(_Action a) => switch (a) {
        _Action.advance => AppColors.success,
        _Action.eliminate => AppColors.error,
        _Action.noShow => AppColors.eliminated,
      };

  Future<bool> _confirm(
    BuildContext context, {
    required String title,
    required String body,
    required String confirmLabel,
    required Color confirmColor,
  }) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: AppTheme.cardRadius),
        title: Text(title, style: AppTypography.headlineSmall),
        content: Text(body, style: AppTypography.bodySmall),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
                backgroundColor: confirmColor),
            child: Text(confirmLabel),
          ),
        ],
      ),
    );
    return result ?? false;
  }
}

// ─── Local models ─────────────────────────────────────────────────────────────
class _AdminParticipant {
  final String id;
  final int queueNumber;
  final String name;
  String status;

  _AdminParticipant({
    required this.id,
    required this.queueNumber,
    required this.name,
    required this.status,
  });
}

// ─── AdminParticipantTile ─────────────────────────────────────────────────────
class _AdminParticipantTile extends StatelessWidget {
  final _AdminParticipant participant;
  final VoidCallback? onAdvance;
  final VoidCallback? onEliminate;
  final VoidCallback? onNoShow;

  const _AdminParticipantTile({
    required this.participant,
    this.onAdvance,
    this.onEliminate,
    this.onNoShow,
  });

  Color get _statusColor => switch (participant.status) {
        'active' => AppColors.success,
        'advancing' => AppColors.primaryBrand,
        'eliminated' => AppColors.eliminated,
        'winner' => AppColors.primaryBrand,
        _ => AppColors.textSecondary,
      };

  @override
  Widget build(BuildContext context) {
    final isActive = participant.status == 'active';
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: isActive ? AppColors.surface : const Color(0xFFF5F5F5),
        borderRadius: AppTheme.cardRadius,
        border: Border(
          left: BorderSide(color: _statusColor, width: 3),
        ),
        boxShadow: isActive ? [AppTheme.cardShadow] : [],
      ),
      child: Row(
        children: [
          // Queue number
          CircleAvatar(
            radius: 20,
            backgroundColor: _statusColor.withOpacity(0.15),
            child: Text(
              '#${participant.queueNumber}',
              style: AppTypography.labelSmall
                  .copyWith(color: _statusColor, fontWeight: FontWeight.w700),
            ),
          ),
          const SizedBox(width: 12),

          // Name + status
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(participant.name,
                    style: AppTypography.labelLarge.copyWith(
                      color: isActive
                          ? AppColors.textPrimary
                          : AppColors.eliminated,
                      decoration: participant.status == 'eliminated'
                          ? TextDecoration.lineThrough
                          : null,
                    )),
                Text(
                  participant.status[0].toUpperCase() +
                      participant.status.substring(1),
                  style: AppTypography.caption.copyWith(color: _statusColor),
                ),
              ],
            ),
          ),

          // Action buttons (only for active)
          if (isActive) ...[
            _ActionBtn(
                label: '✓',
                tooltip: 'Advance',
                color: AppColors.success,
                onTap: onAdvance),
            const SizedBox(width: 6),
            _ActionBtn(
                label: '✗',
                tooltip: 'Eliminate',
                color: AppColors.error,
                onTap: onEliminate),
            const SizedBox(width: 6),
            _ActionBtn(
                label: '⊘',
                tooltip: 'No Show',
                color: AppColors.eliminated,
                onTap: onNoShow),
          ] else
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: _statusColor.withOpacity(0.1),
                borderRadius: AppTheme.chipRadius,
              ),
              child: Text(
                participant.status[0].toUpperCase() +
                    participant.status.substring(1),
                style: AppTypography.labelSmall
                    .copyWith(color: _statusColor, fontSize: 11),
              ),
            ),
        ],
      ),
    );
  }
}

class _ActionBtn extends StatelessWidget {
  final String label;
  final String tooltip;
  final Color color;
  final VoidCallback? onTap;

  const _ActionBtn(
      {required this.label,
      required this.tooltip,
      required this.color,
      this.onTap});

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: color.withOpacity(0.12),
            borderRadius: AppTheme.chipRadius,
            border: Border.all(color: color.withOpacity(0.3)),
          ),
          child: Center(
            child: Text(label,
                style: TextStyle(
                    color: color,
                    fontSize: 16,
                    fontWeight: FontWeight.w700)),
          ),
        ),
      ),
    );
  }
}

// ─── Summary pill ─────────────────────────────────────────────────────────────
class _SummaryPill extends StatelessWidget {
  final String label;
  final int count;
  final Color color;
  const _SummaryPill(
      {required this.label, required this.count, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: AppTheme.chipRadius,
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Text('$count $label',
          style: AppTypography.labelSmall
              .copyWith(color: color, fontWeight: FontWeight.w700)),
    );
  }
}

// ─── Live indicator ───────────────────────────────────────────────────────────
class _LiveIndicator extends StatefulWidget {
  final int activeCount;
  const _LiveIndicator({required this.activeCount});

  @override
  State<_LiveIndicator> createState() => _LiveIndicatorState();
}

class _LiveIndicatorState extends State<_LiveIndicator>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 800))
      ..repeat(reverse: true);
    _anim = Tween<double>(begin: 0.3, end: 1.0).animate(_ctrl);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.error.withOpacity(0.1),
        borderRadius: AppTheme.chipRadius,
        border: Border.all(color: AppColors.error.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          FadeTransition(
            opacity: _anim,
            child: const CircleAvatar(
                radius: 4, backgroundColor: AppColors.error),
          ),
          const SizedBox(width: 5),
          Text('LIVE · ${widget.activeCount}',
              style: AppTypography.labelSmall.copyWith(
                  color: AppColors.error, fontWeight: FontWeight.w800)),
        ],
      ),
    );
  }
}

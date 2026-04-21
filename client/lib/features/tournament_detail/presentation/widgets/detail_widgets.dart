import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:percent_indicator/percent_indicator.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/formatters.dart';
import '../../../home/data/models/tournament_model.dart';

// ─── ParticipantCountChip ─────────────────────────────────────────────────────
class ParticipantCountChip extends StatelessWidget {
  final int registered;
  final int max;

  const ParticipantCountChip(
      {super.key, required this.registered, required this.max});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: AppTheme.chipRadius,
        border: Border.all(color: AppColors.divider),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.people_outline,
              color: AppColors.primaryBrand, size: 16),
          const SizedBox(width: 6),
          Text('$registered / $max',
              style: AppTypography.labelMedium
                  .copyWith(color: AppColors.primaryBrand)),
        ],
      ),
    );
  }
}

// ─── RulesSection ─────────────────────────────────────────────────────────────
class RulesSection extends StatefulWidget {
  final String rules;
  const RulesSection({super.key, required this.rules});

  @override
  State<RulesSection> createState() => _RulesSectionState();
}

class _RulesSectionState extends State<RulesSection> {
  bool _expanded = false;
  static const int _previewLines = 4;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: AppTheme.cardDecoration,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.rule_rounded,
                  color: AppColors.primaryBrand, size: 20),
              const SizedBox(width: 8),
              Text('Rules', style: AppTypography.headlineSmall),
            ],
          ),
          const SizedBox(height: 12),
          AnimatedCrossFade(
            duration: const Duration(milliseconds: 300),
            crossFadeState: _expanded
                ? CrossFadeState.showSecond
                : CrossFadeState.showFirst,
            firstChild: Text(
              widget.rules,
              style: AppTypography.bodyMedium,
              maxLines: _previewLines,
              overflow: TextOverflow.ellipsis,
            ),
            secondChild: Text(widget.rules, style: AppTypography.bodyMedium),
          ),
          const SizedBox(height: 8),
          GestureDetector(
            onTap: () => setState(() => _expanded = !_expanded),
            child: Text(
              _expanded ? 'Show less' : 'Read more',
              style: AppTypography.labelMedium
                  .copyWith(color: AppColors.primaryBrand),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── RoundsSection ────────────────────────────────────────────────────────────
class RoundsSection extends StatelessWidget {
  final List<RoundSummary> rounds;
  const RoundsSection({super.key, required this.rounds});

  @override
  Widget build(BuildContext context) {
    if (rounds.isEmpty) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              const Icon(Icons.format_list_numbered_rounded,
                  color: AppColors.primaryBrand, size: 20),
              const SizedBox(width: 8),
              Text('Rounds', style: AppTypography.headlineSmall),
            ],
          ),
        ),
        const SizedBox(height: 12),
        ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 16),
          itemCount: rounds.length,
          separatorBuilder: (_, __) => const SizedBox(height: 8),
          itemBuilder: (_, i) => _RoundCard(round: rounds[i], index: i),
        ),
      ],
    );
  }
}

class _RoundCard extends StatelessWidget {
  final RoundSummary round;
  final int index;
  const _RoundCard({required this.round, required this.index});

  @override
  Widget build(BuildContext context) {
    final (statusColor, statusLabel) = switch (round.status) {
      'active' => (AppColors.success, 'Live'),
      'completed' => (AppColors.eliminated, 'Done'),
      _ => (AppColors.primaryBrand, 'Upcoming'),
    };

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: AppTheme.cardRadius,
        border: Border(
          left: BorderSide(color: statusColor, width: 3),
        ),
        boxShadow: [AppTheme.cardShadow],
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 18,
            backgroundColor: statusColor.withOpacity(0.15),
            child: Text('${index + 1}',
                style: AppTypography.labelMedium
                    .copyWith(color: statusColor)),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(round.name, style: AppTypography.labelLarge),
                if (round.scheduledAt != null)
                  Text(DateFormatter.formatTime(round.scheduledAt!),
                      style: AppTypography.caption),
              ],
            ),
          ),
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: statusColor.withOpacity(0.1),
              borderRadius: AppTheme.chipRadius,
            ),
            child: Text(statusLabel,
                style: AppTypography.labelSmall
                    .copyWith(color: statusColor, fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }
}

// ─── PhotoGallerySection ──────────────────────────────────────────────────────
class PhotoGallerySection extends StatelessWidget {
  final List<String> photoUrls;
  const PhotoGallerySection({super.key, required this.photoUrls});

  @override
  Widget build(BuildContext context) {
    if (photoUrls.isEmpty) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              const Icon(Icons.photo_library_outlined,
                  color: AppColors.primaryBrand, size: 20),
              const SizedBox(width: 8),
              Text('Gallery', style: AppTypography.headlineSmall),
            ],
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 120,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.only(left: 16),
            itemCount: photoUrls.length,
            itemBuilder: (_, i) => GestureDetector(
              onTap: () => _showFullscreen(context, i),
              child: Hero(
                tag: 'gallery_$i',
                child: Container(
                  width: 140,
                  margin: const EdgeInsets.only(right: 10),
                  decoration: BoxDecoration(
                    borderRadius: AppTheme.cardRadius,
                    boxShadow: [AppTheme.cardShadow],
                  ),
                  child: ClipRRect(
                    borderRadius: AppTheme.cardRadius,
                    child: CachedNetworkImage(
                      imageUrl: photoUrls[i],
                      fit: BoxFit.cover,
                      placeholder: (_, __) => Container(
                          color: AppColors.divider),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  void _showFullscreen(BuildContext context, int initialIndex) {
    Navigator.of(context).push(MaterialPageRoute(
      fullscreenDialog: true,
      builder: (_) => _FullscreenGallery(
          photoUrls: photoUrls, initialIndex: initialIndex),
    ));
  }
}

class _FullscreenGallery extends StatefulWidget {
  final List<String> photoUrls;
  final int initialIndex;
  const _FullscreenGallery(
      {required this.photoUrls, required this.initialIndex});

  @override
  State<_FullscreenGallery> createState() => _FullscreenGalleryState();
}

class _FullscreenGalleryState extends State<_FullscreenGallery> {
  late int _current;

  @override
  void initState() {
    super.initState();
    _current = widget.initialIndex;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: Text('${_current + 1} / ${widget.photoUrls.length}',
            style: AppTypography.labelLarge.copyWith(color: Colors.white)),
      ),
      body: PageView.builder(
        itemCount: widget.photoUrls.length,
        controller: PageController(initialPage: widget.initialIndex),
        onPageChanged: (i) => setState(() => _current = i),
        itemBuilder: (_, i) => Hero(
          tag: 'gallery_$i',
          child: Center(
            child: CachedNetworkImage(
              imageUrl: widget.photoUrls[i],
              fit: BoxFit.contain,
            ),
          ),
        ),
      ),
    );
  }
}

// ─── RegistrationSection ──────────────────────────────────────────────────────
class RegistrationSection extends StatefulWidget {
  final TournamentModel tournament;
  final bool isRegistered;
  final VoidCallback onRegister;

  const RegistrationSection({
    super.key,
    required this.tournament,
    required this.isRegistered,
    required this.onRegister,
  });

  @override
  State<RegistrationSection> createState() => _RegistrationSectionState();
}

class _RegistrationSectionState extends State<RegistrationSection> {
  Timer? _timer;
  String _countdown = '';

  @override
  void initState() {
    super.initState();
    _updateCountdown();
    _timer = Timer.periodic(const Duration(seconds: 30), (_) {
      if (mounted) _updateCountdown();
    });
  }

  void _updateCountdown() {
    final deadline = widget.tournament.registrationDeadline;
    setState(() {
      _countdown = deadline != null
          ? DateFormatter.formatRegistrationDeadline(deadline)
          : '';
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = widget.tournament;
    final spotsPercent =
        (t.registeredCount / t.maxParticipants).clamp(0.0, 1.0);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(20),
      decoration: AppTheme.goldBorderDecoration,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Entry Fee', style: AppTypography.bodySmall),
              Text(t.entryFeeFormatted,
                  style: AppTypography.headlineSmall
                      .copyWith(color: AppColors.primaryBrand)),
            ],
          ),
          const SizedBox(height: 16),

          // Spots progress bar
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Spots left: ${t.spotsLeft} / ${t.maxParticipants}',
                  style: AppTypography.caption),
              Text(
                  '${((t.registeredCount / t.maxParticipants) * 100).round()}% full',
                  style: AppTypography.caption
                      .copyWith(color: AppColors.primaryBrand)),
            ],
          ),
          const SizedBox(height: 8),
          LinearPercentIndicator(
            lineHeight: 8,
            percent: spotsPercent,
            padding: EdgeInsets.zero,
            progressColor: AppColors.primaryBrand,
            backgroundColor: AppColors.divider,
            barRadius: const Radius.circular(4),
          ),

          if (_countdown.isNotEmpty) ...[
            const SizedBox(height: 10),
            Row(
              children: [
                const Icon(Icons.schedule_rounded,
                    size: 14, color: AppColors.textSecondary),
                const SizedBox(width: 4),
                Text(_countdown, style: AppTypography.caption),
              ],
            ),
          ],
          const SizedBox(height: 16),

          if (widget.isRegistered)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 14),
              decoration: BoxDecoration(
                color: AppColors.success.withOpacity(0.1),
                borderRadius: AppTheme.buttonRadius,
                border: Border.all(color: AppColors.success.withOpacity(0.4)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.check_circle_rounded,
                      color: AppColors.success, size: 20),
                  const SizedBox(width: 8),
                  Text('You\'re Registered!',
                      style: AppTypography.labelLarge
                          .copyWith(color: AppColors.success)),
                ],
              ),
            )
          else
            _RegisterButton(onTap: widget.onRegister, label: 'Register Now — ${t.entryFeeFormatted}'),

          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.lock_outlined,
                  size: 13, color: AppColors.textSecondary),
              const SizedBox(width: 4),
              Text('Secure payment via Razorpay',
                  style: AppTypography.caption),
            ],
          ),
        ],
      ),
    );
  }
}

class _RegisterButton extends StatefulWidget {
  final VoidCallback onTap;
  final String label;
  const _RegisterButton({required this.onTap, required this.label});

  @override
  State<_RegisterButton> createState() => _RegisterButtonState();
}

class _RegisterButtonState extends State<_RegisterButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 120));
    _scale = Tween<double>(begin: 1.0, end: 0.96)
        .animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(
      scale: _scale,
      child: GestureDetector(
        onTapDown: (_) => _ctrl.forward(),
        onTapUp: (_) {
          _ctrl.reverse();
          widget.onTap();
        },
        onTapCancel: () => _ctrl.reverse(),
        child: Container(
          width: double.infinity,
          height: 54,
          decoration: BoxDecoration(
            gradient: AppColors.goldGradient,
            borderRadius: AppTheme.buttonRadius,
            boxShadow: [
              BoxShadow(
                color: AppColors.primaryBrand.withOpacity(0.35),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Center(
            child: Text(widget.label, style: AppTypography.button),
          ),
        ),
      ),
    );
  }
}

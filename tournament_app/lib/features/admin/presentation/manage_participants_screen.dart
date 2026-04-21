import 'package:flutter/material.dart';
import 'package:tournament_app/core/theme/app_colors.dart';
import 'package:tournament_app/core/theme/app_typography.dart';
import 'package:tournament_app/core/theme/app_theme.dart';
import 'package:tournament_app/shared/widgets/cream_scaffold.dart';
import 'package:tournament_app/shared/widgets/empty_state.dart';
import 'package:tournament_app/shared/widgets/gold_button.dart';
import 'package:tournament_app/features/admin/presentation/widgets/participant_management_tile.dart';

class ManageParticipantsScreen extends StatefulWidget {
  final String? tournamentId;
  const ManageParticipantsScreen({super.key, this.tournamentId});

  @override
  State<ManageParticipantsScreen> createState() =>
      _ManageParticipantsScreenState();
}

class _ManageParticipantsScreenState
    extends State<ManageParticipantsScreen> {
  final _searchController = TextEditingController();
  String _activeFilter = 'All';
  String _searchQuery = '';
  bool _isExporting = false;

  final List<String> _filters = ['All', 'Active', 'Eliminated', 'Tomorrow'];

  // Simulated data — real app loads from AdminRepository
  final List<_ParticipantRecord> _all = List.generate(
    18,
    (i) => _ParticipantRecord(
      id: 'p_$i',
      name: 'Player ${i + 1}',
      queueNumber: i + 1,
      status: i % 3 == 0 ? 'eliminated' : 'active',
      phone: '+91 9876${(543210 + i).toString().padLeft(6, '0')}',
      amountPaidPaise: 20000,
      paymentId: 'pay_${i.toString().padLeft(16, 'X')}',
    ),
  );

  List<_ParticipantRecord> get _filtered {
    return _all.where((p) {
      final matchesFilter = _activeFilter == 'All' ||
          p.status.toLowerCase() == _activeFilter.toLowerCase();
      final matchesSearch = _searchQuery.isEmpty ||
          p.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          p.queueNumber.toString().contains(_searchQuery) ||
          p.phone.contains(_searchQuery);
      return matchesFilter && matchesSearch;
    }).toList();
  }

  Future<void> _exportCsv() async {
    setState(() => _isExporting = true);
    await Future.delayed(const Duration(seconds: 1));
    setState(() => _isExporting = false);
    if (mounted) showSuccessSnackbar(context, 'CSV exported successfully');
  }

  void _confirmRefund(BuildContext context, _ParticipantRecord p) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: AppTheme.cardRadius),
        title: Text('Refund ${p.name}?', style: AppTypography.headlineSmall),
        content: Text(
          'Issue a refund of ₹${(p.amountPaidPaise / 100).toStringAsFixed(0)} '
          'to ${p.name} (${p.phone})?\n\n'
          'Payment ID: ${p.paymentId}',
          style: AppTypography.bodySmall,
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              showSuccessSnackbar(context, 'Refund initiated for ${p.name}');
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            child: const Text('Issue Refund'),
          ),
        ],
      ),
    );
  }

  void _editQueue(BuildContext context, _ParticipantRecord p) {
    final ctrl = TextEditingController(text: p.queueNumber.toString());
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: AppTheme.cardRadius),
        title: Text('Edit Queue #', style: AppTypography.headlineSmall),
        content: TextField(
          controller: ctrl,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(labelText: 'Queue number'),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              final newNum = int.tryParse(ctrl.text);
              if (newNum != null) {
                setState(() => p.queueNumber = newNum);
              }
              Navigator.pop(context);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _filtered;

    return CreamScaffold(
      appBar: AppBar(
        title: Text('Participants', style: AppTypography.titleLarge),
        actions: [
          _isExporting
              ? const Padding(
                  padding: EdgeInsets.all(12),
                  child: SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: AppColors.primaryBrand)),
                )
              : IconButton(
                  icon: const Icon(Icons.download_outlined),
                  tooltip: 'Export CSV',
                  onPressed: _exportCsv,
                ),
        ],
      ),
      body: Column(
        children: [
          // ── Search + Filters ───────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            child: Column(
              children: [
                TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Search name, queue #, phone...',
                    prefixIcon: const Icon(Icons.search_rounded,
                        color: AppColors.textSecondary, size: 20),
                    suffixIcon: _searchQuery.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear_rounded, size: 18),
                            onPressed: () {
                              _searchController.clear();
                              setState(() => _searchQuery = '');
                            },
                          )
                        : null,
                    isDense: true,
                  ),
                  onChanged: (v) => setState(() => _searchQuery = v),
                ),
                const SizedBox(height: 10),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: _filters.map((f) {
                      final isActive = _activeFilter == f;
                      return GestureDetector(
                        onTap: () => setState(() => _activeFilter = f),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          margin: const EdgeInsets.only(right: 8),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 7),
                          decoration: BoxDecoration(
                            color: isActive
                                ? AppColors.primaryBrand
                                : AppColors.surface,
                            borderRadius: AppTheme.chipRadius,
                            border:
                                Border.all(color: AppColors.divider),
                          ),
                          child: Text(f,
                              style: AppTypography.labelSmall.copyWith(
                                color: isActive
                                    ? Colors.white
                                    : AppColors.textSecondary,
                                fontWeight: isActive
                                    ? FontWeight.w700
                                    : FontWeight.w500,
                              )),
                        ),
                      );
                    }).toList(),
                  ),
                ),
                const SizedBox(height: 8),
                // Count + export row
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('${filtered.length} participants',
                        style: AppTypography.caption),
                    TextButton.icon(
                      onPressed: _exportCsv,
                      icon: const Icon(Icons.file_download_outlined,
                          size: 16),
                      label: const Text('Export CSV'),
                      style: TextButton.styleFrom(
                          foregroundColor: AppColors.primaryBrand),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const Divider(height: 1),

          // ── List ──────────────────────────────────────────────
          Expanded(
            child: filtered.isEmpty
                ? EmptyState(
                    icon: Icons.search_off_rounded,
                    title: 'No results',
                    subtitle: 'Try a different search or filter.',
                  )
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 8),
                    itemCount: filtered.length,
                    itemBuilder: (_, i) {
                      final p = filtered[i];
                      return ParticipantManagementTile(
                        name: p.name,
                        queueNumber: p.queueNumber,
                        status: p.status,
                        phone: p.phone,
                        amountPaidPaise: p.amountPaidPaise,
                        paymentId: p.paymentId,
                        onRefund: () => _confirmRefund(context, p),
                        onEditQueue: () => _editQueue(context, p),
                        onViewDetails: () =>
                            _showDetails(context, p),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  void _showDetails(BuildContext context, _ParticipantRecord p) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
          borderRadius:
              BorderRadius.vertical(top: Radius.circular(24))),
      builder: (_) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                    color: AppColors.divider,
                    borderRadius: BorderRadius.circular(2)),
              ),
            ),
            const SizedBox(height: 20),
            Text(p.name, style: AppTypography.headlineSmall),
            const SizedBox(height: 4),
            Text(p.phone, style: AppTypography.bodySmall),
            const Divider(height: 24),
            _DetailRow('Queue Number', '#${p.queueNumber}'),
            _DetailRow('Status', p.status),
            _DetailRow('Amount Paid',
                '₹${(p.amountPaidPaise / 100).toStringAsFixed(0)}'),
            _DetailRow('Payment ID', p.paymentId),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () {
                      Navigator.pop(context);
                      _editQueue(context, p);
                    },
                    child: const Text('Edit Queue'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context);
                      _confirmRefund(context, p);
                    },
                    style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.error),
                    child: const Text('Refund'),
                  ),
                ),
              ],
            ),
            SizedBox(
                height: MediaQuery.of(context).padding.bottom + 8),
          ],
        ),
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final String label, value;
  const _DetailRow(this.label, this.value);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: AppTypography.bodySmall),
          Text(value, style: AppTypography.labelLarge),
        ],
      ),
    );
  }
}

class _ParticipantRecord {
  final String id;
  String name;
  int queueNumber;
  String status;
  String phone;
  int amountPaidPaise;
  String paymentId;

  _ParticipantRecord({
    required this.id,
    required this.name,
    required this.queueNumber,
    required this.status,
    required this.phone,
    required this.amountPaidPaise,
    required this.paymentId,
  });
}

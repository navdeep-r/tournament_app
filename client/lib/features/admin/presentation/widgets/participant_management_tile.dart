import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../shared/widgets/empty_state.dart';

class ParticipantManagementTile extends StatelessWidget {
  final String name;
  final int queueNumber;
  final String status;
  final String phone;
  final int amountPaidPaise;
  final String paymentId;
  final VoidCallback? onRefund;
  final VoidCallback? onEditQueue;
  final VoidCallback? onViewDetails;

  const ParticipantManagementTile({
    super.key,
    required this.name,
    required this.queueNumber,
    required this.status,
    required this.phone,
    required this.amountPaidPaise,
    required this.paymentId,
    this.onRefund,
    this.onEditQueue,
    this.onViewDetails,
  });

  Color get _statusColor => switch (status) {
        'active' => AppColors.success,
        'eliminated' => AppColors.eliminated,
        'winner' => AppColors.primaryBrand,
        _ => AppColors.textSecondary,
      };

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onViewDetails,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(14),
        decoration: AppTheme.cardDecoration,
        child: Row(
          children: [
            // Avatar
            AvatarWithStatus(name: name, radius: 22),
            const SizedBox(width: 12),

            // Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(name, style: AppTypography.labelLarge),
                      const SizedBox(width: 8),
                      _QueueBadge(number: queueNumber),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(phone, style: AppTypography.caption),
                  Text(
                    '₹${(amountPaidPaise / 100).toStringAsFixed(0)} · $paymentId',
                    style: AppTypography.caption
                        .copyWith(color: AppColors.textSecondary),
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),

            // Status + actions
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                _StatusBadge(status: status, color: _statusColor),
                const SizedBox(height: 6),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (onEditQueue != null)
                      _IconBtn(
                          icon: Icons.edit_outlined,
                          onTap: onEditQueue!,
                          tooltip: 'Edit queue'),
                    if (onRefund != null)
                      _IconBtn(
                          icon: Icons.undo_rounded,
                          onTap: onRefund!,
                          tooltip: 'Refund',
                          color: AppColors.error),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _QueueBadge extends StatelessWidget {
  final int number;
  const _QueueBadge({required this.number});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
      decoration: BoxDecoration(
        color: AppColors.primaryBrand.withOpacity(0.12),
        borderRadius: AppTheme.chipRadius,
      ),
      child: Text('#$number',
          style: AppTypography.labelSmall
              .copyWith(color: AppColors.primaryBrand, fontSize: 10)),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final String status;
  final Color color;
  const _StatusBadge({required this.status, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: AppTheme.chipRadius,
      ),
      child: Text(
        status[0].toUpperCase() + status.substring(1),
        style: AppTypography.labelSmall
            .copyWith(color: color, fontWeight: FontWeight.w700, fontSize: 10),
      ),
    );
  }
}

class _IconBtn extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final String tooltip;
  final Color color;

  const _IconBtn({
    required this.icon,
    required this.onTap,
    required this.tooltip,
    this.color = AppColors.primaryBrand,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: GestureDetector(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(4),
          child: Icon(icon, color: color, size: 18),
        ),
      ),
    );
  }
}

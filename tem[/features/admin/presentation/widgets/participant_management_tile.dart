import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/theme/app_theme.dart';

class ParticipantManagementTile extends StatelessWidget {
  final String name;
  final int queueNumber;
  final String status;
  final String phone;
  final int amountPaidPaise;
  final String paymentId;
  final VoidCallback onRefund;
  final VoidCallback onEditQueue;
  final VoidCallback onViewDetails;

  const ParticipantManagementTile({
    super.key,
    required this.name,
    required this.queueNumber,
    required this.status,
    required this.phone,
    required this.amountPaidPaise,
    required this.paymentId,
    required this.onRefund,
    required this.onEditQueue,
    required this.onViewDetails,
  });

  Color get _statusColor => switch (status.toLowerCase()) {
        'active' => AppColors.success,
        'eliminated' => AppColors.eliminated,
        'tomorrow' => AppColors.textSecondary,
        _ => AppColors.primaryBrand,
      };

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: AppTheme.cardDecoration,
      child: Row(
        children: [
          // Queue Number Badge
          CircleAvatar(
            radius: 20,
            backgroundColor: _statusColor.withOpacity(0.15),
            child: Text(
              '#$queueNumber',
              style: AppTypography.labelSmall.copyWith(
                color: _statusColor,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const SizedBox(width: 12),

          // Player Info
          Expanded(
            child: InkWell(
              onTap: onViewDetails,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: AppTypography.labelLarge,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    'Queue #$queueNumber · $phone',
                    style: AppTypography.caption,
                  ),
                  Text(
                    '₹${(amountPaidPaise / 100).toStringAsFixed(0)} · $paymentId',
                    style: AppTypography.caption.copyWith(
                      color: AppColors.textSecondary,
                      fontSize: 10,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ),

          // Actions
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                icon: const Icon(Icons.edit_outlined, size: 20),
                onPressed: onEditQueue,
                tooltip: 'Edit Queue',
                color: AppColors.primaryBrand,
              ),
              IconButton(
                icon: const Icon(Icons.history_rounded, size: 20),
                onPressed: onRefund,
                tooltip: 'Refund',
                color: AppColors.error,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

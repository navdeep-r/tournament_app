import 'package:flutter/material.dart';
import 'package:tournament_app/core/theme/app_colors.dart';
import 'package:tournament_app/core/theme/app_typography.dart';
import 'package:tournament_app/core/theme/app_theme.dart';

/// Compact order summary card shown at the top of Step 3 in checkout.
/// Displays tournament name, phone, discount, and final amount.
class OrderSummaryCard extends StatelessWidget {
  final String tournamentName;
  final String? tournamentDate;
  final String phone;
  final int originalAmountPaise;
  final int discountAmountPaise;
  final int finalAmountPaise;
  final String? referralCode;
  final VoidCallback? onEditPhone;

  const OrderSummaryCard({
    super.key,
    required this.tournamentName,
    this.tournamentDate,
    required this.phone,
    required this.originalAmountPaise,
    required this.discountAmountPaise,
    required this.finalAmountPaise,
    this.referralCode,
    this.onEditPhone,
  });

  bool get hasDiscount => discountAmountPaise > 0;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: AppTheme.goldBorderDecoration,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Tournament info
          Row(
            children: [
              const Icon(Icons.emoji_events_rounded,
                  color: AppColors.primaryBrand, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(tournamentName,
                        style: AppTypography.labelLarge,
                        overflow: TextOverflow.ellipsis),
                    if (tournamentDate != null)
                      Text(tournamentDate!,
                          style: AppTypography.caption),
                  ],
                ),
              ),
              // Final amount (large)
              Text(
                '₹${(finalAmountPaise / 100).toStringAsFixed(0)}',
                style: AppTypography.headlineMedium
                    .copyWith(color: AppColors.primaryBrand),
              ),
            ],
          ),

          const SizedBox(height: 12),
          const Divider(),
          const SizedBox(height: 8),

          // Phone with edit
          Row(
            children: [
              const Icon(Icons.phone_outlined,
                  size: 15, color: AppColors.textSecondary),
              const SizedBox(width: 6),
              Expanded(
                child: Text('+91 $phone', style: AppTypography.bodySmall),
              ),
              if (onEditPhone != null)
                GestureDetector(
                  onTap: onEditPhone,
                  child: const Icon(Icons.edit_outlined,
                      size: 15, color: AppColors.primaryBrand),
                ),
            ],
          ),

          // Queue type
          const SizedBox(height: 6),
          Row(
            children: [
              const Icon(Icons.format_list_numbered_rounded,
                  size: 15, color: AppColors.textSecondary),
              const SizedBox(width: 6),
              Text('First-come-first-served',
                  style: AppTypography.caption),
            ],
          ),

          // Discount row
          if (hasDiscount) ...[
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.success.withOpacity(0.08),
                borderRadius: AppTheme.chipRadius,
                border:
                    Border.all(color: AppColors.success.withOpacity(0.3)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.local_offer_outlined,
                      size: 13, color: AppColors.success),
                  const SizedBox(width: 5),
                  Text(
                    referralCode != null
                        ? '$referralCode applied — '
                            'Saved ₹${(discountAmountPaise / 100).toStringAsFixed(0)}'
                        : 'Saved ₹${(discountAmountPaise / 100).toStringAsFixed(0)}',
                    style: AppTypography.labelSmall
                        .copyWith(color: AppColors.success, fontSize: 11),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

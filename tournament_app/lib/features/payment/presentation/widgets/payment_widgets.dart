import 'package:flutter/material.dart';
import 'package:tournament_app/features/payment/data/models/payment_models.dart';
import 'package:tournament_app/core/theme/app_colors.dart';
import 'package:tournament_app/core/theme/app_typography.dart';
import 'package:tournament_app/core/theme/app_theme.dart';

// ─── PriceBreakdownCard ───────────────────────────────────────────────────────
/// Animated breakdown card shown after a valid referral code is applied.
/// Uses AnimatedSize so it slides open smoothly.
class PriceBreakdownCard extends StatelessWidget {
  final int originalPaise;
  final int discountPaise;
  final int finalPaise;
  final String? appliedCode;
  final VoidCallback? onRemoveCode;

  const PriceBreakdownCard({
    super.key,
    required this.originalPaise,
    required this.discountPaise,
    required this.finalPaise,
    this.appliedCode,
    this.onRemoveCode,
  });

  String _fmt(int paise) =>
      '₹${(paise / 100).toStringAsFixed(0)}';

  @override
  Widget build(BuildContext context) {
    return AnimatedSize(
      duration: const Duration(milliseconds: 350),
      curve: Curves.easeInOut,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.success.withOpacity(0.05),
          borderRadius: AppTheme.cardRadius,
          border:
              Border.all(color: AppColors.success.withOpacity(0.25)),
        ),
        child: Column(
          children: [
            // Applied code chip + remove
            if (appliedCode != null) ...[
              Row(
                children: [
                  const Icon(Icons.check_circle_rounded,
                      color: AppColors.success, size: 16),
                  const SizedBox(width: 6),
                  Text('"$appliedCode" applied',
                      style: AppTypography.labelSmall.copyWith(
                          color: AppColors.success,
                          fontWeight: FontWeight.w700)),
                  const Spacer(),
                  if (onRemoveCode != null)
                    GestureDetector(
                      onTap: onRemoveCode,
                      child: const Icon(Icons.close_rounded,
                          size: 16, color: AppColors.textSecondary),
                    ),
                ],
              ),
              const SizedBox(height: 12),
              const Divider(height: 1),
              const SizedBox(height: 12),
            ],

            // Price rows
            _PriceRow(
              label: 'Original',
              value: _fmt(originalPaise),
              isOriginal: true,
            ),
            const SizedBox(height: 6),
            _PriceRow(
              label: 'Discount',
              value: '- ${_fmt(discountPaise)}',
              valueColor: AppColors.success,
            ),
            const SizedBox(height: 10),
            const Divider(height: 1),
            const SizedBox(height: 10),
            _PriceRow(
              label: 'Total',
              value: _fmt(finalPaise),
              isBold: true,
              valueColor: AppColors.primaryBrand,
            ),
          ],
        ),
      ),
    );
  }
}

class _PriceRow extends StatelessWidget {
  final String label, value;
  final Color? valueColor;
  final bool isBold;
  final bool isOriginal;

  const _PriceRow({
    required this.label,
    required this.value,
    this.valueColor,
    this.isBold = false,
    this.isOriginal = false,
  });

  @override
  Widget build(BuildContext context) {
    final labelStyle = isBold
        ? AppTypography.labelLarge
        : AppTypography.bodySmall;
    final valueStyle = isBold
        ? AppTypography.labelLarge.copyWith(
            color: valueColor,
            fontWeight: FontWeight.w700,
          )
        : AppTypography.bodySmall.copyWith(
            color: valueColor,
            decoration:
                isOriginal ? TextDecoration.lineThrough : null,
          );

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: labelStyle),
        Text(value, style: valueStyle),
      ],
    );
  }
}

// ─── GPayButton ───────────────────────────────────────────────────────────────
/// Native-style Google Pay button with the official G icon and brand styling.
class GPayButton extends StatefulWidget {
  final String amount;
  final VoidCallback? onPressed;
  final bool isLoading;

  const GPayButton({
    super.key,
    required this.amount,
    this.onPressed,
    this.isLoading = false,
  });

  @override
  State<GPayButton> createState() => _GPayButtonState();
}

class _GPayButtonState extends State<GPayButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _scaleCtrl;
  late Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _scaleCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 100));
    _scale = Tween<double>(begin: 1.0, end: 0.97)
        .animate(CurvedAnimation(parent: _scaleCtrl, curve: Curves.easeIn));
  }

  @override
  void dispose() {
    _scaleCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(
      scale: _scale,
      child: GestureDetector(
        onTapDown: (_) => _scaleCtrl.forward(),
        onTapUp: (_) {
          _scaleCtrl.reverse();
          widget.onPressed?.call();
        },
        onTapCancel: () => _scaleCtrl.reverse(),
        child: Container(
          height: 54,
          decoration: BoxDecoration(
            color: Colors.black,
            borderRadius: AppTheme.buttonRadius,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.25),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Center(
            child: widget.isLoading
                ? const CircularProgressIndicator(
                    color: Colors.white, strokeWidth: 2.5)
                : Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Stylised G icon
                      Container(
                        width: 24,
                        height: 24,
                        decoration: const BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                        ),
                        child: const Center(
                          child: Text('G',
                              style: TextStyle(
                                color: Colors.blue,
                                fontWeight: FontWeight.w700,
                                fontSize: 14,
                              )),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Text(
                        'Pay ${widget.amount} with GPay',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.3,
                        ),
                      ),
                    ],
                  ),
          ),
        ),
      ),
    );
  }
}

// ─── RazorpayButton ───────────────────────────────────────────────────────────
/// Razorpay-branded pay button — used for card / netbanking flows.
class RazorpayButton extends StatelessWidget {
  final String amount;
  final VoidCallback? onPressed;
  final bool isLoading;

  const RazorpayButton({
    super.key,
    required this.amount,
    this.onPressed,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 54,
      child: ElevatedButton(
        onPressed: isLoading ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF528FF0), // Razorpay blue
          shape: const RoundedRectangleBorder(
              borderRadius: AppTheme.buttonRadius),
          elevation: 0,
        ),
        child: isLoading
            ? const CircularProgressIndicator(
                color: Colors.white, strokeWidth: 2.5)
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.credit_card_rounded,
                      color: Colors.white, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    'Pay $amount',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}

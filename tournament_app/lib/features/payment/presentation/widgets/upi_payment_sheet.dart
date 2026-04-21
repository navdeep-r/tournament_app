import 'package:flutter/material.dart';
import 'package:tournament_app/features/payment/data/models/payment_models.dart';
import 'package:tournament_app/core/theme/app_colors.dart';
import 'package:tournament_app/core/theme/app_typography.dart';
import 'package:tournament_app/core/theme/app_theme.dart';

/// Bottom sheet that appears when user selects "Any UPI App" or
/// when no specific UPI app is installed and we want them to choose.
class UpiPaymentSheet extends StatelessWidget {
  final List<PaymentMethod> availableMethods;
  final PaymentMethodType? selectedMethod;
  final ValueChanged<PaymentMethodType> onMethodSelected;
  final String amountFormatted;

  const UpiPaymentSheet({
    super.key,
    required this.availableMethods,
    this.selectedMethod,
    required this.onMethodSelected,
    required this.amountFormatted,
  });

  /// Shows the sheet and returns the selected method, or null if dismissed.
  static Future<PaymentMethodType?> show(
    BuildContext context, {
    required List<PaymentMethod> methods,
    required String amount,
    PaymentMethodType? current,
  }) {
    return showModalBottomSheet<PaymentMethodType>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => UpiPaymentSheet(
        availableMethods: methods,
        selectedMethod: current,
        onMethodSelected: (m) => Navigator.of(context).pop(m),
        amountFormatted: amount,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final upiMethods = availableMethods
        .where((m) =>
            m.type == PaymentMethodType.googlePay ||
            m.type == PaymentMethodType.phonePe ||
            m.type == PaymentMethodType.paytm ||
            m.type == PaymentMethodType.bhimUpi)
        .toList();

    return Container(
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.only(
        left: 24,
        right: 24,
        top: 16,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle
          Container(
            width: 36,
            height: 4,
            decoration: BoxDecoration(
              color: AppColors.divider,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 20),

          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Pay via UPI', style: AppTypography.headlineSmall),
                    Text('Select an app to pay $amountFormatted',
                        style: AppTypography.bodySmall),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close_rounded),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Divider(),
          const SizedBox(height: 8),

          // UPI app grid
          GridView.count(
            crossAxisCount: 3,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            children: upiMethods.map((method) {
              final isSelected = selectedMethod == method.type;
              final isDisabled = !method.isInstalled;
              return GestureDetector(
                onTap: isDisabled ? null : () => onMethodSelected(method.type),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? AppColors.primaryBrand.withOpacity(0.1)
                        : AppColors.background,
                    borderRadius: AppTheme.cardRadius,
                    border: Border.all(
                      color: isSelected
                          ? AppColors.primaryBrand
                          : AppColors.divider,
                      width: isSelected ? 1.5 : 1,
                    ),
                  ),
                  child: Opacity(
                    opacity: isDisabled ? 0.4 : 1.0,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          _iconFor(method.type),
                          color: _colorFor(method.type),
                          size: 32,
                        ),
                        const SizedBox(height: 6),
                        Text(
                          method.displayName,
                          style: AppTypography.labelSmall.copyWith(
                            fontWeight: FontWeight.w600,
                            color: isDisabled
                                ? AppColors.eliminated
                                : AppColors.textPrimary,
                          ),
                          textAlign: TextAlign.center,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        if (isDisabled)
                          Text('Not installed',
                              style: AppTypography.caption
                                  .copyWith(fontSize: 9)),
                      ],
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 20),

          // Note
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.primaryBrand.withOpacity(0.06),
              borderRadius: AppTheme.chipRadius,
            ),
            child: Row(
              children: [
                const Icon(Icons.info_outline_rounded,
                    color: AppColors.primaryBrand, size: 16),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'You will be taken to the UPI app to complete payment. Return to this app after payment.',
                    style: AppTypography.caption,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  IconData _iconFor(PaymentMethodType type) => switch (type) {
        PaymentMethodType.googlePay => Icons.g_mobiledata,
        PaymentMethodType.phonePe => Icons.phone_android,
        PaymentMethodType.paytm => Icons.account_balance_wallet,
        PaymentMethodType.bhimUpi => Icons.qr_code_scanner,
        _ => Icons.payment,
      };

  Color _colorFor(PaymentMethodType type) => switch (type) {
        PaymentMethodType.googlePay => Colors.blue,
        PaymentMethodType.phonePe => const Color(0xFF5F259F),
        PaymentMethodType.paytm => Colors.blue.shade700,
        PaymentMethodType.bhimUpi => const Color(0xFF5F259F),
        _ => AppColors.primaryBrand,
      };
}

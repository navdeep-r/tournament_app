import 'package:flutter/material.dart';
import 'package:dotted_border/dotted_border.dart';
import 'package:tournament_app/features/payment/bloc/payment_bloc.dart';
import 'package:tournament_app/features/payment/data/models/payment_models.dart';
import 'package:tournament_app/core/theme/app_colors.dart';
import 'package:tournament_app/core/theme/app_typography.dart';
import 'package:tournament_app/core/theme/app_theme.dart';
import 'package:tournament_app/shared/widgets/gold_button.dart';

class CheckoutOrderSummarySection extends StatelessWidget {
  final PaymentState state;

  const CheckoutOrderSummarySection({super.key, required this.state});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFFFF7E8), Color(0xFFFFFDF7)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: AppTheme.cardRadius,
        border: Border.all(color: AppColors.primaryBrand.withOpacity(0.28)),
        boxShadow: [AppTheme.cardShadow],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: AppColors.primaryBrand.withOpacity(0.14),
              borderRadius: AppTheme.chipRadius,
            ),
            child: Text(
              'Order Summary',
              style: AppTypography.labelSmall.copyWith(
                color: AppColors.primaryBrand,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            state.currentOrder?.tournamentName ?? 'Tournament',
            style: AppTypography.labelLarge,
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(
                    Icons.phone_outlined,
                    size: 14,
                    color: AppColors.textSecondary,
                  ),
                  const SizedBox(width: 4),
                  Text('+91 ${state.phone}', style: AppTypography.caption),
                ],
              ),
              Text(
                state.formattedFinalAmount,
                style: AppTypography.headlineSmall.copyWith(
                  color: AppColors.primaryBrand,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          if (state.discountAmountPaise > 0) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(
                  Icons.local_offer_outlined,
                  size: 14,
                  color: AppColors.success,
                ),
                const SizedBox(width: 4),
                Text(
                  'Saved Rs ${(state.discountAmountPaise / 100).toStringAsFixed(2)}',
                  style: AppTypography.caption.copyWith(
                    color: AppColors.success,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class CheckoutPricingBreakdownSection extends StatelessWidget {
  final int originalPaise;
  final int discountPaise;
  final int finalPaise;
  final String? code;

  const CheckoutPricingBreakdownSection({
    super.key,
    required this.originalPaise,
    required this.discountPaise,
    required this.finalPaise,
    this.code,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: AppTheme.cardRadius,
        border: Border.all(color: AppColors.divider),
        boxShadow: [AppTheme.cardShadow],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Price Details', style: AppTypography.labelLarge),
          const SizedBox(height: 12),
          _PriceRow('Subtotal', 'Rs ${(originalPaise / 100).toStringAsFixed(2)}'),
          const SizedBox(height: 6),
          _PriceRow(
            code == null || code!.isEmpty ? 'Discount' : 'Discount ($code)',
            '-Rs ${(discountPaise / 100).toStringAsFixed(2)}',
            valueColor: AppColors.success,
          ),
          const Divider(height: 20),
          _PriceRow(
            'Total',
            'Rs ${(finalPaise / 100).toStringAsFixed(2)}',
            bold: true,
          ),
        ],
      ),
    );
  }
}

class CheckoutReferralSection extends StatelessWidget {
  final TextEditingController controller;
  final bool hasApplied;
  final bool isValidating;
  final String? errorText;
  final VoidCallback onApply;
  final VoidCallback onClear;

  const CheckoutReferralSection({
    super.key,
    required this.controller,
    required this.hasApplied,
    required this.isValidating,
    required this.errorText,
    required this.onApply,
    required this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Apply Discount', style: AppTypography.labelLarge),
        const SizedBox(height: 10),
        DottedBorder(
          color: hasApplied
              ? AppColors.success
              : errorText != null
                  ? AppColors.error
                  : AppColors.primaryBrand,
          strokeWidth: 1.5,
          dashPattern: const [8, 4],
          borderType: BorderType.RRect,
          radius: const Radius.circular(8),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: controller,
                    textCapitalization: TextCapitalization.characters,
                    maxLength: 20,
                    decoration: const InputDecoration(
                      border: InputBorder.none,
                      counterText: '',
                      hintText: 'e.g. FRIEND2024',
                    ),
                    style: AppTypography.labelLarge.copyWith(letterSpacing: 3),
                  ),
                ),
                if (isValidating)
                  const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: AppColors.primaryBrand,
                    ),
                  )
                else if (hasApplied)
                  IconButton(
                    onPressed: onClear,
                    icon: const Icon(Icons.close, color: AppColors.textSecondary),
                  )
                else
                  TextButton(
                    onPressed: onApply,
                    child: Text(
                      'Apply',
                      style: AppTypography.labelLarge.copyWith(
                        color: AppColors.primaryBrand,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
        if (errorText != null) ...[
          const SizedBox(height: 8),
          Text(
            errorText!,
            style: AppTypography.caption.copyWith(color: AppColors.error),
          ),
        ],
        if (hasApplied && errorText == null) ...[
          const SizedBox(height: 8),
          Text(
            'Referral code applied successfully.',
            style: AppTypography.caption.copyWith(color: AppColors.success),
          ),
        ],
      ],
    );
  }
}

class CheckoutPaymentMethodSection extends StatelessWidget {
  final List<PaymentMethod> methods;
  final PaymentMethodType? selected;
  final ValueChanged<PaymentMethodType> onSelect;

  const CheckoutPaymentMethodSection({
    super.key,
    required this.methods,
    required this.selected,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: methods
          .map(
            (method) => _PaymentMethodTile(
              method: method,
              isSelected: selected == method.type,
              onTap: method.isInstalled ? () => onSelect(method.type) : null,
            ),
          )
          .toList(),
    );
  }
}

class CheckoutConfirmButton extends StatelessWidget {
  final String amountText;
  final bool isLoading;
  final bool canProceed;
  final VoidCallback onPressed;

  const CheckoutConfirmButton({
    super.key,
    required this.amountText,
    required this.isLoading,
    required this.canProceed,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return GoldButton(
      label: 'Pay $amountText',
      onPressed: canProceed ? onPressed : null,
      isLoading: isLoading,
    );
  }
}

class _PaymentMethodTile extends StatelessWidget {
  final PaymentMethod method;
  final bool isSelected;
  final VoidCallback? onTap;

  const _PaymentMethodTile({
    required this.method,
    required this.isSelected,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.primaryBrand.withOpacity(0.06)
              : AppColors.surface,
          borderRadius: AppTheme.cardRadius,
          border: Border(
            left: BorderSide(
              color: isSelected ? AppColors.primaryBrand : Colors.transparent,
              width: 3,
            ),
            top: const BorderSide(color: AppColors.divider, width: 0.5),
            right: const BorderSide(color: AppColors.divider, width: 0.5),
            bottom: const BorderSide(color: AppColors.divider, width: 0.5),
          ),
        ),
        child: Row(
          children: [
            Radio<bool>(
              value: true,
              groupValue: isSelected,
              activeColor: AppColors.primaryBrand,
              onChanged: onTap != null ? (_) => onTap!() : null,
            ),
            const SizedBox(width: 4),
            _methodIcon(method.type),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(method.displayName, style: AppTypography.labelLarge),
                  Text(method.subtitle, style: AppTypography.caption),
                ],
              ),
            ),
            if (method.isRecommended && method.isInstalled)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: AppColors.success.withOpacity(0.1),
                  borderRadius: AppTheme.chipRadius,
                ),
                child: Text(
                  'RECOMMENDED',
                  style: AppTypography.labelSmall.copyWith(
                    color: AppColors.success,
                    fontSize: 9,
                  ),
                ),
              )
            else if (!method.isInstalled)
              Text(
                'Not installed',
                style: AppTypography.caption.copyWith(
                  color: AppColors.eliminated,
                  fontSize: 10,
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _methodIcon(PaymentMethodType type) {
    final (icon, color) = switch (type) {
      PaymentMethodType.googlePay => (Icons.g_mobiledata, Colors.blue),
      PaymentMethodType.phonePe => (Icons.phone_android, const Color(0xFF5F259F)),
      PaymentMethodType.paytm => (Icons.account_balance_wallet, Colors.blue),
      PaymentMethodType.bhimUpi => (Icons.qr_code_scanner, const Color(0xFF5F259F)),
      PaymentMethodType.razorpayCard => (Icons.credit_card, AppColors.textPrimary),
      PaymentMethodType.netBanking => (Icons.account_balance, AppColors.textPrimary),
      _ => (Icons.payment, AppColors.textPrimary),
    };
    return Icon(icon, color: color, size: 26);
  }
}

class _PriceRow extends StatelessWidget {
  final String label;
  final String value;
  final Color? valueColor;
  final bool bold;

  const _PriceRow(
    this.label,
    this.value, {
    this.valueColor,
    this.bold = false,
  });

  @override
  Widget build(BuildContext context) {
    final style = bold ? AppTypography.labelLarge : AppTypography.bodySmall;
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: style),
        Text(
          value,
          style: style.copyWith(
            color: valueColor,
            fontWeight: bold ? FontWeight.w700 : null,
          ),
        ),
      ],
    );
  }
}

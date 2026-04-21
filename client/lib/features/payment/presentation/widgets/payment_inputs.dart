import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:dotted_border/dotted_border.dart';
import 'package:tournament_app/core/theme/app_colors.dart';
import 'package:tournament_app/core/theme/app_typography.dart';
import 'package:tournament_app/core/theme/app_theme.dart';
import 'package:tournament_app/shared/widgets/animations.dart';

// ─── PhoneNumberInput ─────────────────────────────────────────────────────────
/// +91 prefix chip + 10-digit text field.
/// Live validation: red border + error text if invalid.
/// Green checkmark animates in when 10 valid digits are entered.
class PhoneNumberInput extends StatefulWidget {
  final ValueChanged<String> onChanged;
  final bool isValid;
  final bool enabled;

  const PhoneNumberInput({
    super.key,
    required this.onChanged,
    required this.isValid,
    this.enabled = true,
  });

  @override
  State<PhoneNumberInput> createState() => _PhoneNumberInputState();
}

class _PhoneNumberInputState extends State<PhoneNumberInput> {
  final _ctrl = TextEditingController();
  String _formatted = '';

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  void _onInput(String raw) {
    final digits = raw.replaceAll(RegExp(r'[^\d]'), '');
    // Format as "XXXXX XXXXX"
    final formatted = digits.length > 5
        ? '${digits.substring(0, 5)} ${digits.substring(5)}'
        : digits;

    if (formatted != _formatted) {
      _formatted = formatted;
      _ctrl.value = TextEditingValue(
        text: formatted,
        selection: TextSelection.collapsed(offset: formatted.length),
      );
    }
    widget.onChanged(digits);
  }

  @override
  Widget build(BuildContext context) {
    final hasError =
        _ctrl.text.isNotEmpty && !widget.isValid;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: AppTheme.chipRadius,
            border: Border.all(
              color: widget.isValid
                  ? AppColors.success
                  : hasError
                      ? AppColors.error
                      : AppColors.divider,
              width: widget.isValid || hasError ? 1.5 : 1,
            ),
          ),
          child: Row(
            children: [
              // +91 prefix chip
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 14, vertical: 16),
                decoration: const BoxDecoration(
                  border: Border(
                      right: BorderSide(color: AppColors.divider)),
                ),
                child: Text('+91',
                    style: AppTypography.labelLarge
                        .copyWith(color: AppColors.textSecondary)),
              ),

              // Input field
              Expanded(
                child: TextField(
                  controller: _ctrl,
                  enabled: widget.enabled,
                  keyboardType: const TextInputType.numberWithOptions(
                      signed: false, decimal: false),
                  maxLength: 11, // 10 digits + 1 space
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(
                        RegExp(r'[\d ]')),
                  ],
                  decoration: const InputDecoration(
                    border: InputBorder.none,
                    counterText: '',
                    hintText: 'XXXXX XXXXX',
                    contentPadding:
                        EdgeInsets.symmetric(horizontal: 12),
                  ),
                  onChanged: _onInput,
                ),
              ),

              // Valid checkmark
              AnimatedOpacity(
                opacity: widget.isValid ? 1.0 : 0.0,
                duration: const Duration(milliseconds: 200),
                child: const Padding(
                  padding: EdgeInsets.only(right: 12),
                  child: Icon(Icons.check_circle_rounded,
                      color: AppColors.success, size: 20),
                ),
              ),
            ],
          ),
        ),

        if (hasError) ...[
          const SizedBox(height: 6),
          Text(
            'Enter a valid 10-digit Indian mobile number',
            style: AppTypography.caption
                .copyWith(color: AppColors.error),
          ),
        ],
      ],
    );
  }
}

// ─── ReferralCodeInput ────────────────────────────────────────────────────────
/// Dotted border input for referral code entry.
/// Shows loading, success (green), and error (red) states.
/// Apply button lives inside the field on the right.
class ReferralCodeInput extends StatefulWidget {
  final ValueChanged<String> onSubmit;
  final VoidCallback? onRemove;
  final bool isValidating;
  final bool isValid;
  final String? appliedCode;
  final String? errorMessage;

  const ReferralCodeInput({
    super.key,
    required this.onSubmit,
    this.onRemove,
    this.isValidating = false,
    this.isValid = false,
    this.appliedCode,
    this.errorMessage,
  });

  @override
  State<ReferralCodeInput> createState() => _ReferralCodeInputState();
}

class _ReferralCodeInputState extends State<ReferralCodeInput> {
  final _ctrl = TextEditingController();
  final GlobalKey<ShakeWidgetState> _shakeKey =
      GlobalKey<ShakeWidgetState>();

  @override
  void didUpdateWidget(ReferralCodeInput old) {
    super.didUpdateWidget(old);
    // Shake on new error
    if (widget.errorMessage != null &&
        widget.errorMessage != old.errorMessage) {
      _shakeKey.currentState?.shake();
    }
    // Clear field when code is removed
    if (old.appliedCode != null && widget.appliedCode == null) {
      _ctrl.clear();
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  Color get _borderColor {
    if (widget.isValid) return AppColors.success;
    if (widget.errorMessage != null) return AppColors.error;
    return AppColors.primaryBrand;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ShakeWidget(
          key: _shakeKey,
          child: DottedBorder(
            color: _borderColor,
            strokeWidth: 1.5,
            dashPattern: const [8, 4],
            borderType: BorderType.RRect,
            radius: const Radius.circular(8),
            child: SizedBox(
              height: 52,
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _ctrl,
                      enabled: !widget.isValid,
                      textCapitalization: TextCapitalization.characters,
                      maxLength: 12,
                      decoration: InputDecoration(
                        border: InputBorder.none,
                        counterText: '',
                        hintText: 'e.g. FRIEND2024',
                        contentPadding:
                            const EdgeInsets.symmetric(horizontal: 14),
                        hintStyle: AppTypography.bodyMedium.copyWith(
                            color: AppColors.eliminated),
                      ),
                      style: AppTypography.labelLarge.copyWith(
                          letterSpacing: 3,
                          color: widget.isValid
                              ? AppColors.success
                              : AppColors.textPrimary),
                      onChanged: (v) =>
                          setState(() {}), // Rebuild for button enable
                    ),
                  ),

                  // Trailing: loader / apply / remove / check
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: _buildTrailing(),
                  ),
                ],
              ),
            ),
          ),
        ),

        // Error text
        if (widget.errorMessage != null) ...[
          const SizedBox(height: 6),
          Text(widget.errorMessage!,
              style: AppTypography.caption
                  .copyWith(color: AppColors.error)),
        ],
      ],
    );
  }

  Widget _buildTrailing() {
    if (widget.isValidating) {
      return const SizedBox(
        width: 20,
        height: 20,
        child: CircularProgressIndicator(
            strokeWidth: 2, color: AppColors.primaryBrand),
      );
    }
    if (widget.isValid) {
      return GestureDetector(
        onTap: widget.onRemove,
        child: const Icon(Icons.cancel_rounded,
            color: AppColors.eliminated, size: 20),
      );
    }
    // Apply button — enabled only when input has text
    final hasText = _ctrl.text.trim().isNotEmpty;
    return TextButton(
      onPressed: hasText ? () => widget.onSubmit(_ctrl.text) : null,
      style: TextButton.styleFrom(
        foregroundColor: AppColors.primaryBrand,
        disabledForegroundColor: AppColors.eliminated,
        padding: EdgeInsets.zero,
        minimumSize: Size.zero,
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      ),
      child: Text('Apply', style: AppTypography.labelLarge),
    );
  }
}

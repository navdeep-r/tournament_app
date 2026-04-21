import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:pin_code_fields/pin_code_fields.dart';
import 'package:dotted_border/dotted_border.dart';
import 'package:tournament_app/features/payment/bloc/payment_bloc.dart';
import 'package:tournament_app/features/payment/data/models/payment_models.dart';
import 'package:tournament_app/core/theme/app_colors.dart';
import 'package:tournament_app/core/theme/app_typography.dart';
import 'package:tournament_app/core/theme/app_theme.dart';
import 'package:tournament_app/shared/widgets/cream_scaffold.dart';
import 'package:tournament_app/shared/widgets/gold_button.dart';

class CheckoutScreen extends StatefulWidget {
  final String tournamentId;
  const CheckoutScreen({super.key, required this.tournamentId});

  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  final _pageController = PageController();

  @override
  void initState() {
    super.initState();
    context.read<PaymentBloc>().add(PaymentInitRequested(widget.tournamentId));
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _goToPage(int page) {
    _pageController.animateToPage(page,
        duration: const Duration(milliseconds: 350), curve: Curves.easeInOut);
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<PaymentBloc, PaymentState>(
      listener: (context, state) {
        _goToPage(state.currentStep);
        if (state.status == PaymentStatus.success) {
          context.go('/payment/success');
        } else if (state.status == PaymentStatus.failure) {
          context.go('/payment/failure');
        }
      },
      child: CreamScaffold(
        appBar: AppBar(
          title: Text('Checkout', style: AppTypography.titleLarge),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new_rounded),
            onPressed: () {
              // Use GoRouter's pop which properly handles the navigation stack
              if (context.canPop()) {
                context.pop();
              } else {
                // Fallback: navigate back to tournament detail
                context.go('/home');
              }
            },
          ),
        ),
        body: Column(
          children: [
            const SizedBox(height: 16),
            BlocBuilder<PaymentBloc, PaymentState>(
              builder: (_, s) => _StepIndicator(currentStep: s.currentStep),
            ),
            const SizedBox(height: 24),
            Expanded(
              child: PageView(
                controller: _pageController,
                physics: const NeverScrollableScrollPhysics(),
                children: [
                  _Step1Phone(onNext: () => _goToPage(1)),
                  _Step2Referral(
                    onNext: () =>
                        context.read<PaymentBloc>().add(PaymentCreateOrder()),
                    onSkip: () =>
                        context.read<PaymentBloc>().add(PaymentCreateOrder()),
                  ),
                  _Step3Payment(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Step Indicator ───────────────────────────────────────────────────────────
class _StepIndicator extends StatelessWidget {
  final int currentStep;
  const _StepIndicator({required this.currentStep});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Row(
        children: List.generate(3, (i) {
          final isDone = i < currentStep;
          final isActive = i == currentStep;
          return Expanded(
            child: Row(
              children: [
                AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isDone
                        ? AppColors.success
                        : isActive
                            ? AppColors.primaryBrand
                            : Colors.transparent,
                    border: Border.all(
                      color: isDone
                          ? AppColors.success
                          : isActive
                              ? AppColors.primaryBrand
                              : AppColors.divider,
                      width: 1.5,
                    ),
                  ),
                  child: Center(
                    child: isDone
                        ? const Icon(Icons.check, color: Colors.white, size: 16)
                        : Text('${i + 1}',
                            style: AppTypography.labelMedium.copyWith(
                              color: isActive
                                  ? Colors.white
                                  : AppColors.textSecondary,
                              fontWeight: FontWeight.w700,
                            )),
                  ),
                ),
                if (i < 2)
                  Expanded(
                    child: Container(
                      height: 1.5,
                      color: i < currentStep
                          ? AppColors.success
                          : AppColors.divider,
                    ),
                  ),
              ],
            ),
          );
        }),
      ),
    );
  }
}

// ─── Step 1: Phone + OTP ──────────────────────────────────────────────────────
class _Step1Phone extends StatefulWidget {
  final VoidCallback onNext;
  const _Step1Phone({required this.onNext});

  @override
  State<_Step1Phone> createState() => _Step1PhoneState();
}

class _Step1PhoneState extends State<_Step1Phone>
    with SingleTickerProviderStateMixin {
  final _phoneController = TextEditingController();
  late AnimationController _shakeController;
  late Animation<double> _shakeAnimation;
  bool _otpSent = false;

  @override
  void initState() {
    super.initState();
    _shakeController = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 500));
    _shakeAnimation = Tween<double>(begin: 0, end: 1).animate(
        CurvedAnimation(parent: _shakeController, curve: Curves.elasticIn));
  }

  @override
  void dispose() {
    _phoneController.dispose();
    _shakeController.dispose();
    super.dispose();
  }

  void _shake() => _shakeController.forward(from: 0);

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<PaymentBloc, PaymentState>(
      builder: (context, state) {
        return SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Enter your mobile number',
                  style: AppTypography.headlineMedium),
              const SizedBox(height: 6),
              Text('Your queue number will be linked to this number',
                  style: AppTypography.bodySmall),
              const SizedBox(height: 28),

              // Phone input
              Container(
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: AppTheme.chipRadius,
                  border: Border.all(
                    color: state.isPhoneValid
                        ? AppColors.success
                        : AppColors.divider,
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 16),
                      decoration: const BoxDecoration(
                        border: Border(
                            right: BorderSide(color: AppColors.divider)),
                      ),
                      child: Text('+91',
                          style: AppTypography.labelLarge
                              .copyWith(color: AppColors.textSecondary)),
                    ),
                    Expanded(
                      child: TextField(
                        controller: _phoneController,
                        keyboardType: TextInputType.number,
                        maxLength: 10,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly
                        ],
                        decoration: const InputDecoration(
                          border: InputBorder.none,
                          counterText: '',
                          hintText: 'XXXXX XXXXX',
                          contentPadding:
                              EdgeInsets.symmetric(horizontal: 12),
                        ),
                        onChanged: (v) => context
                            .read<PaymentBloc>()
                            .add(PaymentPhoneChanged(v)),
                      ),
                    ),
                    if (state.isPhoneValid)
                      const Padding(
                        padding: EdgeInsets.only(right: 12),
                        child: Icon(Icons.check_circle_rounded,
                            color: AppColors.success, size: 20),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              if (!state.isOtpSent)
                GoldButton(
                  label: 'Send OTP',
                  onPressed: state.isPhoneValid
                      ? () {
                          context.read<PaymentBloc>().add(
                                PaymentSendOtpRequested(state.phone),
                              );
                        }
                      : null,
                  isLoading: state.status == PaymentStatus.phoneVerification,
                )
              else ...[
                Text('Enter 6-digit OTP',
                    style: AppTypography.labelLarge),
                const SizedBox(height: 12),
                AnimatedBuilder(
                  animation: _shakeAnimation,
                  builder: (_, child) {
                    final shake =
                        (_shakeAnimation.value * 10 * 3.14159).abs();
                    return Transform.translate(
                      offset: Offset(8 * shake, 0),
                      child: child,
                    );
                  },
                  child: PinCodeTextField(
                    appContext: context,
                    length: 6,
                    keyboardType: TextInputType.number,
                    animationType: AnimationType.fade,
                    pinTheme: PinTheme(
                      shape: PinCodeFieldShape.box,
                      borderRadius: AppTheme.chipRadius,
                      fieldHeight: 52,
                      fieldWidth: 44,
                      activeColor: AppColors.primaryBrand,
                      inactiveColor: AppColors.divider,
                      selectedColor: AppColors.primaryBrand,
                    ),
                    onCompleted: (otp) {
                      // Auto-verify
                      context.read<PaymentBloc>().add(PaymentOtpVerified());
                      widget.onNext();
                    },
                    onChanged: (v) =>
                        context.read<PaymentBloc>().add(PaymentOtpChanged(v)),
                  ),
                ),
                TextButton(
                  onPressed: () => context.read<PaymentBloc>().add(
                        PaymentSendOtpRequested(state.phone),
                      ),
                  child: Text('Resend OTP',
                      style: AppTypography.labelMedium
                          .copyWith(color: AppColors.primaryBrand)),
                ),
              ],
            ],
          ),
        );
      },
    );
  }
}

// ─── Step 2: Referral Code ────────────────────────────────────────────────────
class _Step2Referral extends StatefulWidget {
  final VoidCallback onNext;
  final VoidCallback onSkip;
  const _Step2Referral({required this.onNext, required this.onSkip});

  @override
  State<_Step2Referral> createState() => _Step2ReferralState();
}

class _Step2ReferralState extends State<_Step2Referral> {
  final _codeController = TextEditingController();

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<PaymentBloc, PaymentState>(
      builder: (context, state) {
        final hasApplied = state.appliedReferral != null;

        return SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Have a referral code?',
                  style: AppTypography.headlineMedium),
              const SizedBox(height: 6),
              Text('Apply to get a discount on entry fee',
                  style: AppTypography.bodySmall),
              const SizedBox(height: 28),

              // Dotted border input
              DottedBorder(
                color: hasApplied
                    ? AppColors.success
                    : state.referralError != null
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
                          controller: _codeController,
                          textCapitalization: TextCapitalization.characters,
                          maxLength: 12,
                          decoration: const InputDecoration(
                            border: InputBorder.none,
                            counterText: '',
                            hintText: 'e.g. FRIEND2024',
                          ),
                          style: AppTypography.labelLarge.copyWith(
                              letterSpacing: 4),
                          onChanged: (v) => context
                              .read<PaymentBloc>()
                              .add(PaymentReferralCodeChanged(v)),
                        ),
                      ),
                      if (state.isValidatingReferral)
                        const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: AppColors.primaryBrand),
                        )
                      else if (hasApplied)
                        GestureDetector(
                          onTap: () {
                            _codeController.clear();
                            context.read<PaymentBloc>().add(PaymentReferralRemoved());
                          },
                          child: const Icon(Icons.close,
                              color: AppColors.textSecondary, size: 20),
                        )
                      else
                        TextButton(
                          onPressed: () => context.read<PaymentBloc>().add(
                              PaymentReferralSubmitted(_codeController.text)),
                          child: Text('Apply',
                              style: AppTypography.labelLarge
                                  .copyWith(color: AppColors.primaryBrand)),
                        ),
                    ],
                  ),
                ),
              ),

              if (state.referralError != null) ...[
                const SizedBox(height: 8),
                Text(state.referralError!,
                    style: AppTypography.caption
                        .copyWith(color: AppColors.error)),
              ],

              // Price breakdown animated
              if (hasApplied) ...[
                const SizedBox(height: 20),
                _PriceBreakdownCard(
                  original: state.originalAmountPaise,
                  discount: state.discountAmountPaise,
                  final_: state.finalAmountPaise,
                  code: state.referralCode,
                ),
              ],

              const SizedBox(height: 28),
              GoldButton(
                label: hasApplied ? 'Apply & Continue' : 'Continue',
                onPressed: widget.onNext,
                isLoading: state.status == PaymentStatus.creatingOrder,
              ),
              const SizedBox(height: 12),
              Center(
                child: TextButton(
                  onPressed: widget.onSkip,
                  child: Text('Continue without code',
                      style: AppTypography.bodySmall
                          .copyWith(color: AppColors.textSecondary)),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _PriceBreakdownCard extends StatelessWidget {
  final int original, discount, final_;
  final String code;
  const _PriceBreakdownCard(
      {required this.original,
      required this.discount,
      required this.final_,
      required this.code});

  @override
  Widget build(BuildContext context) {
    return AnimatedSize(
      duration: const Duration(milliseconds: 300),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.success.withOpacity(0.06),
          borderRadius: AppTheme.cardRadius,
          border: Border.all(color: AppColors.success.withOpacity(0.3)),
        ),
        child: Column(
          children: [
            _Row('Original', '₹${(original / 100).toStringAsFixed(0)}'),
            const SizedBox(height: 6),
            _Row('Discount ($code)', '-₹${(discount / 100).toStringAsFixed(0)}',
                valueColor: AppColors.success),
            const Divider(height: 20),
            _Row('Total', '₹${(final_ / 100).toStringAsFixed(0)}',
                bold: true),
          ],
        ),
      ),
    );
  }
}

class _Row extends StatelessWidget {
  final String label, value;
  final Color? valueColor;
  final bool bold;
  const _Row(this.label, this.value, {this.valueColor, this.bold = false});

  @override
  Widget build(BuildContext context) {
    final style = bold ? AppTypography.labelLarge : AppTypography.bodySmall;
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: style),
        Text(value,
            style: style.copyWith(
                color: valueColor,
                fontWeight: bold ? FontWeight.w700 : null)),
      ],
    );
  }
}

// ─── Step 3: Payment Methods ──────────────────────────────────────────────────
class _Step3Payment extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return BlocBuilder<PaymentBloc, PaymentState>(
      builder: (context, state) {
        return SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Choose payment method',
                  style: AppTypography.headlineMedium),
              const SizedBox(height: 20),

              // Order summary
              _OrderSummaryCard(state: state),
              const SizedBox(height: 20),

              // Payment methods
              ...state.availableMethods.map((method) =>
                  _PaymentMethodTile(
                    method: method,
                    isSelected: state.selectedMethod == method.type,
                    onTap: method.isInstalled
                        ? () => context
                            .read<PaymentBloc>()
                            .add(PaymentMethodSelected(method.type))
                        : null,
                  )),

              const SizedBox(height: 24),
              GoldButton(
                label: 'Pay ${state.formattedFinalAmount}',
                onPressed: state.selectedMethod != null &&
                        state.status != PaymentStatus.processing
                    ? () => context
                        .read<PaymentBloc>()
                        .add(PaymentInitiateRequested())
                    : null,
                isLoading: state.status == PaymentStatus.processing,
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.lock_outlined,
                      size: 14, color: AppColors.textSecondary),
                  const SizedBox(width: 4),
                  Text('256-bit SSL  ·  Powered by Razorpay',
                      style: AppTypography.caption),
                ],
              ),
              const SizedBox(height: 24),
            ],
          ),
        );
      },
    );
  }
}

class _OrderSummaryCard extends StatelessWidget {
  final PaymentState state;
  const _OrderSummaryCard({required this.state});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: AppTheme.cardDecoration,
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                  child: Text(
                      state.currentOrder?.tournamentName ?? 'Tournament',
                      style: AppTypography.labelLarge)),
              Text(state.formattedFinalAmount,
                  style: AppTypography.headlineSmall
                      .copyWith(color: AppColors.primaryBrand)),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              const Icon(Icons.phone_outlined,
                  size: 14, color: AppColors.textSecondary),
              const SizedBox(width: 4),
              Text('+91 ${state.phone}',
                  style: AppTypography.caption),
            ],
          ),
          if (state.discountAmountPaise > 0) ...[
            const SizedBox(height: 4),
            Row(
              children: [
                const Icon(Icons.local_offer_outlined,
                    size: 14, color: AppColors.success),
                const SizedBox(width: 4),
                Text(
                    'Saved ₹${(state.discountAmountPaise / 100).toStringAsFixed(0)}',
                    style: AppTypography.caption
                        .copyWith(color: AppColors.success)),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _PaymentMethodTile extends StatelessWidget {
  final PaymentMethod method;
  final bool isSelected;
  final VoidCallback? onTap;

  const _PaymentMethodTile(
      {required this.method, required this.isSelected, this.onTap});

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
            top: BorderSide(color: AppColors.divider, width: 0.5),
            right: BorderSide(color: AppColors.divider, width: 0.5),
            bottom: BorderSide(color: AppColors.divider, width: 0.5),
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
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: AppColors.success.withOpacity(0.1),
                  borderRadius: AppTheme.chipRadius,
                ),
                child: Text('RECOMMENDED',
                    style: AppTypography.labelSmall
                        .copyWith(color: AppColors.success, fontSize: 9)),
              )
            else if (!method.isInstalled)
              Text('Not installed',
                  style: AppTypography.caption.copyWith(
                      color: AppColors.eliminated, fontSize: 10)),
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

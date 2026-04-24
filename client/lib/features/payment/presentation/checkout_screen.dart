import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:pin_code_fields/pin_code_fields.dart';

import 'package:tournament_app/features/payment/bloc/payment_bloc.dart';
import 'package:tournament_app/features/payment/data/models/payment_models.dart';
import 'package:tournament_app/features/payment/presentation/widgets/checkout_sections.dart';
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
    _pageController.animateToPage(
      page,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<PaymentBloc, PaymentState>(
      listener: (context, state) {
        _goToPage(state.currentStep);

        if (state.status == PaymentStatus.success) {
          context.goNamed('payment-success');
          return;
        }

        if (state.status == PaymentStatus.failure) {
          context.goNamed('payment-failure');
          return;
        }

        if (state.errorMessage != null && state.errorMessage!.isNotEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(state.errorMessage!)),
          );
        }
      },
      child: CreamScaffold(
        appBar: AppBar(
          title: Text('Checkout', style: AppTypography.titleLarge),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new_rounded),
            onPressed: () {
              if (context.canPop()) {
                context.pop();
              } else {
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
            const SizedBox(height: 20),
            Expanded(
              child: PageView(
                controller: _pageController,
                physics: const NeverScrollableScrollPhysics(),
                children: [
                  _StepPhoneOtp(onNext: () => _goToPage(1)),
                  _StepReferral(onNext: () => context.read<PaymentBloc>().add(PaymentCreateOrder())),
                  const _StepPayment(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

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
                  duration: const Duration(milliseconds: 250),
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
                        : Text(
                            '${i + 1}',
                            style: AppTypography.labelMedium.copyWith(
                              color: isActive ? Colors.white : AppColors.textSecondary,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                  ),
                ),
                if (i < 2)
                  Expanded(
                    child: Container(
                      height: 1.5,
                      color: i < currentStep ? AppColors.success : AppColors.divider,
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

class _StepPhoneOtp extends StatelessWidget {
  final VoidCallback onNext;

  const _StepPhoneOtp({required this.onNext});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<PaymentBloc, PaymentState>(
      builder: (context, state) {
        return SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Verify mobile number', style: AppTypography.headlineMedium),
              const SizedBox(height: 6),
              Text('Queue number and updates will use this number.', style: AppTypography.bodySmall),
              const SizedBox(height: 24),

              Container(
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: AppTheme.chipRadius,
                  border: Border.all(
                    color: state.isPhoneValid ? AppColors.success : AppColors.divider,
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
                      decoration: const BoxDecoration(
                        border: Border(right: BorderSide(color: AppColors.divider)),
                      ),
                      child: Text(
                        '+91',
                        style: AppTypography.labelLarge.copyWith(color: AppColors.textSecondary),
                      ),
                    ),
                    Expanded(
                      child: TextField(
                        keyboardType: TextInputType.number,
                        maxLength: 10,
                        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                        decoration: const InputDecoration(
                          border: InputBorder.none,
                          counterText: '',
                          hintText: 'XXXXX XXXXX',
                          contentPadding: EdgeInsets.symmetric(horizontal: 12),
                        ),
                        onChanged: (v) => context.read<PaymentBloc>().add(PaymentPhoneChanged(v)),
                      ),
                    ),
                    if (state.isPhoneValid)
                      const Padding(
                        padding: EdgeInsets.only(right: 12),
                        child: Icon(Icons.check_circle_rounded, color: AppColors.success, size: 20),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              if (!state.isOtpSent)
                GoldButton(
                  label: 'Send OTP',
                  onPressed: state.isPhoneValid
                      ? () => context.read<PaymentBloc>().add(PaymentSendOtpRequested(state.phone))
                      : null,
                  isLoading: state.status == PaymentStatus.phoneVerification,
                )
              else ...[
                Text('Enter 6-digit OTP', style: AppTypography.labelLarge),
                const SizedBox(height: 12),
                PinCodeTextField(
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
                  onChanged: (v) => context.read<PaymentBloc>().add(PaymentOtpChanged(v)),
                  onCompleted: (_) {
                    context.read<PaymentBloc>().add(PaymentOtpVerified());
                    onNext();
                  },
                ),
                TextButton(
                  onPressed: () => context.read<PaymentBloc>().add(PaymentSendOtpRequested(state.phone)),
                  child: Text(
                    'Resend OTP',
                    style: AppTypography.labelMedium.copyWith(color: AppColors.primaryBrand),
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }
}

class _StepReferral extends StatefulWidget {
  final VoidCallback onNext;

  const _StepReferral({required this.onNext});

  @override
  State<_StepReferral> createState() => _StepReferralState();
}

class _StepReferralState extends State<_StepReferral> {
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
              Text('Referral / Discount', style: AppTypography.headlineMedium),
              const SizedBox(height: 6),
              Text('Apply code to update your final payable amount.', style: AppTypography.bodySmall),
              const SizedBox(height: 24),

              CheckoutReferralSection(
                controller: _codeController,
                hasApplied: hasApplied,
                isValidating: state.isValidatingReferral,
                errorText: state.referralError,
                onApply: () => context.read<PaymentBloc>().add(PaymentReferralSubmitted(_codeController.text)),
                onClear: () {
                  _codeController.clear();
                  context.read<PaymentBloc>().add(PaymentReferralRemoved());
                },
              ),

              if (hasApplied) ...[
                const SizedBox(height: 16),
                CheckoutPricingBreakdownSection(
                  originalPaise: state.originalAmountPaise,
                  discountPaise: state.discountAmountPaise,
                  finalPaise: state.finalAmountPaise,
                  code: state.referralCode,
                ),
              ],

              const SizedBox(height: 24),
              GoldButton(
                label: hasApplied ? 'Apply & Continue' : 'Continue',
                onPressed: widget.onNext,
                isLoading: state.status == PaymentStatus.creatingOrder,
              ),
              const SizedBox(height: 10),
              Center(
                child: TextButton(
                  onPressed: widget.onNext,
                  child: Text(
                    'Continue without code',
                    style: AppTypography.bodySmall.copyWith(color: AppColors.textSecondary),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _StepPayment extends StatelessWidget {
  const _StepPayment();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<PaymentBloc, PaymentState>(
      builder: (context, state) {
        return SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Review & Pay', style: AppTypography.headlineMedium),
              const SizedBox(height: 16),

              CheckoutOrderSummarySection(state: state),
              const SizedBox(height: 16),

              CheckoutPricingBreakdownSection(
                originalPaise: state.originalAmountPaise,
                discountPaise: state.discountAmountPaise,
                finalPaise: state.finalAmountPaise,
                code: state.referralCode,
              ),
              const SizedBox(height: 16),

              CheckoutPaymentMethodSection(
                methods: state.availableMethods,
                selected: state.selectedMethod,
                onSelect: (method) => context.read<PaymentBloc>().add(PaymentMethodSelected(method)),
              ),

              const SizedBox(height: 20),
              CheckoutConfirmButton(
                amountText: state.formattedFinalAmount,
                isLoading: state.status == PaymentStatus.processing,
                canProceed: state.selectedMethod != null && state.status != PaymentStatus.processing,
                onPressed: () => context.read<PaymentBloc>().add(PaymentInitiateRequested()),
              ),
              const SizedBox(height: 10),

              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.lock_outline, size: 14, color: AppColors.textSecondary),
                  const SizedBox(width: 4),
                  Text('Secure checkout powered by Razorpay', style: AppTypography.caption),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}

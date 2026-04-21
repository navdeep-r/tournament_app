import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:tournament_app/features/payment/bloc/payment_bloc.dart';
import 'package:tournament_app/features/payment/data/models/payment_models.dart';
import 'package:tournament_app/core/theme/app_colors.dart';
import 'package:tournament_app/core/theme/app_typography.dart';
import 'package:tournament_app/core/theme/app_theme.dart';
import 'package:tournament_app/shared/widgets/cream_scaffold.dart';
import 'package:tournament_app/shared/widgets/gold_button.dart';

// ─── Payment Success Screen ───────────────────────────────────────────────────
class PaymentSuccessScreen extends StatefulWidget {
  const PaymentSuccessScreen({super.key});

  @override
  State<PaymentSuccessScreen> createState() => _PaymentSuccessScreenState();
}

class _PaymentSuccessScreenState extends State<PaymentSuccessScreen>
    with TickerProviderStateMixin {
  late AnimationController _countController;
  late Animation<double> _countAnimation;
  int _displayNumber = 0;
  int _targetNumber = 0;

  @override
  void initState() {
    super.initState();
    _countController = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1500));
    _countAnimation = CurvedAnimation(
        parent: _countController, curve: Curves.easeOut);
  }

  void _startCount(int target) {
    _targetNumber = target;
    _countController.forward(from: 0);
    _countController.addListener(() {
      setState(() {
        _displayNumber =
            (_countAnimation.value * _targetNumber).round();
      });
    });
  }

  @override
  void dispose() {
    _countController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<PaymentBloc, PaymentState>(
      builder: (context, state) {
        final result = state.result;
        if (result is PaymentSuccess && _displayNumber == 0) {
          WidgetsBinding.instance
              .addPostFrameCallback((_) => _startCount(result.queueNumber));
        }

        final queueNum = result is PaymentSuccess ? result.queueNumber : 0;
        final tournamentId = result is PaymentSuccess ? result.tournamentId : '';

        return CreamScaffold(
          body: SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                children: [
                  const Spacer(),
                  // Checkmark animation
                  Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      color: AppColors.success.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.check_circle_rounded,
                        color: AppColors.success, size: 64),
                  ),
                  const SizedBox(height: 24),
                  Text("You're In! 🎉",
                      style: AppTypography.displayLarge),
                  const SizedBox(height: 32),

                  // Queue number card
                  Container(
                    padding: const EdgeInsets.all(28),
                    decoration: AppTheme.goldBorderDecoration,
                    child: Column(
                      children: [
                        Text('Your Queue Number',
                            style: AppTypography.labelMedium),
                        const SizedBox(height: 8),
                        Text('#$_displayNumber',
                            style: AppTypography.queueNumber),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Payment details
                  if (result is PaymentSuccess) ...[
                    _DetailRow('Payment ID', result.razorpayPaymentId.isNotEmpty
                        ? result.razorpayPaymentId
                        : 'Verified'),
                    _DetailRow('Amount paid',
                        '₹${(result.amountPaisePaid / 100).toStringAsFixed(0)}'),
                    _DetailRow('Phone', result.userPhone),
                  ],

                  const Spacer(),

                  GoldButton(
                    label: 'View Live Board',
                    onPressed: () =>
                        context.go('/liveboard/$tournamentId'),
                  ),
                  const SizedBox(height: 12),
                  GoldButton(
                    label: 'Back to Home',
                    onPressed: () => context.go('/home'),
                    outlined: true,
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _DetailRow extends StatelessWidget {
  final String label, value;
  const _DetailRow(this.label, this.value);

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('$label: ', style: AppTypography.caption),
            Text(value,
                style: AppTypography.caption
                    .copyWith(color: AppColors.textPrimary)),
          ],
        ),
      );
}

// ─── Payment Failure Screen ───────────────────────────────────────────────────
class PaymentFailureScreen extends StatelessWidget {
  const PaymentFailureScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<PaymentBloc, PaymentState>(
      builder: (context, state) {
        final failure =
            state.result is PaymentFailure ? state.result as PaymentFailure : null;

        return CreamScaffold(
          body: SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                children: [
                  const Spacer(),
                  Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      color: AppColors.error.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.cancel_rounded,
                        color: AppColors.error, size: 64),
                  ),
                  const SizedBox(height: 24),
                  Text('Payment Failed',
                      style: AppTypography.displayMedium
                          .copyWith(color: AppColors.error)),
                  const SizedBox(height: 24),

                  // Error card
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: AppTheme.cardDecoration,
                    child: Column(
                      children: [
                        const Icon(Icons.error_outline,
                            color: AppColors.error, size: 32),
                        const SizedBox(height: 12),
                        Text(
                          'Your payment could not be processed',
                          style: AppTypography.labelLarge,
                          textAlign: TextAlign.center,
                        ),
                        if (failure != null) ...[
                          const SizedBox(height: 8),
                          Text(failure.errorDescription,
                              style: AppTypography.bodySmall,
                              textAlign: TextAlign.center),
                          const SizedBox(height: 4),
                          Text('Code: ${failure.errorCode}',
                              style: AppTypography.caption),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Refund note
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.amber.withOpacity(0.1),
                      borderRadius: AppTheme.chipRadius,
                      border: Border.all(color: Colors.amber.withOpacity(0.3)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.warning_amber_rounded,
                            color: Colors.amber, size: 20),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'If money was deducted, it will be refunded in 3–5 working days.',
                            style: AppTypography.caption,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const Spacer(),

                  GoldButton(
                    label: 'Try Again',
                    onPressed: () {
                      context.read<PaymentBloc>().add(PaymentRetryRequested());
                      context.pop();
                    },
                  ),
                  const SizedBox(height: 12),
                  GoldButton(
                    label: 'Choose Different Method',
                    onPressed: () {
                      context.read<PaymentBloc>().add(PaymentRetryRequested());
                      context.pop();
                    },
                    outlined: true,
                  ),
                  const SizedBox(height: 12),
                  TextButton(
                    onPressed: () {},
                    child: Text('Contact Support',
                        style: AppTypography.labelMedium
                            .copyWith(color: AppColors.textSecondary)),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

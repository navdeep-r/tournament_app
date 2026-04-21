import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../bloc/auth_bloc.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/widgets/gold_button.dart';

class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocListener<AuthBloc, AuthState>(
      listener: (context, state) {
        if (state is AuthAuthenticated) {
          if (state.user.isAdmin) {
            context.go('/admin');
          } else {
            context.go('/home');
          }
        } else if (state is AuthError) {
          showErrorSnackbar(context, state.message);
        }
      },
      child: Scaffold(
        body: Container(
          decoration: const BoxDecoration(gradient: AppColors.creamGradient),
          child: SafeArea(
            child: Column(
              children: [
                // ── Trophy hero ──────────────────────────────────────────
                Expanded(
                  flex: 4,
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          width: 120,
                          height: 120,
                          decoration: BoxDecoration(
                            color: AppColors.surface,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.primaryBrand.withOpacity(0.3),
                                blurRadius: 24,
                                spreadRadius: 4,
                              )
                            ],
                          ),
                          child: const Icon(
                            Icons.emoji_events_rounded,
                            color: AppColors.primaryBrand,
                            size: 64,
                          ),
                        ),
                        const SizedBox(height: 24),
                        Text('Tournament Hub',
                            style: AppTypography.displayLarge),
                        const SizedBox(height: 8),
                        Text(
                          'Your Tournament. Live. Ranked.',
                          style: AppTypography.bodyMedium.copyWith(
                              color: AppColors.textSecondary),
                        ),
                      ],
                    ),
                  ),
                ),

                // ── Sign-in card ─────────────────────────────────────────
                Expanded(
                  flex: 5,
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(32),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(28)),
                      boxShadow: [AppTheme.cardShadow],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Welcome Back',
                            style: AppTypography.headlineLarge),
                        const SizedBox(height: 6),
                        Text('Sign in to join the tournament',
                            style: AppTypography.bodySmall),
                        const SizedBox(height: 32),
                        const Divider(),
                        const SizedBox(height: 32),
                        // Google Sign-In Button
                        BlocBuilder<AuthBloc, AuthState>(
                          builder: (context, state) {
                            final isLoading = state is AuthLoading;
                            return _GoogleSignInButton(
                              isLoading: isLoading,
                              onTap: isLoading
                                  ? null
                                  : () => context
                                      .read<AuthBloc>()
                                      .add(AuthGoogleSignInRequested()),
                            );
                          },
                        ),
                        const Spacer(),
                        Center(
                          child: Text(
                            'By continuing, you agree to our Terms & Privacy Policy',
                            style: AppTypography.caption,
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ],
                    ),
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

class _GoogleSignInButton extends StatelessWidget {
  final bool isLoading;
  final VoidCallback? onTap;

  const _GoogleSignInButton({required this.isLoading, this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 56,
        decoration: BoxDecoration(
          color: AppColors.activeElement,
          borderRadius: AppTheme.buttonRadius,
          border: Border.all(color: AppColors.divider),
          boxShadow: [AppTheme.cardShadow],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (isLoading)
              const SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  color: AppColors.primaryBrand,
                ),
              )
            else ...[
              // Google G logo
              Container(
                width: 24,
                height: 24,
                decoration: const BoxDecoration(shape: BoxShape.circle),
                child: const Icon(Icons.g_mobiledata,
                    color: Colors.red, size: 28),
              ),
              const SizedBox(width: 12),
              Text('Continue with Google',
                  style: AppTypography.labelLarge
                      .copyWith(color: AppColors.textPrimary)),
            ],
          ],
        ),
      ),
    );
  }
}

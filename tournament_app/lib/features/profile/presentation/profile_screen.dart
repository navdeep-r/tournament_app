import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:tournament_app/features/auth/bloc/auth_bloc.dart';
import 'package:tournament_app/core/theme/app_colors.dart';
import 'package:tournament_app/core/theme/app_typography.dart';
import 'package:tournament_app/core/theme/app_theme.dart';
import 'package:tournament_app/shared/widgets/cream_scaffold.dart';
import 'package:tournament_app/shared/widgets/empty_state.dart';
import 'package:tournament_app/shared/widgets/gold_button.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocListener<AuthBloc, AuthState>(
      listener: (context, state) {
        if (state is AuthUnauthenticated) context.go('/login');
      },
      child: CreamScaffold(
        appBar: AppBar(
          title: Text('My Profile', style: AppTypography.titleLarge),
        ),
        body: BlocBuilder<AuthBloc, AuthState>(
          builder: (context, state) {
            final user = state is AuthAuthenticated ? state.user : null;
            return ListView(
              padding: const EdgeInsets.all(16),
              children: [
                const SizedBox(height: 12),
                // Avatar + name
                Center(
                  child: Column(
                    children: [
                      AvatarWithStatus(
                        photoUrl: user?.photoUrl,
                        name: user?.name ?? 'Player',
                        radius: 44,
                      ),
                      const SizedBox(height: 14),
                      Text(user?.name ?? 'Player',
                          style: AppTypography.headlineMedium),
                      Text(user?.email ?? '',
                          style: AppTypography.bodySmall),
                    ],
                  ),
                ),
                const SizedBox(height: 28),

                // Stats row
                Row(
                  children: [
                    _StatItem(label: 'Tournaments\nPlayed', value: '12'),
                    _Divider(),
                    _StatItem(label: 'Wins', value: '3'),
                    _Divider(),
                    _StatItem(label: 'Win Rate', value: '25%'),
                  ],
                ),
                const SizedBox(height: 24),

                // Settings
                _SectionHeader('Account'),
                _ProfileTile(
                  icon: Icons.notifications_outlined,
                  label: 'Notifications',
                  onTap: () {},
                ),
                _ProfileTile(
                  icon: Icons.payment_outlined,
                  label: 'Payment History',
                  onTap: () {},
                ),
                _ProfileTile(
                  icon: Icons.help_outline_rounded,
                  label: 'Help & Support',
                  onTap: () {},
                ),
                _ProfileTile(
                  icon: Icons.privacy_tip_outlined,
                  label: 'Privacy Policy',
                  onTap: () {},
                ),
                _SectionHeader('Danger Zone'),
                const SizedBox(height: 12),
                GoldButton(
                  label: 'Sign Out',
                  outlined: true,
                  onPressed: () => _confirmSignOut(context),
                ),
                const SizedBox(height: 32),
              ],
            );
          },
        ),
      ),
    );
  }

  void _confirmSignOut(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: AppTheme.cardRadius),
        title: Text('Sign out?', style: AppTypography.headlineSmall),
        content: Text('You will need to sign in again to join tournaments.',
            style: AppTypography.bodySmall),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel')),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              context.read<AuthBloc>().add(AuthSignOutRequested());
            },
            child: Text('Sign Out',
                style: AppTypography.labelLarge
                    .copyWith(color: AppColors.error)),
          ),
        ],
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  final String label, value;
  const _StatItem({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          Text(value,
              style: AppTypography.headlineLarge
                  .copyWith(color: AppColors.primaryBrand)),
          const SizedBox(height: 4),
          Text(label,
              style: AppTypography.caption, textAlign: TextAlign.center),
        ],
      ),
    );
  }
}

class _Divider extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Container(
      height: 40, width: 1, color: AppColors.divider);
}

class _SectionHeader extends StatelessWidget {
  final String text;
  const _SectionHeader(this.text);

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(top: 8, bottom: 4),
        child: Text(text,
            style: AppTypography.labelMedium
                .copyWith(color: AppColors.textSecondary)),
      );
}

class _ProfileTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _ProfileTile(
      {required this.icon, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: AppTheme.cardRadius,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 14),
        child: Row(
          children: [
            Icon(icon, color: AppColors.primaryBrand, size: 22),
            const SizedBox(width: 16),
            Expanded(
                child:
                    Text(label, style: AppTypography.bodyMedium)),
            const Icon(Icons.chevron_right_rounded,
                color: AppColors.textSecondary, size: 20),
          ],
        ),
      ),
    );
  }
}

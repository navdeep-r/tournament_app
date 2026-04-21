import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../core/theme/app_theme.dart';

class EmptyState extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final Widget? action;

  const EmptyState({
    super.key,
    required this.title,
    required this.subtitle,
    required this.icon,
    this.action,
  });

  factory EmptyState.noParticipants() => const EmptyState(
        title: 'No Participants',
        subtitle: 'There are no active participants in this tournament yet.',
        icon: Icons.people_outline_rounded,
      );

  factory EmptyState.noTournaments() => const EmptyState(
        title: 'No Tournaments',
        subtitle: 'You haven\'t created any tournaments yet.',
        icon: Icons.emoji_events_outlined,
      );

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: AppColors.primaryBrand.withOpacity(0.06),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: AppColors.primaryBrand, size: 48),
            ),
            const SizedBox(height: 24),
            Text(title, style: AppTypography.headlineSmall),
            const SizedBox(height: 8),
            Text(
              subtitle,
              style: AppTypography.bodySmall,
              textAlign: TextAlign.center,
            ),
            if (action != null) ...[
              const SizedBox(height: 32),
              action!,
            ],
          ],
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';
import 'package:tournament_app/core/theme/app_colors.dart';
import 'package:tournament_app/core/theme/app_typography.dart';
import 'package:tournament_app/core/theme/app_theme.dart';
import 'package:tournament_app/shared/widgets/gold_button.dart';

// ─── EmptyState ───────────────────────────────────────────────────────────────
class EmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final String? actionLabel;
  final VoidCallback? onAction;

  const EmptyState({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    this.actionLabel,
    this.onAction,
  });

  // Named constructors for common cases
  factory EmptyState.noTournaments({VoidCallback? onRefresh}) => EmptyState(
        icon: Icons.emoji_events_outlined,
        title: 'No tournaments yet',
        subtitle: 'Check back soon — new tournaments are added daily.',
        actionLabel: onRefresh != null ? 'Refresh' : null,
        onAction: onRefresh,
      );

  factory EmptyState.noParticipants() => const EmptyState(
        icon: Icons.people_outline,
        title: 'No participants',
        subtitle: 'Registrations will appear here once the tournament opens.',
      );

  factory EmptyState.noHistory() => const EmptyState(
        icon: Icons.history_rounded,
        title: 'No history yet',
        subtitle: 'Your past tournaments and results will show up here.',
      );

  factory EmptyState.networkError({VoidCallback? onRetry}) => EmptyState(
        icon: Icons.wifi_off_rounded,
        title: 'No connection',
        subtitle: 'Check your internet and try again.',
        actionLabel: 'Retry',
        onAction: onRetry,
      );

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: AppColors.primaryBrand.withOpacity(0.08),
                shape: BoxShape.circle,
              ),
              child: Icon(icon,
                  color: AppColors.primaryBrand.withOpacity(0.5), size: 40),
            ),
            const SizedBox(height: 20),
            Text(title,
                style: AppTypography.headlineSmall,
                textAlign: TextAlign.center),
            const SizedBox(height: 8),
            Text(subtitle,
                style: AppTypography.bodySmall, textAlign: TextAlign.center),
            if (actionLabel != null && onAction != null) ...[
              const SizedBox(height: 24),
              GoldButton(
                label: actionLabel!,
                onPressed: onAction,
                width: 160,
                height: 44,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// ─── Shimmer helpers ──────────────────────────────────────────────────────────
class ShimmerBox extends StatelessWidget {
  final double height;
  final double? width;
  final BorderRadius? borderRadius;

  const ShimmerBox({
    super.key,
    required this.height,
    this.width,
    this.borderRadius,
  });

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: AppColors.divider,
      highlightColor: AppColors.surface,
      child: Container(
        height: height,
        width: width ?? double.infinity,
        decoration: BoxDecoration(
          color: AppColors.divider,
          borderRadius: borderRadius ?? AppTheme.chipRadius,
        ),
      ),
    );
  }
}

/// Shimmer placeholder for a generic card row
class ShimmerCardTile extends StatelessWidget {
  const ShimmerCardTile({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      padding: const EdgeInsets.all(16),
      decoration: AppTheme.cardDecoration,
      child: Shimmer.fromColors(
        baseColor: AppColors.divider,
        highlightColor: AppColors.surface,
        child: Row(
          children: [
            const ShimmerBox(height: 44, width: 44,
                borderRadius: BorderRadius.all(Radius.circular(22))),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ShimmerBox(height: 14, width: MediaQuery.of(context).size.width * 0.5),
                  const SizedBox(height: 8),
                  const ShimmerBox(height: 12, width: 100),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Shimmer placeholder for a tournament card with banner
class ShimmerTournamentCard extends StatelessWidget {
  const ShimmerTournamentCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      decoration: AppTheme.cardDecoration,
      child: Shimmer.fromColors(
        baseColor: AppColors.divider,
        highlightColor: AppColors.surface,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const ShimmerBox(
                height: 140,
                borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ShimmerBox(height: 18,
                      width: MediaQuery.of(context).size.width * 0.6),
                  const SizedBox(height: 10),
                  const ShimmerBox(height: 14, width: 120),
                  const SizedBox(height: 16),
                  const ShimmerBox(height: 44),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Shimmer list — drop-in replacement while loading
class ShimmerList extends StatelessWidget {
  final int count;
  final Widget Function() itemBuilder;

  const ShimmerList({
    super.key,
    this.count = 3,
    required this.itemBuilder,
  });

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      physics: const NeverScrollableScrollPhysics(),
      shrinkWrap: true,
      itemCount: count,
      itemBuilder: (_, __) => itemBuilder(),
    );
  }
}

// ─── OfflineBanner ────────────────────────────────────────────────────────────
class OfflineBanner extends StatelessWidget {
  const OfflineBanner({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      color: AppColors.error.withOpacity(0.9),
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.wifi_off_rounded, color: Colors.white, size: 16),
          const SizedBox(width: 8),
          Text('No internet connection',
              style: AppTypography.labelSmall
                  .copyWith(color: Colors.white, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}

// ─── AvatarWithStatus ─────────────────────────────────────────────────────────
class AvatarWithStatus extends StatelessWidget {
  final String? photoUrl;
  final String name;
  final bool isOnline;
  final double radius;

  const AvatarWithStatus({
    super.key,
    this.photoUrl,
    required this.name,
    this.isOnline = false,
    this.radius = 22,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        CircleAvatar(
          radius: radius,
          backgroundColor: AppColors.primaryBrand.withOpacity(0.15),
          backgroundImage: photoUrl != null && photoUrl!.isNotEmpty
              ? NetworkImage(photoUrl!)
              : null,
          child: (photoUrl == null || photoUrl!.isEmpty)
              ? Text(
                  name.isNotEmpty ? name[0].toUpperCase() : '?',
                  style: AppTypography.labelLarge
                      .copyWith(color: AppColors.primaryBrand),
                )
              : null,
        ),
        if (isOnline)
          Positioned(
            right: 0,
            bottom: 0,
            child: Container(
              width: radius * 0.55,
              height: radius * 0.55,
              decoration: BoxDecoration(
                color: AppColors.success,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 1.5),
              ),
            ),
          ),
      ],
    );
  }
}

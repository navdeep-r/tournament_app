import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:shimmer/shimmer.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../shared/widgets/gold_button.dart';
import '../../data/models/tournament_model.dart';

// ─── UserStatsBanner ──────────────────────────────────────────────────────────
class UserStatsBanner extends StatelessWidget {
  final String name;
  final String? photoUrl;
  final int? queueNumber;
  final bool isActive;
  final int wins;

  const UserStatsBanner({
    super.key,
    required this.name,
    this.photoUrl,
    this.queueNumber,
    required this.isActive,
    required this.wins,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(20),
      decoration: AppTheme.goldBorderDecoration,
      child: Row(
        children: [
          // Avatar
          CircleAvatar(
            radius: 32,
            backgroundColor: AppColors.primaryBrand.withOpacity(0.2),
            backgroundImage: photoUrl != null
                ? CachedNetworkImageProvider(photoUrl!)
                : null,
            child: photoUrl == null
                ? Text(name.isNotEmpty ? name[0].toUpperCase() : '?',
                    style: AppTypography.headlineSmall
                        .copyWith(color: AppColors.primaryBrand))
                : null,
          ),
          const SizedBox(width: 16),
          // Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name, style: AppTypography.headlineSmall),
                const SizedBox(height: 4),
                Row(
                  children: [
                    _StatusChip(isActive: isActive),
                    if (queueNumber != null) ...[
                      const SizedBox(width: 8),
                      Text('Queue #$queueNumber',
                          style: AppTypography.labelMedium),
                    ],
                  ],
                ),
              ],
            ),
          ),
          // Wins
          Column(
            children: [
              Text('$wins', style: AppTypography.headlineLarge
                  .copyWith(color: AppColors.primaryBrand)),
              Text('Wins', style: AppTypography.caption),
            ],
          ),
        ],
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  final bool isActive;
  const _StatusChip({required this.isActive});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: (isActive ? AppColors.success : AppColors.eliminated)
            .withOpacity(0.12),
        borderRadius: AppTheme.chipRadius,
      ),
      child: Text(
        isActive ? 'Active' : 'Eliminated',
        style: AppTypography.labelSmall.copyWith(
          color: isActive ? AppColors.success : AppColors.eliminated,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

// ─── ActiveTournamentCard ─────────────────────────────────────────────────────
class ActiveTournamentCard extends StatefulWidget {
  final TournamentModel tournament;
  final bool isRegistered;
  final VoidCallback onViewBoard;
  final VoidCallback onRegister;

  const ActiveTournamentCard({
    super.key,
    required this.tournament,
    required this.isRegistered,
    required this.onViewBoard,
    required this.onRegister,
  });

  @override
  State<ActiveTournamentCard> createState() => _ActiveTournamentCardState();
}

class _ActiveTournamentCardState extends State<ActiveTournamentCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 900))
      ..repeat(reverse: true);
    _pulseAnimation =
        Tween<double>(begin: 0.4, end: 1.0).animate(_pulseController);
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = widget.tournament;
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: AppTheme.cardDecoration,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Banner image
          if (t.bannerUrl != null)
            ClipRRect(
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(16)),
              child: CachedNetworkImage(
                imageUrl: t.bannerUrl!,
                height: 160,
                width: double.infinity,
                fit: BoxFit.cover,
                placeholder: (_, __) => _shimmerBox(height: 160),
              ),
            ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(t.name, style: AppTypography.headlineSmall),
                    ),
                    // LIVE badge
                    Row(
                      children: [
                        FadeTransition(
                          opacity: _pulseAnimation,
                          child: const CircleAvatar(
                              radius: 5,
                              backgroundColor: AppColors.error),
                        ),
                        const SizedBox(width: 5),
                        Text('LIVE',
                            style: AppTypography.labelSmall.copyWith(
                                color: AppColors.error,
                                fontWeight: FontWeight.w700)),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  '${t.activeCount} / ${t.maxParticipants} Active',
                  style: AppTypography.bodySmall,
                ),
                const SizedBox(height: 16),
                GoldButton(
                    label: 'View Live Board', onPressed: widget.onViewBoard),
                if (!widget.isRegistered) ...[
                  const SizedBox(height: 8),
                  GoldButton(
                    label: 'Register Now — ${t.entryFeeFormatted}',
                    onPressed: widget.onRegister,
                    outlined: true,
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─── UpcomingTournamentCard ───────────────────────────────────────────────────
class UpcomingTournamentCard extends StatelessWidget {
  final TournamentModel tournament;
  final bool isRegistered;
  final VoidCallback onJoin;
  final VoidCallback onTap;

  const UpcomingTournamentCard({
    super.key,
    required this.tournament,
    required this.isRegistered,
    required this.onJoin,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final t = tournament;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 220,
        margin: const EdgeInsets.only(right: 12),
        decoration: AppTheme.cardDecoration,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Thumbnail
            ClipRRect(
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(16)),
              child: t.bannerUrl != null
                  ? CachedNetworkImage(
                      imageUrl: t.bannerUrl!,
                      height: 110,
                      width: double.infinity,
                      fit: BoxFit.cover)
                  : Container(
                      height: 110,
                      color: AppColors.primaryBrand.withOpacity(0.15),
                      child: const Icon(Icons.emoji_events_rounded,
                          color: AppColors.primaryBrand, size: 40)),
            ),
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Time chip
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: AppColors.primaryBrand.withOpacity(0.1),
                      borderRadius: AppTheme.chipRadius,
                    ),
                    child: Text(
                      _formatTime(t.startTime),
                      style: AppTypography.labelSmall
                          .copyWith(color: AppColors.primaryBrand),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(t.name,
                      style: AppTypography.labelLarge, maxLines: 2),
                  const SizedBox(height: 4),
                  Text('${t.registeredCount} registered',
                      style: AppTypography.caption),
                  const SizedBox(height: 10),
                  if (isRegistered)
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: AppColors.success.withOpacity(0.1),
                        borderRadius: AppTheme.chipRadius,
                      ),
                      child: Text('Registered',
                          style: AppTypography.labelSmall
                              .copyWith(color: AppColors.success)),
                    )
                  else
                    GoldButton(
                      label: 'Join — ${t.entryFeeFormatted}',
                      onPressed: onJoin,
                      height: 36,
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatTime(DateTime dt) {
    final h = dt.hour % 12 == 0 ? 12 : dt.hour % 12;
    final m = dt.minute.toString().padLeft(2, '0');
    final period = dt.hour < 12 ? 'AM' : 'PM';
    return '$h:$m $period';
  }
}

// ─── Shimmer helper ───────────────────────────────────────────────────────────
Widget _shimmerBox({double height = 80, double? width}) {
  return Shimmer.fromColors(
    baseColor: AppColors.divider,
    highlightColor: AppColors.surface,
    child: Container(
      height: height,
      width: width,
      color: AppColors.divider,
    ),
  );
}

Widget tournamentCardShimmer() {
  return Container(
    margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
    decoration: AppTheme.cardDecoration,
    child: Shimmer.fromColors(
      baseColor: AppColors.divider,
      highlightColor: AppColors.surface,
      child: Column(
        children: [
          Container(height: 120, color: AppColors.divider),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(children: [
              Container(height: 18, color: AppColors.divider),
              const SizedBox(height: 8),
              Container(height: 14, width: 120, color: AppColors.divider),
            ]),
          ),
        ],
      ),
    ),
  );
}

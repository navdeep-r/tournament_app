import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/theme/app_theme.dart';
import '../../data/models/liveboard_models.dart';

class ParticipantTile extends StatefulWidget {
  final ParticipantModel participant;

  const ParticipantTile({super.key, required this.participant});

  @override
  State<ParticipantTile> createState() => _ParticipantTileState();
}

class _ParticipantTileState extends State<ParticipantTile>
    with SingleTickerProviderStateMixin {
  late AnimationController _flashController;
  late Animation<Color?> _bgAnimation;
  ParticipantStatus? _prevStatus;

  @override
  void initState() {
    super.initState();
    _flashController = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 400));
    _bgAnimation = ColorTween(
      begin: Colors.transparent,
      end: AppColors.primaryBrand.withOpacity(0.18),
    ).animate(CurvedAnimation(parent: _flashController, curve: Curves.easeOut));
  }

  @override
  void didUpdateWidget(ParticipantTile old) {
    super.didUpdateWidget(old);
    if (old.participant.status != widget.participant.status) {
      _flashController.forward(from: 0).then((_) => _flashController.reverse());
    }
    _prevStatus = old.participant.status;
  }

  @override
  void dispose() {
    _flashController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final p = widget.participant;
    final isEliminated = p.status == ParticipantStatus.eliminated;
    final isAdvancing = p.status == ParticipantStatus.advancing ||
        p.status == ParticipantStatus.winner;

    return AnimatedBuilder(
      animation: _bgAnimation,
      builder: (context, child) {
        return AnimatedContainer(
          duration: const Duration(milliseconds: 400),
          curve: Curves.easeInOut,
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          decoration: BoxDecoration(
            color: _bgAnimation.value ??
                (isEliminated
                    ? const Color(0xFFF5F5F5)
                    : AppColors.surface),
            borderRadius: AppTheme.cardRadius,
            border: Border(
              left: BorderSide(
                color: isEliminated
                    ? Colors.transparent
                    : isAdvancing
                        ? AppColors.primaryBrand
                        : AppColors.success,
                width: 3,
              ),
            ),
            boxShadow: isEliminated ? [] : [AppTheme.cardShadow],
          ),
          child: child,
        );
      },
      child: Opacity(
        opacity: isEliminated ? 0.5 : 1.0,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              // Avatar
              _buildAvatar(p, isEliminated, isAdvancing),
              const SizedBox(width: 12),
              // Name + queue
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      p.name,
                      style: AppTypography.labelLarge.copyWith(
                        decoration: isEliminated
                            ? TextDecoration.lineThrough
                            : null,
                        color: isEliminated
                            ? AppColors.eliminated
                            : AppColors.textPrimary,
                      ),
                    ),
                    Text('#${p.queueNumber}',
                        style: AppTypography.caption),
                  ],
                ),
              ),
              // Status chip
              _StatusChip(status: p.status),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAvatar(
      ParticipantModel p, bool isEliminated, bool isAdvancing) {
    Widget avatar = CircleAvatar(
      radius: 22,
      backgroundColor: AppColors.primaryBrand.withOpacity(0.15),
      backgroundImage: p.photoUrl != null
          ? CachedNetworkImageProvider(p.photoUrl!)
          : null,
      child: p.photoUrl == null
          ? Text(
              p.name.isNotEmpty ? p.name[0].toUpperCase() : '?',
              style: AppTypography.labelLarge
                  .copyWith(color: AppColors.primaryBrand),
            )
          : null,
    );

    if (isEliminated) {
      avatar = ColorFiltered(
        colorFilter: const ColorFilter.matrix([
          0.2126, 0.7152, 0.0722, 0, 0,
          0.2126, 0.7152, 0.0722, 0, 0,
          0.2126, 0.7152, 0.0722, 0, 0,
          0, 0, 0, 1, 0,
        ]),
        child: avatar,
      );
    }

    if (isAdvancing) {
      avatar = Container(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: AppColors.primaryBrand, width: 2.5),
        ),
        child: avatar,
      );
    }

    return avatar;
  }
}

class _StatusChip extends StatelessWidget {
  final ParticipantStatus status;
  const _StatusChip({required this.status});

  @override
  Widget build(BuildContext context) {
    final (label, color, icon) = switch (status) {
      ParticipantStatus.active => ('Active', AppColors.success, Icons.check_circle_outline),
      ParticipantStatus.eliminated => ('Eliminated', AppColors.eliminated, Icons.cancel_outlined),
      ParticipantStatus.advancing => ('Advanced', AppColors.primaryBrand, Icons.arrow_circle_up_outlined),
      ParticipantStatus.winner => ('Winner', AppColors.primaryBrand, Icons.emoji_events_outlined),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: AppTheme.chipRadius,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 14),
          const SizedBox(width: 4),
          Text(label,
              style:
                  AppTypography.labelSmall.copyWith(color: color, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}

// ─── Live badge with pulsing dot ──────────────────────────────────────────────
class LiveBadge extends StatefulWidget {
  final int activeCount;
  const LiveBadge({super.key, required this.activeCount});

  @override
  State<LiveBadge> createState() => _LiveBadgeState();
}

class _LiveBadgeState extends State<LiveBadge>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _pulseAnim;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 800))
      ..repeat(reverse: true);
    _pulseAnim = Tween<double>(begin: 0.3, end: 1.0).animate(_pulseController);
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.error.withOpacity(0.1),
        borderRadius: AppTheme.chipRadius,
        border: Border.all(color: AppColors.error.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          FadeTransition(
            opacity: _pulseAnim,
            child: const CircleAvatar(
                radius: 4, backgroundColor: AppColors.error),
          ),
          const SizedBox(width: 6),
          Text('LIVE · ${widget.activeCount} active',
              style: AppTypography.labelSmall
                  .copyWith(color: AppColors.error, fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }
}

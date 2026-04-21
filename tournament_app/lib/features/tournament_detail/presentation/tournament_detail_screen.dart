import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:tournament_app/features/tournament_detail/bloc/tournament_detail_bloc.dart';
import 'package:tournament_app/features/home/data/models/tournament_model.dart';
import 'package:tournament_app/features/tournament_detail/presentation/widgets/detail_widgets.dart';
import 'package:tournament_app/core/theme/app_colors.dart';
import 'package:tournament_app/core/theme/app_typography.dart';
import 'package:tournament_app/core/theme/app_theme.dart';
import 'package:tournament_app/core/utils/formatters.dart';
import 'package:tournament_app/shared/widgets/empty_state.dart';

class TournamentDetailScreen extends StatefulWidget {
  final String tournamentId;
  const TournamentDetailScreen({super.key, required this.tournamentId});

  @override
  State<TournamentDetailScreen> createState() => _TournamentDetailScreenState();
}

class _TournamentDetailScreenState extends State<TournamentDetailScreen> {
  @override
  void initState() {
    super.initState();
    context
        .read<TournamentDetailBloc>()
        .add(TournamentDetailLoadRequested(widget.tournamentId));
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<TournamentDetailBloc, TournamentDetailState>(
      builder: (context, state) {
        if (state is TournamentDetailLoading) {
          return _buildSkeleton();
        }
        if (state is TournamentDetailError) {
          return Scaffold(
            appBar: AppBar(),
            body: EmptyState.networkError(
              onRetry: () => context.read<TournamentDetailBloc>().add(
                  TournamentDetailLoadRequested(widget.tournamentId)),
            ),
          );
        }
        if (state is TournamentDetailLoaded) {
          return _buildLoaded(context, state);
        }
        return const SizedBox.shrink();
      },
    );
  }

  Widget _buildLoaded(BuildContext context, TournamentDetailLoaded state) {
    final t = state.tournament;
    return Scaffold(
      backgroundColor: AppColors.background,
      body: RefreshIndicator(
        color: AppColors.primaryBrand,
        onRefresh: () async => context.read<TournamentDetailBloc>().add(
            TournamentDetailRefreshRequested(widget.tournamentId)),
        child: CustomScrollView(
          slivers: [
            // ── SliverAppBar with Hero banner ─────────────────────────
            SliverAppBar(
              expandedHeight: 280,
              pinned: true,
              backgroundColor: AppColors.surface,
              foregroundColor: AppColors.textPrimary,
              leading: IconButton(
                icon: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.35),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.arrow_back_ios_new_rounded,
                      color: Colors.white, size: 16),
                ),
                onPressed: () {
                   if (context.canPop()) {
                     context.pop();
                   } else {
                     context.go('/home');
                   }
                 },
              ),
              actions: [
                if (t.isLive)
                  Container(
                    margin: const EdgeInsets.only(right: 12),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: AppColors.error,
                      borderRadius: AppTheme.chipRadius,
                    ),
                    child: Row(children: [
                      const CircleAvatar(
                          radius: 4, backgroundColor: Colors.white),
                      const SizedBox(width: 6),
                      Text('LIVE',
                          style: AppTypography.labelSmall.copyWith(
                              color: Colors.white, fontWeight: FontWeight.w800)),
                    ]),
                  ),
              ],
              flexibleSpace: FlexibleSpaceBar(
                titlePadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                title: Text(
                  t.name,
                  style: AppTypography.headlineSmall
                      .copyWith(color: Colors.white, fontSize: 16),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                background: Stack(
                  fit: StackFit.expand,
                  children: [
                    // Banner image with Hero
                    Hero(
                      tag: 'tournament_banner_${t.id}',
                      child: t.bannerUrl != null
                          ? CachedNetworkImage(
                              imageUrl: t.bannerUrl!,
                              fit: BoxFit.cover,
                              placeholder: (_, __) =>
                                  Container(color: AppColors.divider),
                            )
                          : Container(
                              decoration: const BoxDecoration(
                                gradient: AppColors.goldGradient,
                              ),
                              child: const Icon(Icons.emoji_events_rounded,
                                  color: Colors.white54, size: 80),
                            ),
                    ),
                    // Gradient overlay
                    Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.transparent,
                            Colors.black.withOpacity(0.7),
                          ],
                          stops: const [0.4, 1.0],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // ── Body content ────────────────────────────────────────
            SliverToBoxAdapter(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 20),

                  // Status row
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        _StatusChip(tournament: t),
                        ParticipantCountChip(
                          registered: t.registeredCount,
                          max: t.maxParticipants,
                        ),
                        _DateChip(tournament: t),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),

                  // Description
                  if (t.description.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 8),
                      child: Text(t.description,
                          style: AppTypography.bodyMedium
                              .copyWith(color: AppColors.textSecondary)),
                    ),

                  const SizedBox(height: 12),

                  // Participant counts
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Row(
                      children: [
                        _CountCard(label: 'Registered', value: t.registeredCount),
                        const SizedBox(width: 10),
                        _CountCard(label: 'Active Today', value: t.activeCount),
                        const SizedBox(width: 10),
                        _CountCard(
                            label: 'Spots Left',
                            value: t.spotsLeft,
                            highlight: true),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Rules
                  if (t.rules.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: RulesSection(rules: t.rules),
                    ),
                  const SizedBox(height: 20),

                  // Rounds
                  if (t.rounds.isNotEmpty) ...[
                    RoundsSection(rounds: t.rounds),
                    const SizedBox(height: 20),
                  ],

                  // Photo gallery
                  if (t.photoUrls.isNotEmpty) ...[
                    PhotoGallerySection(photoUrls: t.photoUrls),
                    const SizedBox(height: 20),
                  ],

                  // Registration section (only if upcoming)
                  if (t.isUpcoming) ...[
                    RegistrationSection(
                      tournament: t,
                      isRegistered: state.isRegistered,
                      onRegister: () =>
                          context.push('/tournament/${t.id}/checkout'),
                    ),
                    const SizedBox(height: 32),
                  ],

                  // View live board button (if active)
                  if (t.isLive)
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
                      child: ElevatedButton.icon(
                        onPressed: () => context.push('/liveboard/${t.id}'),
                        icon: const Icon(Icons.live_tv_rounded),
                        label: const Text('View Live Board'),
                        style: ElevatedButton.styleFrom(
                          minimumSize: const Size(double.infinity, 54),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSkeleton() {
    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 280,
            pinned: true,
            flexibleSpace: FlexibleSpaceBar(
              background: Container(color: AppColors.divider),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: ShimmerList(
                count: 4,
                itemBuilder: () => const Padding(
                  padding: EdgeInsets.only(bottom: 12),
                  child: ShimmerBox(height: 80),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Local sub-widgets ────────────────────────────────────────────────────────
class _StatusChip extends StatelessWidget {
  final TournamentModel tournament;
  const _StatusChip({required this.tournament});

  @override
  Widget build(BuildContext context) {
    final (label, color) = tournament.isLive
        ? ('Live', AppColors.success)
        : tournament.isUpcoming
            ? ('Upcoming', AppColors.primaryBrand)
            : ('Completed', AppColors.eliminated);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: AppTheme.chipRadius,
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Text(label,
          style: AppTypography.labelSmall
              .copyWith(color: color, fontWeight: FontWeight.w700)),
    );
  }
}

class _DateChip extends StatelessWidget {
  final TournamentModel tournament;
  const _DateChip({required this.tournament});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: AppTheme.chipRadius,
        border: Border.all(color: AppColors.divider),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.calendar_today_outlined,
              size: 13, color: AppColors.textSecondary),
          const SizedBox(width: 5),
          Text(DateFormatter.formatRelativeDate(tournament.startTime),
              style: AppTypography.labelSmall),
          const SizedBox(width: 5),
          Text(DateFormatter.formatTime(tournament.startTime),
              style: AppTypography.labelSmall
                  .copyWith(color: AppColors.primaryBrand)),
        ],
      ),
    );
  }
}

class _CountCard extends StatelessWidget {
  final String label;
  final int value;
  final bool highlight;
  const _CountCard(
      {required this.label, required this.value, this.highlight = false});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: highlight
              ? AppColors.primaryBrand.withOpacity(0.08)
              : AppColors.surface,
          borderRadius: AppTheme.cardRadius,
          border: Border.all(
            color: highlight
                ? AppColors.primaryBrand.withOpacity(0.3)
                : AppColors.divider,
          ),
        ),
        child: Column(
          children: [
            Text('$value',
                style: AppTypography.headlineSmall.copyWith(
                  color:
                      highlight ? AppColors.primaryBrand : AppColors.textPrimary,
                )),
            const SizedBox(height: 2),
            Text(label,
                style: AppTypography.caption, textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }
}

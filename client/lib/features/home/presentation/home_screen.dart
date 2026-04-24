import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:tournament_app/features/home/bloc/home_bloc.dart';
import 'package:tournament_app/features/home/data/models/tournament_model.dart';
import 'package:tournament_app/features/home/presentation/widgets/tournament_widgets.dart';
import 'package:tournament_app/core/theme/app_colors.dart';
import 'package:tournament_app/core/theme/app_typography.dart';
import 'package:tournament_app/core/theme/app_theme.dart';
import 'package:tournament_app/shared/widgets/cream_scaffold.dart';
import 'package:tournament_app/shared/widgets/gold_button.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentTab = 0;
  Timer? _refreshTimer;

  @override
  void initState() {
    super.initState();
    context.read<HomeBloc>().add(HomeLoadRequested());
    _refreshTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      if (!mounted) return;
      context.read<HomeBloc>().add(HomeRefreshRequested());
    });
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return CreamScaffold(
      appBar: AppBar(
        title: Text('Tournament Hub', style: AppTypography.titleLarge),
        actions: [
          CircleAvatar(
            radius: 18,
            backgroundColor: AppColors.primaryBrand.withOpacity(0.15),
            child: const Icon(Icons.person_outline,
                color: AppColors.primaryBrand, size: 20),
          ),
          const SizedBox(width: 8),
          IconButton(
            icon: const Icon(Icons.notifications_none_rounded),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('No notifications yet')),
              );
            },
          ),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentTab,
        onTap: (i) {
          setState(() => _currentTab = i);
          if (i == 1) {
            final state = context.read<HomeBloc>().state;
            if (state is HomeLoaded && state.activeToday.isNotEmpty) {
              final registeredLive = state.activeToday.where((t) {
                return state.registeredTournamentIds.contains(t.id);
              }).toList();
              if (registeredLive.isNotEmpty) {
                context.push('/liveboard/${registeredLive.first.id}');
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text(
                      'You are not registered in any live tournament yet',
                    ),
                  ),
                );
              }
            } else {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('No active tournament live right now')),
              );
            }
          }
          if (i == 2) context.push('/profile');
        },
        items: const [
          BottomNavigationBarItem(
              icon: Icon(Icons.home_outlined),
              activeIcon: Icon(Icons.home_rounded),
              label: 'Home'),
          BottomNavigationBarItem(
              icon: Icon(Icons.wifi_tethering),
              activeIcon: Icon(Icons.wifi_tethering),
              label: 'Live Board'),
          BottomNavigationBarItem(
              icon: Icon(Icons.person_outline),
              activeIcon: Icon(Icons.person_rounded),
              label: 'Profile'),
        ],
      ),
      body: BlocBuilder<HomeBloc, HomeState>(
        builder: (context, state) {
          if (state is HomeLoading) return _buildSkeleton();
          if (state is HomeError) return _buildError(state.message);
          if (state is HomeLoaded) return _buildContent(state);
          return const SizedBox.shrink();
        },
      ),
    );
  }

  Widget _buildContent(HomeLoaded state) {
    final registeredTournamentIds = state.registeredTournamentIds;
    return RefreshIndicator(
      color: AppColors.primaryBrand,
      onRefresh: () async =>
          context.read<HomeBloc>().add(HomeRefreshRequested()),
      child: ListView(
        padding: const EdgeInsets.symmetric(vertical: 16),
        children: [
          // User stats
          const UserStatsBanner(
            name: 'Player',
            isActive: true,
            wins: 3,
          ),
          const SizedBox(height: 24),

          // Active tournaments
          if (state.activeToday.isNotEmpty) ...[
            _SectionHeader(title: 'Live Board'),
            const SizedBox(height: 12),
            ...state.activeToday.map((t) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: ActiveTournamentCard(
                    tournament: t,
                    isRegistered: registeredTournamentIds.contains(t.id),
                    onViewBoard: () =>
                        context.push('/liveboard/${t.id}'),
                    onRegister: () =>
                        context.push('/tournament/${t.id}/checkout'),
                  ),
                )),
            const SizedBox(height: 8),
          ],

          // Today's schedule
          if (state.scheduled.isNotEmpty) ...[
            _SectionHeader(title: 'Scheduled Tournaments'),
            const SizedBox(height: 12),
            SizedBox(
              height: 270,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.only(left: 16),
                itemCount: state.scheduled.length,
                itemBuilder: (_, i) => UpcomingTournamentCard(
                  tournament: state.scheduled[i],
                  isRegistered:
                      registeredTournamentIds.contains(state.scheduled[i].id),
                  onJoin: () => context
                      .push('/tournament/${state.scheduled[i].id}/checkout'),
                  onTap: () => context
                      .go('/tournament/${state.scheduled[i].id}'),
                ),
              ),
            ),
            const SizedBox(height: 24),
          ],

          // History
          if (state.history.isNotEmpty) ...[
            _SectionHeader(title: 'My Tournament History'),
            const SizedBox(height: 12),
            ...state.history.map((p) => _HistoryTile(participation: p)),
            const SizedBox(height: 16),
          ],
        ],
      ),
    );
  }

  Widget _buildSkeleton() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        tournamentCardShimmer(),
        const SizedBox(height: 16),
        tournamentCardShimmer(),
        const SizedBox(height: 16),
        tournamentCardShimmer(),
      ],
    );
  }

  Widget _buildError(String msg) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.wifi_off_rounded,
                color: AppColors.textSecondary, size: 48),
            const SizedBox(height: 16),
            Text('Couldn\'t load tournaments',
                style: AppTypography.headlineSmall),
            const SizedBox(height: 8),
            Text(msg,
                style: AppTypography.bodySmall, textAlign: TextAlign.center),
            const SizedBox(height: 24),
            GoldButton(
              label: 'Retry',
              onPressed: () =>
                  context.read<HomeBloc>().add(HomeLoadRequested()),
              width: 160,
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  const _SectionHeader({required this.title});

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Text(title, style: AppTypography.headlineSmall),
      );
}

class _HistoryTile extends StatelessWidget {
  final ParticipationModel participation;
  const _HistoryTile({required this.participation});

  @override
  Widget build(BuildContext context) {
    final p = participation;
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      padding: const EdgeInsets.all(14),
      decoration: AppTheme.cardDecoration,
      child: Row(
        children: [
          const Icon(Icons.emoji_events_outlined,
              color: AppColors.primaryBrand, size: 28),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(p.tournamentName,
                    style: AppTypography.labelLarge),
                Text('Queue #${p.queueNumber}',
                    style: AppTypography.caption),
              ],
            ),
          ),
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: (p.isWinner ? AppColors.success : AppColors.eliminated)
                  .withOpacity(0.1),
              borderRadius: AppTheme.chipRadius,
            ),
            child: Text(
              p.isWinner ? 'Winner' : p.status,
              style: AppTypography.labelSmall.copyWith(
                color:
                    p.isWinner ? AppColors.success : AppColors.eliminated,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

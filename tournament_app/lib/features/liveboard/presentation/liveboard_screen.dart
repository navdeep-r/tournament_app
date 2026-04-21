import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:tournament_app/features/liveboard/bloc/liveboard_bloc.dart';
import 'package:tournament_app/features/liveboard/presentation/widgets/participant_tile.dart';
import 'package:tournament_app/features/liveboard/data/models/liveboard_models.dart';
import 'package:tournament_app/core/theme/app_colors.dart';
import 'package:tournament_app/core/theme/app_typography.dart';
import 'package:tournament_app/core/theme/app_theme.dart';
import 'package:tournament_app/shared/widgets/animations.dart';
import 'package:tournament_app/shared/widgets/cream_scaffold.dart';

class LiveboardScreen extends StatefulWidget {
  final String tournamentId;
  const LiveboardScreen({super.key, required this.tournamentId});

  @override
  State<LiveboardScreen> createState() => _LiveboardScreenState();
}

class _LiveboardScreenState extends State<LiveboardScreen>
    with SingleTickerProviderStateMixin {
  TabController? _tabController;

  @override
  void initState() {
    super.initState();
    context
        .read<LiveboardBloc>()
        .add(LiveboardConnectRequested(widget.tournamentId));
  }

  @override
  void dispose() {
    _tabController?.dispose();
    context.read<LiveboardBloc>().add(LiveboardDisconnectRequested());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<LiveboardBloc, LiveboardState>(
      builder: (context, state) {
        if (state is LiveboardConnecting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator(color: AppColors.primaryBrand)),
          );
        }

        if (state is LiveboardError) {
          return Scaffold(
            appBar: AppBar(title: const Text('Live Board')),
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.wifi_off_rounded,
                      color: AppColors.textSecondary, size: 48),
                  const SizedBox(height: 16),
                  Text(state.message, style: AppTypography.bodyMedium),
                ],
              ),
            ),
          );
        }

        if (state is LiveboardLoaded) {
          final rounds = state.rounds;
          if (_tabController == null ||
              _tabController!.length != rounds.length) {
            _tabController?.dispose();
            _tabController = TabController(
                length: rounds.length, vsync: this,
                initialIndex: state.activeRoundIndex);
            _tabController!.addListener(() {
              context.read<LiveboardBloc>().add(
                  LiveboardRoundChanged(_tabController!.index));
            });
          }

          final activeCount = rounds.isNotEmpty
              ? rounds[state.activeRoundIndex]
                  .participants
                  .where((p) => p.status == ParticipantStatus.active)
                  .length
              : 0;

          return CreamScaffold(
            appBar: AppBar(
              title: Text('Live Board', style: AppTypography.titleLarge),
              actions: [
                LiveBadge(activeCount: activeCount),
                const SizedBox(width: 12),
              ],
              bottom: rounds.length > 1
                  ? TabBar(
                      controller: _tabController,
                      isScrollable: true,
                      labelColor: AppColors.primaryBrand,
                      unselectedLabelColor: AppColors.textSecondary,
                      indicatorColor: AppColors.primaryBrand,
                      indicatorWeight: 2.5,
                      labelStyle: AppTypography.labelLarge,
                      tabs: rounds
                          .map((r) => Tab(text: 'Round ${r.roundNumber}'))
                          .toList(),
                    )
                  : null,
            ),
            body: rounds.isEmpty
                ? _buildEmpty()
                : TabBarView(
                    controller: _tabController,
                    children: rounds.map((round) {
                      final sorted = [...round.participants]
                        ..sort((a, b) => a.queueNumber.compareTo(b.queueNumber));
                      return ListView.builder(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        itemCount: sorted.length,
                        itemBuilder: (_, i) =>
                            ParticipantTile(participant: sorted[i]),
                      );
                    }).toList(),
                  ),
          );
        }

        return const SizedBox.shrink();
      },
    );
  }

  Widget _buildEmpty() => const Center(
        child: Text('No participants yet.',
            style: TextStyle(color: AppColors.textSecondary)),
      );
}

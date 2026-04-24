import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:tournament_app/features/auth/bloc/auth_bloc.dart';
import 'package:tournament_app/features/admin/bloc/admin_bloc.dart';
import 'package:tournament_app/core/theme/app_colors.dart';
import 'package:tournament_app/core/theme/app_typography.dart';
import 'package:tournament_app/core/theme/app_theme.dart';
import 'package:tournament_app/shared/widgets/cream_scaffold.dart';
import 'package:tournament_app/shared/widgets/gold_button.dart';
import 'package:tournament_app/core/constants/asset_constants.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});
  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  int _tab = 0;
  Timer? _refreshTimer;

  @override
  void initState() {
    super.initState();
    context.read<AdminBloc>().add(AdminDashboardLoadRequested());
    _refreshTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      if (!mounted) return;
      context.read<AdminBloc>().add(AdminDashboardLoadRequested());
    });
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<AuthBloc, AuthState>(
      listener: (context, state) {
        if (state is AuthUnauthenticated) {
          context.go('/login');
        }
      },
      child: CreamScaffold(
        appBar: AppBar(
          title: Text('Admin', style: AppTypography.titleLarge),
          actions: [
            IconButton(
              icon: const Icon(Icons.logout_rounded),
              onPressed: () => context.read<AuthBloc>().add(AuthSignOutRequested()),
            )
          ],
        ),
        bottomNavigationBar: BottomNavigationBar(
          currentIndex: _tab,
          onTap: (i) => setState(() => _tab = i),
          items: const [
            BottomNavigationBarItem(icon: Icon(Icons.dashboard_outlined), activeIcon: Icon(Icons.dashboard_rounded), label: 'Dashboard'),
            BottomNavigationBarItem(icon: Icon(Icons.emoji_events_outlined), activeIcon: Icon(Icons.emoji_events_rounded), label: 'Tournaments'),
            BottomNavigationBarItem(icon: Icon(Icons.live_tv_outlined), activeIcon: Icon(Icons.live_tv_rounded), label: 'Live'),
            BottomNavigationBarItem(icon: Icon(Icons.people_outline), activeIcon: Icon(Icons.people_rounded), label: 'Participants'),
          ],
        ),
        body: BlocBuilder<AdminBloc, AdminState>(
          builder: (context, state) {
            Map<String, dynamic>? stats;
            List<dynamic>? tournaments;

            if (state is AdminDashboardLoaded) {
              stats = state.stats;
              tournaments = state.tournaments;
            }

            return IndexedStack(
              index: _tab,
              children: [
                _DashboardTab(stats: stats),
                _TournamentsTab(tournaments: tournaments ?? []),
                _LiveTab(tournaments: tournaments ?? []),
                _ParticipantsTab(tournaments: tournaments ?? []),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _DashboardTab extends StatelessWidget {
  final Map<String, dynamic>? stats;
  const _DashboardTab({this.stats});

  @override
  Widget build(BuildContext context) {
    if (stats == null) {
      return const Center(child: CircularProgressIndicator());
    }
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('Overview', style: AppTypography.headlineSmall),
        const SizedBox(height: 16),
        GridView.count(
          crossAxisCount: 2, shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisSpacing: 12, mainAxisSpacing: 12, childAspectRatio: 1.4,
          children: [
            _StatCard(label: 'Total Users', value: '${stats!['total_active_users'] ?? 0}', icon: Icons.people_rounded),
            _StatCard(label: 'Active Tournaments', value: '${stats!['active_tournaments'] ?? 0}', icon: Icons.emoji_events_rounded),
            _StatCard(label: "Today's Participants", value: '${stats!['registrations_today'] ?? 0}', icon: Icons.how_to_reg_rounded),
            _StatCard(label: "Live Tournaments", value: '${stats!['live_tournaments'] ?? 0}', icon: Icons.schedule_rounded),
          ],
        ),
        const SizedBox(height: 24),
        Text('Quick Actions', style: AppTypography.headlineSmall),
        const SizedBox(height: 12),
        GridView.count(
          crossAxisCount: 2, shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisSpacing: 12, mainAxisSpacing: 12, childAspectRatio: 1.8,
          children: [
            _QA(icon: Icons.add_circle_outline, label: 'New Tournament', onTap: () => context.go('/admin/tournament/create')),
            _QA(
              icon: Icons.refresh,
              label: 'Refresh',
              onTap: () {
                context.read<AdminBloc>().add(AdminDashboardLoadRequested());
              },
            ),
          ],
        ),
      ]),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label, value; final IconData icon;
  const _StatCard({required this.label, required this.value, required this.icon});
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(16), decoration: AppTheme.cardDecoration,
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
      Icon(icon, color: AppColors.primaryBrand, size: 24),
      Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(value, style: AppTypography.headlineSmall.copyWith(color: AppColors.primaryBrand)),
        Text(label, style: AppTypography.caption),
      ]),
    ]),
  );
}

class _QA extends StatelessWidget {
  final IconData icon; final String label; final VoidCallback onTap; final bool accent;
  const _QA({required this.icon, required this.label, required this.onTap, this.accent = false});
  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: accent ? AppColors.primaryBrand : AppColors.surface, borderRadius: AppTheme.cardRadius, boxShadow: [AppTheme.cardShadow]),
      child: Row(children: [
        Icon(icon, color: accent ? Colors.white : AppColors.primaryBrand, size: 22),
        const SizedBox(width: 8),
        Expanded(child: Text(label, style: AppTypography.labelLarge.copyWith(color: accent ? Colors.white : AppColors.textPrimary))),
      ]),
    ),
  );
}

class _TournamentsTab extends StatelessWidget {
  final List<dynamic> tournaments;
  const _TournamentsTab({required this.tournaments});

  Future<void> _confirmDelete(BuildContext context, dynamic tournament) async {
    final id = tournament['id']?.toString();
    if (id == null || id.isEmpty) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete tournament?'),
        content: Text(
          'This will permanently delete "${tournament['name'] ?? 'this tournament'}" and related data.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.error),
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      context.read<AdminBloc>().add(AdminTournamentDeleteRequested(id));
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Delete requested...')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(children: [
        GoldButton(label: '+ Create New Tournament', onPressed: () => context.go('/admin/tournament/create'), height: 46),
        const SizedBox(height: 16),
        if (tournaments.isEmpty)
          const Expanded(child: Center(child: Text('No tournaments found'))),
        if (tournaments.isNotEmpty)
          Expanded(child: ListView.builder(
            itemCount: tournaments.length,
            itemBuilder: (_, i) {
              final t = tournaments[i];
              return Container(
                margin: const EdgeInsets.only(bottom: 10),
                padding: const EdgeInsets.all(16),
                decoration: AppTheme.cardDecoration,
                child: Row(children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: _TournamentBannerThumb(
                      imageUrl:
                          (t['banner_image_url'] ?? t['banner_url'])?.toString(),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(t['name'] ?? 'Unnamed', style: AppTypography.labelLarge, maxLines: 1, overflow: TextOverflow.ellipsis),
                    Text(t['starts_at'] != null ? t['starts_at'].toString().split('T')[0] : '', style: AppTypography.caption),
                  ])),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(color: (t['status'] == 'live' ? AppColors.success : AppColors.primaryBrand).withOpacity(0.1), borderRadius: AppTheme.chipRadius),
                    child: Text(t['status']?.toUpperCase() ?? 'DRAFT', style: AppTypography.labelSmall.copyWith(color: t['status'] == 'live' ? AppColors.success : AppColors.primaryBrand)),
                  ),
                  const SizedBox(width: 8),
                  IconButton(icon: const Icon(Icons.edit_outlined, color: AppColors.primaryBrand, size: 20), onPressed: () => context.go('/admin/tournament/${t['id']}/edit')),
                  IconButton(
                    icon: const Icon(Icons.delete_outline_rounded, color: AppColors.error, size: 20),
                    tooltip: 'Delete tournament',
                    onPressed: () => _confirmDelete(context, t),
                  ),
                ]),
              );
            },
          )),
      ]),
    );
  }
}

class _TournamentBannerThumb extends StatelessWidget {
  final String? imageUrl;
  const _TournamentBannerThumb({this.imageUrl});

  @override
  Widget build(BuildContext context) {
    if (imageUrl != null && imageUrl!.isNotEmpty) {
      return CachedNetworkImage(
        imageUrl: imageUrl!,
        height: 52,
        width: 72,
        fit: BoxFit.cover,
        errorWidget: (_, __, ___) => _fallback(),
      );
    }
    return _fallback();
  }

  Widget _fallback() => Image.asset(
        AssetConstants.defaultTournamentBanner,
        height: 52,
        width: 72,
        fit: BoxFit.cover,
      );
}

// ── Live Tab ─────────────────────────────────────────────────────────────────
// Shows only tournaments with 'live' status. No dummy data.
class _LiveTab extends StatelessWidget {
  final List<dynamic> tournaments;
  const _LiveTab({required this.tournaments});

  @override
  Widget build(BuildContext context) {
    final liveTournaments = tournaments.where((t) => t['status'] == 'live').toList();

    if (liveTournaments.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.live_tv_outlined, size: 64, color: AppColors.textSecondary.withOpacity(0.4)),
              const SizedBox(height: 16),
              Text('No Live Tournaments', style: AppTypography.headlineSmall),
              const SizedBox(height: 8),
              Text(
                'Tournaments will appear here once they are set to "Live" status.',
                style: AppTypography.bodySmall.copyWith(color: AppColors.textSecondary),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: liveTournaments.length,
      itemBuilder: (_, i) {
        final t = liveTournaments[i];
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(16),
          decoration: AppTheme.cardDecoration,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 8, height: 8,
                    decoration: const BoxDecoration(color: AppColors.error, shape: BoxShape.circle),
                  ),
                  const SizedBox(width: 8),
                  Text('LIVE', style: AppTypography.labelSmall.copyWith(color: AppColors.error, fontWeight: FontWeight.w800)),
                  const Spacer(),
                  Text('${t['registered_count'] ?? 0} participants', style: AppTypography.caption),
                ],
              ),
              const SizedBox(height: 10),
              Text(t['name'] ?? 'Unnamed', style: AppTypography.labelLarge),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => context.go('/admin/live/${t['id']}'),
                      icon: const Icon(Icons.visibility_rounded, size: 18),
                      label: const Text('View Liveboard'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}

// ── Participants Tab ─────────────────────────────────────────────────────────
// Shows a tournament selector, then participants for the selected one.
class _ParticipantsTab extends StatelessWidget {
  final List<dynamic> tournaments;
  const _ParticipantsTab({required this.tournaments});

  @override
  Widget build(BuildContext context) {
    if (tournaments.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.people_outline, size: 64, color: AppColors.textSecondary.withOpacity(0.4)),
              const SizedBox(height: 16),
              Text('No Tournaments Yet', style: AppTypography.headlineSmall),
              const SizedBox(height: 8),
              Text(
                'Create a tournament first to manage its participants.',
                style: AppTypography.bodySmall.copyWith(color: AppColors.textSecondary),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: tournaments.length,
      itemBuilder: (_, i) {
        final t = tournaments[i];
        final registered = t['registered_count'] ?? 0;
        final maxP = t['max_participants'] ?? 0;
        return Container(
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.all(16),
          decoration: AppTheme.cardDecoration,
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(t['name'] ?? 'Unnamed', style: AppTypography.labelLarge, maxLines: 1, overflow: TextOverflow.ellipsis),
                    const SizedBox(height: 4),
                    Text('$registered / $maxP participants', style: AppTypography.caption),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.primaryBrand.withOpacity(0.1),
                  borderRadius: AppTheme.chipRadius,
                ),
                child: Text(
                  t['status']?.toUpperCase() ?? 'DRAFT',
                  style: AppTypography.labelSmall.copyWith(color: AppColors.primaryBrand),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/widgets/cream_scaffold.dart';
import '../../../shared/widgets/gold_button.dart';
import 'update_results_screen.dart';
import 'manage_participants_screen.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});
  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  int _tab = 0;
  static const String _tid = 'tournament_001';

  @override
  Widget build(BuildContext context) {
    return CreamScaffold(
      appBar: AppBar(
        title: Text('Admin', style: AppTypography.titleLarge),
        actions: [IconButton(icon: const Icon(Icons.logout_rounded), onPressed: () => context.go('/login'))],
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
      body: IndexedStack(
        index: _tab,
        children: [
          _DashboardTab(),
          _TournamentsTab(),
          UpdateResultsScreen(tournamentId: _tid),
          ManageParticipantsScreen(tournamentId: _tid),
        ],
      ),
    );
  }
}

class _DashboardTab extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('Overview', style: AppTypography.headlineSmall),
        const SizedBox(height: 16),
        GridView.count(
          crossAxisCount: 2, shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisSpacing: 12, mainAxisSpacing: 12, childAspectRatio: 1.4,
          children: const [
            _StatCard(label: 'Total Users', value: '1,284', icon: Icons.people_rounded),
            _StatCard(label: 'Active Tournaments', value: '3', icon: Icons.emoji_events_rounded),
            _StatCard(label: "Today's Participants", value: '248', icon: Icons.how_to_reg_rounded),
            _StatCard(label: "Tomorrow's Queue", value: '512', icon: Icons.schedule_rounded),
          ],
        ),
        const SizedBox(height: 24),
        Text('Revenue', style: AppTypography.headlineSmall),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(20),
          decoration: AppTheme.cardDecoration,
          child: Column(children: [
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              Text("Today's Revenue", style: AppTypography.bodyMedium),
              Text('₹12,400', style: AppTypography.headlineSmall.copyWith(color: AppColors.primaryBrand)),
            ]),
            const Divider(height: 20),
            _RRow('Pending refunds', '2', AppColors.error),
            const SizedBox(height: 8),
            _RRow('Total registrations', '82', AppColors.textPrimary),
          ]),
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
            _QA(icon: Icons.upload_outlined, label: 'Upload Photos', onTap: () {}),
            _QA(icon: Icons.rule_outlined, label: 'Update Rules', onTap: () {}),
            _QA(icon: Icons.live_tv_rounded, label: 'Go Live', onTap: () {}, accent: true),
          ],
        ),
      ]),
    );
  }
}

class _RRow extends StatelessWidget {
  final String l, v; final Color c;
  const _RRow(this.l, this.v, this.c);
  @override
  Widget build(BuildContext context) => Row(
    mainAxisAlignment: MainAxisAlignment.spaceBetween,
    children: [Text(l, style: AppTypography.bodySmall), Text(v, style: AppTypography.labelLarge.copyWith(color: c))],
  );
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
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(children: [
        GoldButton(label: '+ Create New Tournament', onPressed: () => context.go('/admin/tournament/create'), height: 46),
        const SizedBox(height: 16),
        Expanded(child: ListView.builder(
          itemCount: 3,
          itemBuilder: (_, i) => Container(
            margin: const EdgeInsets.only(bottom: 10),
            padding: const EdgeInsets.all(16),
            decoration: AppTheme.cardDecoration,
            child: Row(children: [
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('Tournament ${i+1}', style: AppTypography.labelLarge),
                Text(i == 0 ? 'Today · 3:00 PM' : i == 1 ? 'Tomorrow · 5:00 PM' : 'In 3 days', style: AppTypography.caption),
              ])),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(color: (i==0 ? AppColors.success : AppColors.primaryBrand).withOpacity(0.1), borderRadius: AppTheme.chipRadius),
                child: Text(i==0 ? 'Active' : 'Upcoming', style: AppTypography.labelSmall.copyWith(color: i==0 ? AppColors.success : AppColors.primaryBrand)),
              ),
              const SizedBox(width: 8),
              IconButton(icon: const Icon(Icons.edit_outlined, color: AppColors.primaryBrand, size: 20), onPressed: () => context.go('/admin/tournament/$i/edit')),
            ]),
          ),
        )),
      ]),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:tournament_app/core/theme/app_theme.dart';
import 'package:tournament_app/core/network/api_client.dart';
import 'package:tournament_app/core/storage/secure_storage.dart';
import 'package:tournament_app/features/auth/bloc/auth_bloc.dart';
import 'package:tournament_app/features/auth/data/auth_repository.dart';
import 'package:tournament_app/features/auth/presentation/login_screen.dart';
import 'package:tournament_app/features/home/bloc/home_bloc.dart';
import 'package:tournament_app/features/home/data/tournament_repository.dart';
import 'package:tournament_app/features/home/presentation/home_screen.dart';
import 'package:tournament_app/features/liveboard/bloc/liveboard_bloc.dart';
import 'package:tournament_app/features/liveboard/presentation/liveboard_screen.dart';
import 'package:tournament_app/features/tournament_detail/bloc/tournament_detail_bloc.dart';
import 'package:tournament_app/features/tournament_detail/presentation/tournament_detail_screen.dart';
import 'package:tournament_app/features/payment/bloc/payment_bloc.dart';
import 'package:tournament_app/features/payment/data/payment_repository.dart';
import 'package:tournament_app/features/payment/presentation/checkout_screen.dart';
import 'package:tournament_app/features/payment/presentation/payment_screens.dart';
import 'package:tournament_app/features/admin/presentation/admin_dashboard_screen.dart';
import 'package:tournament_app/features/admin/presentation/create_tournament_screen.dart';
import 'package:tournament_app/features/profile/presentation/profile_screen.dart';

final _api = ApiClient();
final _tournamentRepo = TournamentRepository(_api);
final _paymentRepo = PaymentRepository(_api);

final _router = GoRouter(
  initialLocation: '/login',
  redirect: (context, state) async {
    final hasSession = await SecureStorage.hasValidSession();
    final onLogin = state.matchedLocation == '/login';
    if (!hasSession && !onLogin) return '/login';
    if (hasSession && onLogin) {
      final role = await SecureStorage.getUserRole();
      return role == 'admin' ? '/admin' : '/home';
    }
    return null;
  },
  routes: [
    GoRoute(path: '/login', builder: (_, __) => const LoginScreen()),
    GoRoute(
      path: '/home',
      builder: (_, __) => BlocProvider(
        create: (_) => HomeBloc(_tournamentRepo)..add(HomeLoadRequested()),
        child: const HomeScreen(),
      ),
    ),
    GoRoute(path: '/profile', builder: (_, __) => const ProfileScreen()),
    GoRoute(
      path: '/tournament/:id',
      builder: (_, state) {
        final id = state.pathParameters['id']!;
        return BlocProvider(
          create: (_) => TournamentDetailBloc(_tournamentRepo),
          child: TournamentDetailScreen(tournamentId: id),
        );
      },
    ),
    GoRoute(
      path: '/tournament/:id/checkout',
      builder: (_, state) {
        final id = state.pathParameters['id']!;
        return BlocProvider(
          create: (_) => PaymentBloc(_paymentRepo),
          child: CheckoutScreen(tournamentId: id),
        );
      },
    ),
    GoRoute(path: '/payment/success', builder: (_, __) => const PaymentSuccessScreen()),
    GoRoute(path: '/payment/failure', builder: (_, __) => const PaymentFailureScreen()),
    GoRoute(
      path: '/liveboard/:id',
      builder: (_, state) {
        final id = state.pathParameters['id']!;
        return BlocProvider(
          create: (_) => LiveboardBloc(),
          child: LiveboardScreen(tournamentId: id),
        );
      },
    ),
    GoRoute(path: '/admin', builder: (_, __) => const AdminDashboardScreen()),
    GoRoute(path: '/admin/tournament/create', builder: (_, __) => const CreateTournamentScreen()),
    GoRoute(
      path: '/admin/tournament/:id/edit',
      builder: (_, state) => CreateTournamentScreen(tournamentId: state.pathParameters['id']),
    ),
    GoRoute(
      path: '/admin/live/:id',
      builder: (_, state) {
        final id = state.pathParameters['id']!;
        return BlocProvider(
          create: (_) => LiveboardBloc(),
          child: LiveboardScreen(tournamentId: id),
        );
      },
    ),
  ],
  errorBuilder: (_, state) => Scaffold(
    body: Center(child: Text('Not found: ${state.error}')),
  ),
);

class TournamentHubApp extends StatelessWidget {
  const TournamentHubApp({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => AuthBloc(AuthRepository(_api))..add(AuthCheckRequested()),
      child: MaterialApp.router(
        title: 'Tournament Hub',
        theme: AppTheme.lightTheme,
        routerConfig: _router,
        debugShowCheckedModeBanner: false,
      ),
    );
  }
}

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  GoogleFonts.config.allowRuntimeFetching = false;
  runApp(const TournamentHubApp());
}

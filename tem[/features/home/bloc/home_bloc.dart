import 'package:flutter_bloc/flutter_bloc.dart';
import '../data/tournament_repository.dart';
import '../data/models/tournament_model.dart';

// ── Events ────────────────────────────────────────────────
abstract class HomeEvent {}
class HomeLoadRequested extends HomeEvent {}
class HomeRefreshRequested extends HomeEvent {}

// ── States ────────────────────────────────────────────────
abstract class HomeState {}
class HomeInitial extends HomeState {}
class HomeLoading extends HomeState {}

class HomeLoaded extends HomeState {
  final List<TournamentModel> activeToday;
  final List<TournamentModel> upcoming;
  final List<TournamentModel> tomorrow;
  final List<ParticipationModel> history;
  HomeLoaded({
    required this.activeToday,
    required this.upcoming,
    required this.tomorrow,
    required this.history,
  });
}

class HomeError extends HomeState {
  final String message;
  HomeError(this.message);
}

// ── BLoC ──────────────────────────────────────────────────
class HomeBloc extends Bloc<HomeEvent, HomeState> {
  final TournamentRepository _repo;

  HomeBloc(this._repo) : super(HomeInitial()) {
    on<HomeLoadRequested>(_onLoad);
    on<HomeRefreshRequested>(_onLoad);
  }

  Future<void> _onLoad(HomeEvent event, Emitter<HomeState> emit) async {
    if (event is HomeLoadRequested) emit(HomeLoading());
    try {
      final results = await Future.wait([
        _repo.getTodayActive(),
        _repo.getUpcoming(),
        _repo.getTomorrow(),
        _repo.getUserHistory(),
      ]);
      emit(HomeLoaded(
        activeToday: results[0] as List<TournamentModel>,
        upcoming: results[1] as List<TournamentModel>,
        tomorrow: results[2] as List<TournamentModel>,
        history: results[3] as List<ParticipationModel>,
      ));
    } catch (e) {
      emit(HomeError(e.toString()));
    }
  }
}

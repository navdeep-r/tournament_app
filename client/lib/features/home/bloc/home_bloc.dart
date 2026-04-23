import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:tournament_app/features/home/data/tournament_repository.dart';
import 'package:tournament_app/features/home/data/models/tournament_model.dart';

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
  final List<TournamentModel> scheduled;
  final List<ParticipationModel> history;
  final Set<String> registeredTournamentIds;
  HomeLoaded({
    required this.activeToday,
    required this.scheduled,
    required this.history,
    required this.registeredTournamentIds,
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
        _repo.getScheduled(),
        _repo.getUserHistory(),
      ]);
      final history = results[2] as List<ParticipationModel>;
      emit(HomeLoaded(
        activeToday: results[0] as List<TournamentModel>,
        scheduled: results[1] as List<TournamentModel>,
        history: history,
        registeredTournamentIds: history.map((p) => p.tournamentId).toSet(),
      ));
    } catch (e) {
      emit(HomeError(e.toString()));
    }
  }
}

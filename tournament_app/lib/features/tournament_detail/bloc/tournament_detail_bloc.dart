import 'package:flutter_bloc/flutter_bloc.dart';
import '../../home/data/models/tournament_model.dart';
import '../../home/data/tournament_repository.dart';

// ── Events ────────────────────────────────────────────────
abstract class TournamentDetailEvent {}

class TournamentDetailLoadRequested extends TournamentDetailEvent {
  final String tournamentId;
  TournamentDetailLoadRequested(this.tournamentId);
}

class TournamentDetailRefreshRequested extends TournamentDetailEvent {
  final String tournamentId;
  TournamentDetailRefreshRequested(this.tournamentId);
}

// ── States ────────────────────────────────────────────────
abstract class TournamentDetailState {}

class TournamentDetailInitial extends TournamentDetailState {}

class TournamentDetailLoading extends TournamentDetailState {}

class TournamentDetailLoaded extends TournamentDetailState {
  final TournamentModel tournament;
  final bool isRegistered;
  TournamentDetailLoaded({required this.tournament, this.isRegistered = false});
}

class TournamentDetailError extends TournamentDetailState {
  final String message;
  TournamentDetailError(this.message);
}

// ── BLoC ──────────────────────────────────────────────────
class TournamentDetailBloc
    extends Bloc<TournamentDetailEvent, TournamentDetailState> {
  final TournamentRepository _repo;

  TournamentDetailBloc(this._repo) : super(TournamentDetailInitial()) {
    on<TournamentDetailLoadRequested>(_onLoad);
    on<TournamentDetailRefreshRequested>(_onRefresh);
  }

  Future<void> _onLoad(TournamentDetailLoadRequested event,
      Emitter<TournamentDetailState> emit) async {
    emit(TournamentDetailLoading());
    try {
      final tournament = await _repo.getById(event.tournamentId);
      emit(TournamentDetailLoaded(tournament: tournament));
    } catch (e) {
      emit(TournamentDetailError(e.toString()));
    }
  }

  Future<void> _onRefresh(TournamentDetailRefreshRequested event,
      Emitter<TournamentDetailState> emit) async {
    try {
      final tournament = await _repo.getById(event.tournamentId);
      emit(TournamentDetailLoaded(tournament: tournament));
    } catch (_) {
      // Keep existing state on refresh failure
    }
  }
}

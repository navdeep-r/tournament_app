import 'package:flutter_bloc/flutter_bloc.dart';
import '../data/admin_repository.dart';

// ── Events ─────────────────────────────────────────────────────────────────────
abstract class AdminEvent {}

class AdminDashboardLoadRequested extends AdminEvent {}

class AdminTournamentCreateRequested extends AdminEvent {
  final Map<String, dynamic> data;
  AdminTournamentCreateRequested(this.data);
}

class AdminTournamentUpdateRequested extends AdminEvent {
  final String id;
  final Map<String, dynamic> data;
  AdminTournamentUpdateRequested(this.id, this.data);
}

class AdminTournamentDeleteRequested extends AdminEvent {
  final String id;
  AdminTournamentDeleteRequested(this.id);
}

class AdminParticipantStatusUpdateRequested extends AdminEvent {
  final String participantId;
  final String newStatus; // 'advancing' | 'eliminated' | 'winner'
  AdminParticipantStatusUpdateRequested(this.participantId, this.newStatus);
}

class AdminRefundRequested extends AdminEvent {
  final String paymentId;
  AdminRefundRequested(this.paymentId);
}

class AdminCsvExportRequested extends AdminEvent {}

// ── States ─────────────────────────────────────────────────────────────────────
abstract class AdminState {}

class AdminInitial extends AdminState {}
class AdminLoading extends AdminState {}
class AdminOperationInProgress extends AdminState {
  final String operation;
  AdminOperationInProgress(this.operation);
}

class AdminDashboardLoaded extends AdminState {
  final Map<String, dynamic> stats;
  final List<dynamic> tournaments;
  AdminDashboardLoaded({required this.stats, required this.tournaments});
}

class AdminOperationSuccess extends AdminState {
  final String message;
  AdminOperationSuccess(this.message);
}

class AdminError extends AdminState {
  final String message;
  AdminError(this.message);
}

// ── BLoC ───────────────────────────────────────────────────────────────────────
class AdminBloc extends Bloc<AdminEvent, AdminState> {
  final AdminRepository _repo;

  AdminBloc(this._repo) : super(AdminInitial()) {
    on<AdminDashboardLoadRequested>(_onLoadDashboard);
    on<AdminTournamentCreateRequested>(_onCreateTournament);
    on<AdminTournamentUpdateRequested>(_onUpdateTournament);
    on<AdminTournamentDeleteRequested>(_onDeleteTournament);
    on<AdminParticipantStatusUpdateRequested>(_onUpdateParticipantStatus);
    on<AdminRefundRequested>(_onRefund);
    on<AdminCsvExportRequested>(_onExportCsv);
  }

  Future<void> _onLoadDashboard(
      AdminDashboardLoadRequested event, Emitter<AdminState> emit) async {
    emit(AdminLoading());
    try {
      final results = await Future.wait([
        _repo.getDashboardStats(),
        _repo.getTournaments(),
      ]);
      emit(AdminDashboardLoaded(
        stats: results[0] as Map<String, dynamic>,
        tournaments: results[1] as List<dynamic>,
      ));
    } catch (e) {
      emit(AdminError('Failed to load dashboard: $e'));
    }
  }

  Future<void> _onCreateTournament(
      AdminTournamentCreateRequested event, Emitter<AdminState> emit) async {
    emit(AdminOperationInProgress('Creating tournament...'));
    try {
      await _repo.createTournament(event.data);
      emit(AdminOperationSuccess('Tournament created successfully'));
      add(AdminDashboardLoadRequested()); // Refresh
    } catch (e) {
      emit(AdminError('Failed to create tournament: $e'));
    }
  }

  Future<void> _onUpdateTournament(
      AdminTournamentUpdateRequested event, Emitter<AdminState> emit) async {
    emit(AdminOperationInProgress('Saving changes...'));
    try {
      await _repo.updateTournament(event.id, event.data);
      emit(AdminOperationSuccess('Tournament updated successfully'));
      add(AdminDashboardLoadRequested());
    } catch (e) {
      emit(AdminError('Failed to update tournament: $e'));
    }
  }

  Future<void> _onDeleteTournament(
      AdminTournamentDeleteRequested event, Emitter<AdminState> emit) async {
    emit(AdminOperationInProgress('Deleting...'));
    try {
      await _repo.deleteTournament(event.id);
      emit(AdminOperationSuccess('Tournament deleted'));
      add(AdminDashboardLoadRequested());
    } catch (e) {
      emit(AdminError('Failed to delete tournament: $e'));
    }
  }

  Future<void> _onUpdateParticipantStatus(
      AdminParticipantStatusUpdateRequested event,
      Emitter<AdminState> emit) async {
    // Don't show full-screen loading — this is a quick inline action
    // The UI should update optimistically; if it fails, show a snackbar
    try {
      await _repo.updateParticipantStatus(event.participantId, event.newStatus);
      emit(AdminOperationSuccess(
          'Participant marked as ${event.newStatus}'));
    } catch (e) {
      emit(AdminError('Failed to update participant status'));
    }
  }

  Future<void> _onRefund(
      AdminRefundRequested event, Emitter<AdminState> emit) async {
    emit(AdminOperationInProgress('Processing refund...'));
    try {
      await _repo.issueRefund(event.paymentId);
      emit(AdminOperationSuccess(
          'Refund initiated. It will reflect in 3–5 working days.'));
    } catch (e) {
      emit(AdminError('Failed to issue refund: $e'));
    }
  }

  Future<void> _onExportCsv(
      AdminCsvExportRequested event, Emitter<AdminState> emit) async {
    emit(AdminOperationInProgress('Generating CSV...'));
    try {
      await _repo.exportParticipantsCSV();
      emit(AdminOperationSuccess('CSV exported successfully'));
    } catch (e) {
      emit(AdminError('Failed to export CSV: $e'));
    }
  }
}

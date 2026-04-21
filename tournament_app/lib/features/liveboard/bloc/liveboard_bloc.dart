import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import '../../../core/constants/api_constants.dart';
import '../../../core/storage/secure_storage.dart';
import '../data/liveboard_repository.dart';
import '../data/models/liveboard_models.dart';

abstract class LiveboardEvent {}

class LiveboardConnectRequested extends LiveboardEvent {
  final String tournamentId;
  LiveboardConnectRequested(this.tournamentId);
}

class LiveboardDisconnectRequested extends LiveboardEvent {}

class LiveboardParticipantUpdated extends LiveboardEvent {
  final String participantId;
  final ParticipantStatus newStatus;
  final int roundNumber;
  LiveboardParticipantUpdated(this.participantId, this.newStatus, this.roundNumber);
}

class LiveboardRoundChanged extends LiveboardEvent {
  final int roundNumber;
  LiveboardRoundChanged(this.roundNumber);
}

class _LiveboardWsMessage extends LiveboardEvent {
  final Map<String, dynamic> data;
  _LiveboardWsMessage(this.data);
}

class _LiveboardWsError extends LiveboardEvent {}

abstract class LiveboardState {}

class LiveboardInitial extends LiveboardState {}

class LiveboardConnecting extends LiveboardState {}

class LiveboardLoaded extends LiveboardState {
  final List<RoundModel> rounds;
  final int activeRoundIndex;
  final bool isLive;
  LiveboardLoaded({
    required this.rounds,
    required this.activeRoundIndex,
    required this.isLive,
  });

  LiveboardLoaded copyWith({List<RoundModel>? rounds, int? activeRoundIndex}) =>
      LiveboardLoaded(
        rounds: rounds ?? this.rounds,
        activeRoundIndex: activeRoundIndex ?? this.activeRoundIndex,
        isLive: isLive,
      );
}

class LiveboardError extends LiveboardState {
  final String message;
  LiveboardError(this.message);
}

class LiveboardBloc extends Bloc<LiveboardEvent, LiveboardState> {
  final LiveboardRepository _repo;
  WebSocketChannel? _channel;
  StreamSubscription? _sub;
  Timer? _reconnectTimer;
  int _reconnectAttempts = 0;
  String? _tournamentId;

  LiveboardBloc(this._repo) : super(LiveboardInitial()) {
    on<LiveboardConnectRequested>(_onConnect);
    on<LiveboardDisconnectRequested>(_onDisconnect);
    on<_LiveboardWsMessage>(_onMessage);
    on<_LiveboardWsError>(_onError);
    on<LiveboardParticipantUpdated>(_onParticipantUpdated);
    on<LiveboardRoundChanged>(_onRoundChanged);
  }

  Future<void> _onConnect(
      LiveboardConnectRequested event, Emitter<LiveboardState> emit) async {
    _tournamentId = event.tournamentId;
    emit(LiveboardConnecting());
    try {
      final rounds = await _repo.getRounds(event.tournamentId);
      final activeIndex = rounds.indexWhere((r) => r.status == 'active');
      emit(LiveboardLoaded(
        rounds: rounds,
        activeRoundIndex: activeIndex >= 0 ? activeIndex : 0,
        isLive: true,
      ));
    } catch (e) {
      emit(LiveboardError('Failed to load liveboard: $e'));
    }
    await _connect();
  }

  Future<void> _connect() async {
    if (_tournamentId == null) return;
    try {
      final token = await SecureStorage.getAccessToken();
      if (token == null || token.isEmpty) {
        add(_LiveboardWsError());
        return;
      }

      final uri = Uri.parse(ApiConstants.liveboardWs(_tournamentId!))
          .replace(queryParameters: {'token': token});
      _channel = WebSocketChannel.connect(uri);
      _reconnectAttempts = 0;
      _sub = _channel!.stream.listen(
        (data) {
          if (data is String) {
            try {
              final json = jsonDecode(data) as Map<String, dynamic>;
              add(_LiveboardWsMessage(json));
            } catch (_) {}
          }
        },
        onError: (_) => add(_LiveboardWsError()),
        onDone: () => _scheduleReconnect(),
      );
    } catch (_) {
      _scheduleReconnect();
    }
  }

  void _scheduleReconnect() {
    _reconnectAttempts++;
    final delay = Duration(
      seconds: min(30, (2 << _reconnectAttempts).clamp(1, 30)),
    );
    _reconnectTimer?.cancel();
    _reconnectTimer = Timer(delay, () {
      _connect();
    });
  }

  Future<void> _onDisconnect(
      LiveboardDisconnectRequested _, Emitter<LiveboardState> emit) async {
    _reconnectTimer?.cancel();
    await _sub?.cancel();
    await _channel?.sink.close();
  }

  void _onMessage(_LiveboardWsMessage event, Emitter<LiveboardState> emit) {
    if (state is! LiveboardLoaded) return;
    final loaded = state as LiveboardLoaded;
    final d = event.data;
    final type = (d['type'] as String? ?? '').toUpperCase();

    if (type == 'INITIAL_STATE') {
      final activeRoundNumber = loaded.rounds[loaded.activeRoundIndex].roundNumber;
      final incoming = (d['participants'] as List<dynamic>? ?? [])
          .map((p) => ParticipantModel.fromJson({
                ...(p as Map<String, dynamic>),
                'round_number': activeRoundNumber,
              }))
          .toList();

      final updatedRounds = loaded.rounds
          .map((r) => RoundModel(
                roundNumber: r.roundNumber,
                name: r.name,
                status: r.status,
                participants:
                    r.roundNumber == activeRoundNumber ? incoming : r.participants,
              ))
          .toList();
      emit(loaded.copyWith(rounds: updatedRounds));
      return;
    }

    if (type == 'PARTICIPANT_UPDATE' || type == 'PARTICIPANT_UPDATE'.toLowerCase()) {
      final participantId = d['participant_id'] as String?;
      final statusStr = d['status'] as String?;
      if (participantId == null || statusStr == null) return;

      final newStatus = switch (statusStr) {
        'eliminated' => ParticipantStatus.eliminated,
        'advancing' || 'advanced' => ParticipantStatus.advancing,
        'winner' => ParticipantStatus.winner,
        _ => ParticipantStatus.active,
      };

      final updatedRounds = loaded.rounds.map((round) {
        final updated = round.participants.map((p) {
          if (p.id != participantId) return p;
          return p.copyWith(status: newStatus);
        }).toList();
        return RoundModel(
          roundNumber: round.roundNumber,
          name: round.name,
          status: round.status,
          participants: updated,
        );
      }).toList();
      emit(loaded.copyWith(rounds: updatedRounds));
      return;
    }

    if (type == 'ROUND_STARTED') {
      final roundNumber = d['round_number'] as int?;
      if (roundNumber == null) return;
      final index = loaded.rounds.indexWhere((r) => r.roundNumber == roundNumber);
      if (index >= 0) {
        emit(loaded.copyWith(activeRoundIndex: index));
      }
    }
  }

  void _onError(_LiveboardWsError _, Emitter<LiveboardState> emit) {
    if (state is! LiveboardLoaded) {
      emit(LiveboardError('Connection failed. Reconnecting...'));
    }
    _scheduleReconnect();
  }

  void _onParticipantUpdated(
      LiveboardParticipantUpdated event, Emitter<LiveboardState> emit) {
    if (state is LiveboardLoaded) {
      add(_LiveboardWsMessage({
        'type': 'PARTICIPANT_UPDATE',
        'participant_id': event.participantId,
        'status': event.newStatus.name,
        'round': event.roundNumber,
      }));
    }
  }

  void _onRoundChanged(LiveboardRoundChanged event, Emitter<LiveboardState> emit) {
    if (state is LiveboardLoaded) {
      final loaded = state as LiveboardLoaded;
      emit(loaded.copyWith(activeRoundIndex: event.roundNumber));
    }
  }

  @override
  Future<void> close() async {
    _reconnectTimer?.cancel();
    await _sub?.cancel();
    await _channel?.sink.close();
    return super.close();
  }
}

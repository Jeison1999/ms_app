import 'package:flutter_bloc/flutter_bloc.dart';
import '../attendance_repository.dart';
import '../models/attendance_event.dart';

abstract class AttendanceEventEvent {}

class LoadAttendanceEvents extends AttendanceEventEvent {
  final int? groupId;
  final int? year;
  final int? month;
  final String? eventType;
  final String? status;

  LoadAttendanceEvents({
    this.groupId,
    this.year,
    this.month,
    this.eventType,
    this.status,
  });
}

class LoadAttendanceEventDetail extends AttendanceEventEvent {
  final int id;
  LoadAttendanceEventDetail(this.id);
}

class CreateAttendanceEvent extends AttendanceEventEvent {
  final Map<String, dynamic> event;
  final List<int> personIds;
  CreateAttendanceEvent({required this.event, this.personIds = const []});
}

class UpdateAttendanceRecords extends AttendanceEventEvent {
  final int id;
  final List<AttendanceRecord> records;
  UpdateAttendanceRecords(this.id, this.records);
}

class CloseAttendanceEvent extends AttendanceEventEvent {
  final int id;
  CloseAttendanceEvent(this.id);
}

class DeleteAttendanceEvent extends AttendanceEventEvent {
  final int id;
  DeleteAttendanceEvent(this.id);
}

abstract class AttendanceEventState {}

class AttendanceEventInitial extends AttendanceEventState {}

class AttendanceEventLoading extends AttendanceEventState {}

class AttendanceEventsLoaded extends AttendanceEventState {
  final List<AttendanceEvent> events;
  AttendanceEventsLoaded(this.events);
}

class AttendanceEventDetailLoaded extends AttendanceEventState {
  final AttendanceEvent event;
  AttendanceEventDetailLoaded(this.event);
}

class AttendanceEventSuccess extends AttendanceEventState {
  final String message;
  final AttendanceEvent? event;
  AttendanceEventSuccess(this.message, {this.event});
}

class AttendanceEventError extends AttendanceEventState {
  final String message;
  AttendanceEventError(this.message);
}

class AttendanceEventBloc
    extends Bloc<AttendanceEventEvent, AttendanceEventState> {
  final AttendanceRepository repository;
  LoadAttendanceEvents? _lastListQuery;

  AttendanceEventBloc(this.repository) : super(AttendanceEventInitial()) {
    on<LoadAttendanceEvents>((event, emit) async {
      emit(AttendanceEventLoading());
      try {
        _lastListQuery = event;
        final events = await repository.getEvents(
          groupId: event.groupId,
          year: event.year,
          month: event.month,
          eventType: event.eventType,
          status: event.status,
        );
        emit(AttendanceEventsLoaded(events));
      } catch (e) {
        emit(AttendanceEventError(e.toString()));
      }
    });

    on<LoadAttendanceEventDetail>((event, emit) async {
      emit(AttendanceEventLoading());
      try {
        final detail = await repository.getEvent(event.id);
        emit(AttendanceEventDetailLoaded(detail));
      } catch (e) {
        emit(AttendanceEventError(e.toString()));
      }
    });

    on<CreateAttendanceEvent>((event, emit) async {
      emit(AttendanceEventLoading());
      try {
        final created = await repository.createEvent(
          event: event.event,
          personIds: event.personIds,
        );
        emit(AttendanceEventSuccess('Evento creado', event: created));
        await _reloadList(emit);
      } catch (e) {
        emit(AttendanceEventError(e.toString()));
      }
    });

    on<UpdateAttendanceRecords>((event, emit) async {
      emit(AttendanceEventLoading());
      try {
        final updated = await repository.updateRecords(event.id, event.records);
        emit(AttendanceEventSuccess('Asistencia guardada', event: updated));
        emit(AttendanceEventDetailLoaded(updated));
      } catch (e) {
        emit(AttendanceEventError(e.toString()));
      }
    });

    on<CloseAttendanceEvent>((event, emit) async {
      emit(AttendanceEventLoading());
      try {
        final closed = await repository.closeEvent(event.id);
        emit(AttendanceEventSuccess('Evento cerrado', event: closed));
        emit(AttendanceEventDetailLoaded(closed));
      } catch (e) {
        emit(AttendanceEventError(e.toString()));
      }
    });

    on<DeleteAttendanceEvent>((event, emit) async {
      emit(AttendanceEventLoading());
      try {
        await repository.deleteEvent(event.id);
        emit(AttendanceEventSuccess('Evento eliminado'));
        await _reloadList(emit);
      } catch (e) {
        emit(AttendanceEventError(e.toString()));
      }
    });
  }

  Future<void> _reloadList(Emitter<AttendanceEventState> emit) async {
    final q = _lastListQuery ?? LoadAttendanceEvents();
    final events = await repository.getEvents(
      groupId: q.groupId,
      year: q.year,
      month: q.month,
      eventType: q.eventType,
      status: q.status,
    );
    emit(AttendanceEventsLoaded(events));
  }
}

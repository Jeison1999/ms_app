import 'package:flutter_bloc/flutter_bloc.dart';
import 'models/event_model.dart';
import 'event_repository.dart';


abstract class EventEvent {}
class LoadAllEvents extends EventEvent {}
class LoadUpcomingEvents extends EventEvent {}
class LoadPastEvents extends EventEvent {}
class LoadEventDetail extends EventEvent {
  final int id;
  LoadEventDetail(this.id);
}
class CreateEvent extends EventEvent {
  final Map<String, dynamic> eventData;
  CreateEvent(this.eventData);
}
class UpdateEvent extends EventEvent {
  final int id;
  final Map<String, dynamic> eventData;
  UpdateEvent(this.id, this.eventData);
}
class DeleteEvent extends EventEvent {
  final int id;
  DeleteEvent(this.id);
}


abstract class EventState {}
class EventInitial extends EventState {}
class EventLoading extends EventState {}
class EventAllLoaded extends EventState {
  final List<EventModel> upcoming;
  final List<EventModel> past;
  EventAllLoaded({required this.upcoming, required this.past});
}
class EventUpcomingLoaded extends EventState {
  final List<EventModel> events;
  EventUpcomingLoaded(this.events);
}
class EventPastLoaded extends EventState {
  final List<EventModel> events;
  EventPastLoaded(this.events);
}
class EventDetailLoaded extends EventState {
  final EventModel event;
  EventDetailLoaded(this.event);
}
class EventSuccess extends EventState {
  final String message;
  EventSuccess(this.message);
}
class EventError extends EventState {
  final String message;
  EventError(this.message);
}

class EventBloc extends Bloc<EventEvent, EventState> {
  final EventRepository repository;
  EventBloc(this.repository) : super(EventInitial()) {
    on<LoadAllEvents>((event, emit) async {
      emit(EventLoading());
      try {
        final result = await repository.getAllEvents();
        emit(EventAllLoaded(upcoming: result['upcoming']!, past: result['past']!));
      } catch (e) {
        emit(EventError(e.toString()));
      }
    });
    on<LoadUpcomingEvents>((event, emit) async {
      emit(EventLoading());
      try {
        final events = await repository.getUpcomingEvents();
        emit(EventUpcomingLoaded(events));
      } catch (e) {
        emit(EventError(e.toString()));
      }
    });
    on<LoadPastEvents>((event, emit) async {
      emit(EventLoading());
      try {
        final events = await repository.getRecentPastEvents();
        emit(EventPastLoaded(events));
      } catch (e) {
        emit(EventError(e.toString()));
      }
    });
    on<LoadEventDetail>((event, emit) async {
      emit(EventLoading());
      try {
        final eventDetail = await repository.getEvent(event.id);
        emit(EventDetailLoaded(eventDetail));
      } catch (e) {
        emit(EventError(e.toString()));
      }
    });
    on<CreateEvent>((event, emit) async {
      emit(EventLoading());
      try {
        await repository.createEvent(event.eventData);
        emit(EventSuccess('Evento creado correctamente'));
      } catch (e) {
        emit(EventError(e.toString()));
      }
    });
    on<UpdateEvent>((event, emit) async {
      emit(EventLoading());
      try {
        await repository.updateEvent(event.id, event.eventData);
        emit(EventSuccess('Evento actualizado correctamente'));
      } catch (e) {
        emit(EventError(e.toString()));
      }
    });
    on<DeleteEvent>((event, emit) async {
      emit(EventLoading());
      try {
        await repository.deleteEvent(event.id);
        emit(EventSuccess('Evento eliminado correctamente'));
      } catch (e) {
        emit(EventError(e.toString()));
      }
    });
  }
}

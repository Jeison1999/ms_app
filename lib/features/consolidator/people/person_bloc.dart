import 'package:flutter_bloc/flutter_bloc.dart';
import 'models/person_model.dart';
import 'person_repository.dart';

// ============= Events =============
abstract class PersonEvent {}

class LoadPeople extends PersonEvent {
  final String? q;
  final String? status;

  LoadPeople({this.q, this.status});
}

class LoadPersonDetail extends PersonEvent {
  final int id;
  LoadPersonDetail(this.id);
}

class CreatePerson extends PersonEvent {
  final Map<String, dynamic> personData;
  CreatePerson(this.personData);
}

class UpdatePerson extends PersonEvent {
  final int id;
  final Map<String, dynamic> personData;
  UpdatePerson(this.id, this.personData);
}

class DeactivatePerson extends PersonEvent {
  final int id;
  DeactivatePerson(this.id);
}

class ReactivatePerson extends PersonEvent {
  final int id;
  ReactivatePerson(this.id);
}

// ============= States =============
abstract class PersonState {}

class PersonInitial extends PersonState {}

class PersonLoading extends PersonState {}

class PeopleLoaded extends PersonState {
  final List<PersonModel> people;
  final int total;
  final String? q;
  final String? status;

  PeopleLoaded({
    required this.people,
    required this.total,
    this.q,
    this.status,
  });
}

class PersonDetailLoaded extends PersonState {
  final PersonModel person;
  PersonDetailLoaded(this.person);
}

class PersonSuccess extends PersonState {
  final String message;
  PersonSuccess(this.message);
}

class PersonError extends PersonState {
  final String message;
  PersonError(this.message);
}

// ============= BLoC =============
class PersonBloc extends Bloc<PersonEvent, PersonState> {
  final PersonRepository repository;

  PersonBloc(this.repository) : super(PersonInitial()) {
    on<LoadPeople>((event, emit) async {
      emit(PersonLoading());
      try {
        final result = await repository.getPeople(
          q: event.q,
          status: event.status,
        );
        emit(
          PeopleLoaded(
            people: result.people,
            total: result.total,
            q: result.q ?? event.q,
            status: result.status ?? event.status,
          ),
        );
      } catch (e) {
        emit(PersonError(e.toString()));
      }
    });

    on<LoadPersonDetail>((event, emit) async {
      emit(PersonLoading());
      try {
        final person = await repository.getPerson(event.id);
        emit(PersonDetailLoaded(person));
      } catch (e) {
        emit(PersonError(e.toString()));
      }
    });

    on<CreatePerson>((event, emit) async {
      emit(PersonLoading());
      try {
        await repository.createPerson(event.personData);
        emit(PersonSuccess('Persona creada exitosamente'));
      } catch (e) {
        emit(PersonError(e.toString()));
      }
    });

    on<UpdatePerson>((event, emit) async {
      emit(PersonLoading());
      try {
        await repository.updatePerson(event.id, event.personData);
        emit(PersonSuccess('Persona actualizada exitosamente'));
      } catch (e) {
        emit(PersonError(e.toString()));
      }
    });

    on<DeactivatePerson>((event, emit) async {
      emit(PersonLoading());
      try {
        await repository.deactivatePerson(event.id);
        emit(PersonSuccess('Persona desactivada'));
      } catch (e) {
        emit(PersonError(e.toString()));
      }
    });

    on<ReactivatePerson>((event, emit) async {
      emit(PersonLoading());
      try {
        await repository.reactivatePerson(event.id);
        emit(PersonSuccess('Persona reactivada'));
      } catch (e) {
        emit(PersonError(e.toString()));
      }
    });
  }
}

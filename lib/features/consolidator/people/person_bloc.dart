import 'package:flutter_bloc/flutter_bloc.dart';
import 'models/person_filters.dart';
import 'models/person_model.dart';
import 'person_repository.dart';

// ============= Events =============
abstract class PersonEvent {}

class LoadPeople extends PersonEvent {
  final PersonFilters filters;
  LoadPeople({PersonFilters? filters}) : filters = filters ?? PersonFilters();
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

class LoadBirthdaysToday extends PersonEvent {}

class LoadBirthdaysMonth extends PersonEvent {
  final int? month;
  LoadBirthdaysMonth({this.month});
}

// ============= States =============
abstract class PersonState {}

class PersonInitial extends PersonState {}

class PersonLoading extends PersonState {}

class PeopleLoaded extends PersonState {
  final List<PersonModel> people;
  final int total;
  final PersonFilters filters;

  PeopleLoaded({
    required this.people,
    required this.total,
    required this.filters,
  });
}

class BirthdaysLoaded extends PersonState {
  final List<PersonModel> people;
  final int total;
  final String mode; // today | month
  final String? date;
  final int? month;
  final int? year;
  final int? todayCount;

  BirthdaysLoaded({
    required this.people,
    required this.total,
    required this.mode,
    this.date,
    this.month,
    this.year,
    this.todayCount,
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
  PersonFilters currentFilters = PersonFilters();

  PersonBloc(this.repository) : super(PersonInitial()) {
    on<LoadPeople>((event, emit) async {
      emit(PersonLoading());
      try {
        currentFilters = event.filters;
        final result = await repository.getPeople(filters: event.filters);
        emit(
          PeopleLoaded(
            people: result.people,
            total: result.total,
            filters: event.filters,
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

    on<LoadBirthdaysToday>((event, emit) async {
      emit(PersonLoading());
      try {
        final result = await repository.getBirthdaysToday();
        emit(
          BirthdaysLoaded(
            people: result.people,
            total: result.total,
            mode: 'today',
            date: result.date,
          ),
        );
      } catch (e) {
        emit(PersonError(e.toString()));
      }
    });

    on<LoadBirthdaysMonth>((event, emit) async {
      emit(PersonLoading());
      try {
        final result = await repository.getBirthdaysMonth(month: event.month);
        emit(
          BirthdaysLoaded(
            people: result.people,
            total: result.total,
            mode: 'month',
            month: result.month ?? event.month,
            year: result.year,
            todayCount: result.todayCount,
          ),
        );
      } catch (e) {
        emit(PersonError(e.toString()));
      }
    });
  }
}

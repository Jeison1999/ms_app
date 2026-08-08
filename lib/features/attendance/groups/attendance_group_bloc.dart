import 'package:flutter_bloc/flutter_bloc.dart';
import '../attendance_repository.dart';
import '../models/attendance_group.dart';

abstract class AttendanceGroupEvent {}

class LoadAttendanceGroups extends AttendanceGroupEvent {
  final bool? active;
  LoadAttendanceGroups({this.active = true});
}

class LoadAttendanceGroupDetail extends AttendanceGroupEvent {
  final int id;
  LoadAttendanceGroupDetail(this.id);
}

class CreateAttendanceGroup extends AttendanceGroupEvent {
  final Map<String, dynamic> group;
  final List<int> personIds;
  CreateAttendanceGroup({required this.group, this.personIds = const []});
}

class UpdateAttendanceGroup extends AttendanceGroupEvent {
  final int id;
  final Map<String, dynamic> group;
  UpdateAttendanceGroup(this.id, this.group);
}

class DeactivateAttendanceGroup extends AttendanceGroupEvent {
  final int id;
  DeactivateAttendanceGroup(this.id);
}

class AddGroupMembers extends AttendanceGroupEvent {
  final int id;
  final List<int> personIds;
  AddGroupMembers(this.id, this.personIds);
}

class RemoveGroupMembers extends AttendanceGroupEvent {
  final int id;
  final List<int> personIds;
  RemoveGroupMembers(this.id, this.personIds);
}

abstract class AttendanceGroupState {}

class AttendanceGroupInitial extends AttendanceGroupState {}

class AttendanceGroupLoading extends AttendanceGroupState {}

class AttendanceGroupsLoaded extends AttendanceGroupState {
  final List<AttendanceGroup> groups;
  AttendanceGroupsLoaded(this.groups);
}

class AttendanceGroupDetailLoaded extends AttendanceGroupState {
  final AttendanceGroup group;
  AttendanceGroupDetailLoaded(this.group);
}

class AttendanceGroupSuccess extends AttendanceGroupState {
  final String message;
  AttendanceGroupSuccess(this.message);
}

class AttendanceGroupError extends AttendanceGroupState {
  final String message;
  AttendanceGroupError(this.message);
}

class AttendanceGroupBloc
    extends Bloc<AttendanceGroupEvent, AttendanceGroupState> {
  final AttendanceRepository repository;
  bool? _lastActive = true;

  AttendanceGroupBloc(this.repository) : super(AttendanceGroupInitial()) {
    on<LoadAttendanceGroups>((event, emit) async {
      emit(AttendanceGroupLoading());
      try {
        _lastActive = event.active;
        final groups = await repository.getGroups(active: event.active);
        emit(AttendanceGroupsLoaded(groups));
      } catch (e) {
        emit(AttendanceGroupError(e.toString()));
      }
    });

    on<LoadAttendanceGroupDetail>((event, emit) async {
      emit(AttendanceGroupLoading());
      try {
        final group = await repository.getGroup(event.id);
        emit(AttendanceGroupDetailLoaded(group));
      } catch (e) {
        emit(AttendanceGroupError(e.toString()));
      }
    });

    on<CreateAttendanceGroup>((event, emit) async {
      emit(AttendanceGroupLoading());
      try {
        await repository.createGroup(
          group: event.group,
          personIds: event.personIds,
        );
        emit(AttendanceGroupSuccess('Grupo creado'));
        final groups = await repository.getGroups(active: _lastActive);
        emit(AttendanceGroupsLoaded(groups));
      } catch (e) {
        emit(AttendanceGroupError(e.toString()));
      }
    });

    on<UpdateAttendanceGroup>((event, emit) async {
      emit(AttendanceGroupLoading());
      try {
        await repository.updateGroup(event.id, event.group);
        emit(AttendanceGroupSuccess('Grupo actualizado'));
        final group = await repository.getGroup(event.id);
        emit(AttendanceGroupDetailLoaded(group));
      } catch (e) {
        emit(AttendanceGroupError(e.toString()));
      }
    });

    on<DeactivateAttendanceGroup>((event, emit) async {
      emit(AttendanceGroupLoading());
      try {
        await repository.deactivateGroup(event.id);
        emit(AttendanceGroupSuccess('Grupo desactivado'));
        final groups = await repository.getGroups(active: _lastActive);
        emit(AttendanceGroupsLoaded(groups));
      } catch (e) {
        emit(AttendanceGroupError(e.toString()));
      }
    });

    on<AddGroupMembers>((event, emit) async {
      emit(AttendanceGroupLoading());
      try {
        final group = await repository.addMembers(event.id, event.personIds);
        emit(AttendanceGroupSuccess('Miembros agregados'));
        emit(AttendanceGroupDetailLoaded(group));
      } catch (e) {
        emit(AttendanceGroupError(e.toString()));
      }
    });

    on<RemoveGroupMembers>((event, emit) async {
      emit(AttendanceGroupLoading());
      try {
        final group = await repository.removeMembers(event.id, event.personIds);
        emit(AttendanceGroupSuccess('Miembros removidos'));
        emit(AttendanceGroupDetailLoaded(group));
      } catch (e) {
        emit(AttendanceGroupError(e.toString()));
      }
    });
  }
}

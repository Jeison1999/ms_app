import 'package:flutter_bloc/flutter_bloc.dart';
import 'custom_field_repository.dart';
import 'models/custom_field_model.dart';

// ============= Events =============
abstract class CustomFieldEvent {}

class LoadCustomFields extends CustomFieldEvent {
  final bool? active;
  LoadCustomFields({this.active});
}

class CreateCustomField extends CustomFieldEvent {
  final Map<String, dynamic> fieldData;
  CreateCustomField(this.fieldData);
}

class UpdateCustomField extends CustomFieldEvent {
  final int id;
  final Map<String, dynamic> fieldData;
  UpdateCustomField(this.id, this.fieldData);
}

class DeactivateCustomField extends CustomFieldEvent {
  final int id;
  DeactivateCustomField(this.id);
}

class ReactivateCustomField extends CustomFieldEvent {
  final int id;
  ReactivateCustomField(this.id);
}

class PurgeCustomField extends CustomFieldEvent {
  final int id;
  final bool force;
  PurgeCustomField(this.id, {this.force = false});
}

// ============= States =============
abstract class CustomFieldState {}

class CustomFieldInitial extends CustomFieldState {}

class CustomFieldLoading extends CustomFieldState {}

class CustomFieldsLoaded extends CustomFieldState {
  final List<CustomFieldModel> fields;
  CustomFieldsLoaded(this.fields);
}

class CustomFieldSuccess extends CustomFieldState {
  final String message;
  CustomFieldSuccess(this.message);
}

class CustomFieldError extends CustomFieldState {
  final String message;
  CustomFieldError(this.message);
}

// ============= BLoC =============
class CustomFieldBloc extends Bloc<CustomFieldEvent, CustomFieldState> {
  final CustomFieldRepository repository;
  bool? _lastActiveFilter = true;

  CustomFieldBloc(this.repository) : super(CustomFieldInitial()) {
    on<LoadCustomFields>((event, emit) async {
      emit(CustomFieldLoading());
      try {
        _lastActiveFilter = event.active;
        final fields = await repository.getCustomFields(active: event.active);
        emit(CustomFieldsLoaded(fields));
      } catch (e) {
        emit(CustomFieldError(e.toString()));
      }
    });

    on<CreateCustomField>((event, emit) async {
      emit(CustomFieldLoading());
      try {
        final result = await repository.createCustomField(event.fieldData);
        var message = 'Campo creado exitosamente';
        if (result.portalEnabled &&
            result.portalAutoEnabledReason != null &&
            result.portalAutoEnabledReason!.isNotEmpty) {
          message =
              'Campo creado. Portal web auto-activado: ${result.portalAutoEnabledReason}';
        } else if (result.field.includeInPublicForm && result.portalEnabled) {
          message = 'Campo creado e incluido en el formulario web';
        }
        emit(CustomFieldSuccess(message));
        final fields = await repository.getCustomFields(
          active: _lastActiveFilter,
        );
        emit(CustomFieldsLoaded(fields));
      } catch (e) {
        emit(CustomFieldError(e.toString()));
      }
    });

    on<UpdateCustomField>((event, emit) async {
      emit(CustomFieldLoading());
      try {
        final result = await repository.updateCustomField(
          event.id,
          event.fieldData,
        );
        var message = 'Campo actualizado exitosamente';
        if (result.portalEnabled &&
            result.portalAutoEnabledReason != null &&
            result.portalAutoEnabledReason!.isNotEmpty) {
          message =
              'Campo actualizado. Portal web auto-activado: ${result.portalAutoEnabledReason}';
        }
        emit(CustomFieldSuccess(message));
        final fields = await repository.getCustomFields(
          active: _lastActiveFilter,
        );
        emit(CustomFieldsLoaded(fields));
      } catch (e) {
        emit(CustomFieldError(e.toString()));
      }
    });

    on<DeactivateCustomField>((event, emit) async {
      emit(CustomFieldLoading());
      try {
        await repository.deactivateCustomField(event.id);
        emit(CustomFieldSuccess('Campo desactivado'));
        final fields = await repository.getCustomFields(
          active: _lastActiveFilter,
        );
        emit(CustomFieldsLoaded(fields));
      } catch (e) {
        emit(CustomFieldError(e.toString()));
      }
    });

    on<ReactivateCustomField>((event, emit) async {
      emit(CustomFieldLoading());
      try {
        await repository.reactivateCustomField(event.id);
        emit(CustomFieldSuccess('Campo reactivado'));
        final fields = await repository.getCustomFields(
          active: _lastActiveFilter,
        );
        emit(CustomFieldsLoaded(fields));
      } catch (e) {
        emit(CustomFieldError(e.toString()));
      }
    });

    on<PurgeCustomField>((event, emit) async {
      emit(CustomFieldLoading());
      try {
        final result = await repository.purgeCustomField(
          event.id,
          force: event.force,
        );
        var message = result.message;
        if (result.deletedValuesCount > 0) {
          message =
              '${result.message} (${result.deletedValuesCount} valor(es) borrados)';
        }
        emit(CustomFieldSuccess(message));
        final fields = await repository.getCustomFields(
          active: _lastActiveFilter,
        );
        emit(CustomFieldsLoaded(fields));
      } catch (e) {
        emit(CustomFieldError(e.toString()));
      }
    });
  }
}

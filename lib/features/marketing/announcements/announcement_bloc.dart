import 'package:flutter_bloc/flutter_bloc.dart';
import 'index_announcement.dart';


// ============= Events =============
abstract class AnnouncementEvent {}

class LoadAllAnnouncements extends AnnouncementEvent {}

class LoadActiveAnnouncements extends AnnouncementEvent {}

class LoadAnnouncementDetail extends AnnouncementEvent {
  final int id;
  LoadAnnouncementDetail(this.id);
}

class CreateAnnouncement extends AnnouncementEvent {
  final Map<String, dynamic> announcementData;
  CreateAnnouncement(this.announcementData);
}

class UpdateAnnouncement extends AnnouncementEvent {
  final int id;
  final Map<String, dynamic> announcementData;
  UpdateAnnouncement(this.id, this.announcementData);
}

class DeleteAnnouncement extends AnnouncementEvent {
  final int id;
  DeleteAnnouncement(this.id);
}

// ============= States =============
abstract class AnnouncementState {}

class AnnouncementInitial extends AnnouncementState {}

class AnnouncementLoading extends AnnouncementState {}

class AnnouncementAllLoaded extends AnnouncementState {
  final List<AnnouncementModel> announcements;
  AnnouncementAllLoaded(this.announcements);
}

class AnnouncementActiveLoaded extends AnnouncementState {
  final List<AnnouncementModel> announcements;
  AnnouncementActiveLoaded(this.announcements);
}

class AnnouncementDetailLoaded extends AnnouncementState {
  final AnnouncementModel announcement;
  AnnouncementDetailLoaded(this.announcement);
}

class AnnouncementSuccess extends AnnouncementState {
  final String message;
  AnnouncementSuccess(this.message);
}

class AnnouncementError extends AnnouncementState {
  final String message;
  AnnouncementError(this.message);
}

// ============= BLoC =============
class AnnouncementBloc extends Bloc<AnnouncementEvent, AnnouncementState> {
  final AnnouncementRepository repository;
  AnnouncementBloc(this.repository) : super(AnnouncementInitial()) {
    on<LoadAllAnnouncements>((event, emit) async {
      emit(AnnouncementLoading());
      try {
        final announcements = await repository.getAllAnnouncements();
        emit(AnnouncementAllLoaded(announcements));
      } catch (e) {
        emit(AnnouncementError(e.toString()));
      }
    });

    on<LoadActiveAnnouncements>((event, emit) async {
      emit(AnnouncementLoading());
      try {
        final announcements = await repository.getActiveAnnouncements();
        emit(AnnouncementActiveLoaded(announcements));
      } catch (e) {
        emit(AnnouncementError(e.toString()));
      }
    });

    on<LoadAnnouncementDetail>((event, emit) async {
      emit(AnnouncementLoading());
      try {
        final announcement = await repository.getAnnouncement(event.id);
        emit(AnnouncementDetailLoaded(announcement));
      } catch (e) {
        emit(AnnouncementError(e.toString()));
      }
    });

    on<CreateAnnouncement>((event, emit) async {
      emit(AnnouncementLoading());
      try {
        await repository.createAnnouncement(event.announcementData);
        emit(AnnouncementSuccess('Anuncio creado exitosamente'));
        // Recargar lista después de crear
        final announcements = await repository.getAllAnnouncements();
        emit(AnnouncementAllLoaded(announcements));
      } catch (e) {
        emit(AnnouncementError(e.toString()));
      }
    });

    on<UpdateAnnouncement>((event, emit) async {
      emit(AnnouncementLoading());
      try {
        await repository.updateAnnouncement(event.id, event.announcementData);
        emit(AnnouncementSuccess('Anuncio actualizado exitosamente'));
        // Recargar detalle después de actualizar
        final announcement = await repository.getAnnouncement(event.id);
        emit(AnnouncementDetailLoaded(announcement));
      } catch (e) {
        emit(AnnouncementError(e.toString()));
      }
    });

    on<DeleteAnnouncement>((event, emit) async {
      emit(AnnouncementLoading());
      try {
        await repository.deleteAnnouncement(event.id);
        emit(AnnouncementSuccess('Anuncio eliminado exitosamente'));
        // Recargar lista después de eliminar
        final announcements = await repository.getAllAnnouncements();
        emit(AnnouncementAllLoaded(announcements));
      } catch (e) {
        emit(AnnouncementError(e.toString()));
      }
    });
  }
}

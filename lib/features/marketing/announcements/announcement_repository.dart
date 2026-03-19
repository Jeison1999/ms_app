import '../../../core/api/api_client.dart';
import '../../../core/api/api_endpoints.dart';
import 'index_announcement.dart';

class AnnouncementRepository {
  final ApiClient apiClient;

  AnnouncementRepository({required this.apiClient});

  // GET /api/v1/content/announcements (todos los anuncios)
  Future<List<AnnouncementModel>> getAllAnnouncements() async {
    final response = await apiClient.get(ApiEndpoints.announcements);
    final data = response.data;
    return (data['announcements'] as List)
        .map((a) => AnnouncementModel.fromJson(a as Map<String, dynamic>))
        .toList();
  }

  // GET /api/v1/content/announcements/active (solo activos y publicados)
  Future<List<AnnouncementModel>> getActiveAnnouncements() async {
    final response = await apiClient.get(ApiEndpoints.activeAnnouncements);
    final data = response.data;
    return (data['announcements'] as List)
        .map((a) => AnnouncementModel.fromJson(a as Map<String, dynamic>))
        .toList();
  }

  // GET /api/v1/content/announcements/:id
  Future<AnnouncementModel> getAnnouncement(int id) async {
    final response = await apiClient.get(ApiEndpoints.announcementById(id));
    final data = response.data['announcement'] as Map<String, dynamic>;
    return AnnouncementModel.fromJson(data);
  }

  // POST /api/v1/content/announcements (crear nuevo anuncio)
  Future<AnnouncementModel> createAnnouncement(
    Map<String, dynamic> announcementData,
  ) async {
    final response = await apiClient.post(
      ApiEndpoints.announcements,
      data: {'announcement': announcementData},
    );
    final data = response.data['announcement'] as Map<String, dynamic>;
    return AnnouncementModel.fromJson(data);
  }

  // PUT /api/v1/content/announcements/:id (actualizar anuncio)
  Future<AnnouncementModel> updateAnnouncement(
    int id,
    Map<String, dynamic> announcementData,
  ) async {
    final response = await apiClient.put(
      ApiEndpoints.announcementById(id),
      data: {'announcement': announcementData},
    );
    final data = response.data['announcement'] as Map<String, dynamic>;
    return AnnouncementModel.fromJson(data);
  }

  // DELETE /api/v1/content/announcements/:id (eliminar anuncio)
  Future<void> deleteAnnouncement(int id) async {
    await apiClient.delete(ApiEndpoints.announcementById(id));
  }
}

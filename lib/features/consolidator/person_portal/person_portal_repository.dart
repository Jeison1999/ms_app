import '../../../core/api/api_client.dart';
import '../../../core/api/api_endpoints.dart';
import 'models/person_portal_model.dart';
import 'models/person_registration_model.dart';

class PersonPortalRepository {
  final ApiClient apiClient;

  PersonPortalRepository({required this.apiClient});

  // GET /api/v1/person_portal
  Future<PersonPortalModel> getPortal() async {
    final response = await apiClient.get(ApiEndpoints.personPortal);
    final data = response.data['person_portal'] as Map<String, dynamic>;
    return PersonPortalModel.fromJson(data);
  }

  // PATCH /api/v1/person_portal
  Future<PersonPortalModel> updatePortal(Map<String, dynamic> portal) async {
    final response = await apiClient.patch(
      ApiEndpoints.personPortal,
      data: {'person_portal': portal},
    );
    final data = response.data['person_portal'] as Map<String, dynamic>;
    return PersonPortalModel.fromJson(data);
  }

  // GET /api/v1/person_registrations?status=&kind=
  Future<PersonRegistrationsListResult> getRegistrations({
    String? status,
    String? kind,
  }) async {
    final query = <String, dynamic>{};
    if (status != null && status.isNotEmpty) query['status'] = status;
    if (kind != null && kind.isNotEmpty) query['kind'] = kind;

    final response = await apiClient.get(
      ApiEndpoints.personRegistrations,
      queryParameters: query.isEmpty ? null : query,
    );
    final data = response.data as Map<String, dynamic>;
    final list = (data['registrations'] as List? ?? [])
        .whereType<Map>()
        .map(
          (e) => PersonRegistrationModel.fromJson(
            Map<String, dynamic>.from(e),
          ),
        )
        .toList();
    final meta = data['meta'] as Map<String, dynamic>? ?? {};
    return PersonRegistrationsListResult(
      registrations: list,
      total: (meta['total'] as num?)?.toInt() ?? list.length,
      pendingCount: (meta['pending_count'] as num?)?.toInt() ?? 0,
    );
  }

  // GET /api/v1/person_registrations/:id
  Future<PersonRegistrationModel> getRegistration(int id) async {
    final response = await apiClient.get(ApiEndpoints.personRegistrationById(id));
    final data = response.data['registration'] as Map<String, dynamic>;
    return PersonRegistrationModel.fromJson(data);
  }

  // POST .../approve
  Future<PersonRegistrationModel> approve(int id) async {
    final response = await apiClient.post(
      ApiEndpoints.approvePersonRegistration(id),
    );
    final data = response.data['registration'] as Map<String, dynamic>;
    return PersonRegistrationModel.fromJson(data);
  }

  // POST .../reject
  Future<PersonRegistrationModel> reject(
    int id, {
    String? rejectionReason,
  }) async {
    final response = await apiClient.post(
      ApiEndpoints.rejectPersonRegistration(id),
      data: {
        if (rejectionReason != null && rejectionReason.trim().isNotEmpty)
          'rejection_reason': rejectionReason.trim(),
      },
    );
    final data = response.data['registration'] as Map<String, dynamic>;
    return PersonRegistrationModel.fromJson(data);
  }

  // DELETE /api/v1/person_registrations/:id (solo rejected)
  Future<int> deleteRegistration(int id) async {
    final response = await apiClient.delete(
      ApiEndpoints.personRegistrationById(id),
    );
    return (response.data['registration_id'] as num).toInt();
  }

  // DELETE /api/v1/person_registrations/cleanup_rejected
  Future<int> cleanupRejectedRegistrations() async {
    final response = await apiClient.delete(
      ApiEndpoints.personRegistrationsCleanupRejected,
    );
    return (response.data['deleted_count'] as num).toInt();
  }
}

import '../../../core/api/api_client.dart';
import '../../../core/api/api_endpoints.dart';
import 'models/person_model.dart';

class PeopleListResult {
  final List<PersonModel> people;
  final int total;
  final String? status;
  final String? q;

  PeopleListResult({
    required this.people,
    required this.total,
    this.status,
    this.q,
  });
}

class PersonRepository {
  final ApiClient apiClient;

  PersonRepository({required this.apiClient});

  // GET /api/v1/people?q=&status=active|inactive
  Future<PeopleListResult> getPeople({String? q, String? status}) async {
    final query = <String, dynamic>{};
    if (q != null && q.trim().isNotEmpty) {
      query['q'] = q.trim();
    }
    if (status != null && status.isNotEmpty) {
      query['status'] = status;
    }

    final response = await apiClient.get(
      ApiEndpoints.people,
      queryParameters: query.isEmpty ? null : query,
    );
    final data = response.data as Map<String, dynamic>;
    final people = (data['people'] as List)
        .map((p) => PersonModel.fromJson(p as Map<String, dynamic>))
        .toList();
    final meta = data['meta'] as Map<String, dynamic>? ?? {};

    return PeopleListResult(
      people: people,
      total: (meta['total'] as int?) ?? people.length,
      status: meta['status'] as String?,
      q: meta['q'] as String?,
    );
  }

  // GET /api/v1/people/:id
  Future<PersonModel> getPerson(int id) async {
    final response = await apiClient.get(ApiEndpoints.personById(id));
    final data = response.data['person'] as Map<String, dynamic>;
    return PersonModel.fromJson(data);
  }

  // POST /api/v1/people
  Future<PersonModel> createPerson(Map<String, dynamic> personData) async {
    final response = await apiClient.post(
      ApiEndpoints.people,
      data: {'person': personData},
    );
    final data = response.data['person'] as Map<String, dynamic>;
    return PersonModel.fromJson(data);
  }

  // PATCH /api/v1/people/:id
  Future<PersonModel> updatePerson(
    int id,
    Map<String, dynamic> personData,
  ) async {
    final response = await apiClient.patch(
      ApiEndpoints.personById(id),
      data: {'person': personData},
    );
    final data = response.data['person'] as Map<String, dynamic>;
    return PersonModel.fromJson(data);
  }

  // DELETE /api/v1/people/:id (desactivar)
  Future<PersonModel> deactivatePerson(int id) async {
    final response = await apiClient.delete(ApiEndpoints.personById(id));
    final data = response.data['person'] as Map<String, dynamic>;
    return PersonModel.fromJson(data);
  }

  // POST /api/v1/people/:id/reactivate
  Future<PersonModel> reactivatePerson(int id) async {
    final response = await apiClient.post(ApiEndpoints.reactivatePerson(id));
    final data = response.data['person'] as Map<String, dynamic>;
    return PersonModel.fromJson(data);
  }
}

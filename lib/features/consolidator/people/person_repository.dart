import 'dart:typed_data';

import 'package:dio/dio.dart';

import '../../../core/api/api_client.dart';
import '../../../core/api/api_endpoints.dart';
import 'models/people_filter_options.dart';
import 'models/person_filters.dart';
import 'models/person_model.dart';
import 'models/person_qr_model.dart';

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

class PersonExportResult {
  final Uint8List bytes;
  final String filename;

  PersonExportResult({required this.bytes, required this.filename});
}

class PersonRepository {
  final ApiClient apiClient;

  PersonRepository({required this.apiClient});

  // GET /api/v1/people/filter_options
  Future<PeopleFilterOptions> getFilterOptions() async {
    final response = await apiClient.get(ApiEndpoints.peopleFilterOptions);
    return PeopleFilterOptions.fromJson(response.data as Map<String, dynamic>);
  }

  // GET /api/v1/people?...filtros
  Future<PeopleListResult> getPeople({PersonFilters? filters}) async {
    final query = (filters ?? PersonFilters()).toQueryParameters();

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
      status: meta['status'] as String? ?? filters?.status,
      q: meta['q'] as String? ?? filters?.q,
    );
  }

  // POST /api/v1/people/export
  // Si personIds tiene al menos un id → solo esas personas; si no → filters.
  Future<PersonExportResult> exportPeople({
    required List<String> columns,
    PersonFilters? filters,
    List<int>? personIds,
  }) async {
    final ids = personIds?.where((id) => id > 0).toList() ?? const <int>[];
    final data = <String, dynamic>{
      'columns': columns,
      if (ids.isNotEmpty)
        'person_ids': ids
      else
        'filters': (filters ?? PersonFilters()).toExportFilters(),
    };

    final response = await apiClient.post(
      ApiEndpoints.peopleExport,
      data: data,
      options: Options(
        responseType: ResponseType.bytes,
        headers: {'Accept': '*/*'},
      ),
    );

    final bytes = Uint8List.fromList(response.data as List<int>);
    final disposition = response.headers.value('content-disposition');
    var filename = 'personas_export.xlsx';
    if (disposition != null) {
      final match = RegExp(
        r'filename[^;=\n]*=(([\"' "'" r']).*?\2|[^;\n]*)',
      ).firstMatch(disposition);
      if (match != null) {
        filename = match.group(1)!.replaceAll('"', '').replaceAll("'", '');
      }
    }

    return PersonExportResult(bytes: bytes, filename: filename);
  }

  // GET /api/v1/people/:id
  Future<PersonModel> getPerson(int id) async {
    final response = await apiClient.get(ApiEndpoints.personById(id));
    final data = response.data['person'] as Map<String, dynamic>;
    return PersonModel.fromJson(data);
  }

  // GET /api/v1/people/:id/qr
  Future<PersonQrModel> getPersonQr(int id) async {
    final response = await apiClient.get(ApiEndpoints.personQr(id));
    final data = response.data is Map<String, dynamic>
        ? response.data as Map<String, dynamic>
        : <String, dynamic>{};
    final payload = data.containsKey('qr_payload') || data.containsKey('code')
        ? data
        : (data['qr'] is Map<String, dynamic>
              ? data['qr'] as Map<String, dynamic>
              : data);
    return PersonQrModel.fromJson(payload);
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

  // POST /api/v1/people/:id/purge (solo administrator)
  Future<int> purgePerson(int id, {required String confirmation}) async {
    final response = await apiClient.post(
      ApiEndpoints.personPurge(id),
      data: {'confirmation': confirmation},
    );
    return (response.data['person_id'] as num).toInt();
  }

  // GET /api/v1/people/birthdays/today
  Future<BirthdaysResult> getBirthdaysToday() async {
    final response = await apiClient.get(ApiEndpoints.peopleBirthdaysToday);
    return BirthdaysResult.fromJson(response.data as Map<String, dynamic>);
  }

  // GET /api/v1/people/birthdays/month?month=
  Future<BirthdaysResult> getBirthdaysMonth({int? month}) async {
    final query = <String, dynamic>{};
    if (month != null) query['month'] = month;
    final response = await apiClient.get(
      ApiEndpoints.peopleBirthdaysMonth,
      queryParameters: query.isEmpty ? null : query,
    );
    return BirthdaysResult.fromJson(response.data as Map<String, dynamic>);
  }
}

class BirthdaysResult {
  final List<PersonModel> people;
  final int total;
  final String? date;
  final int? month;
  final int? year;
  final int? todayCount;

  BirthdaysResult({
    required this.people,
    required this.total,
    this.date,
    this.month,
    this.year,
    this.todayCount,
  });

  factory BirthdaysResult.fromJson(Map<String, dynamic> data) {
    final people = (data['people'] as List? ?? [])
        .map((p) => PersonModel.fromJson(p as Map<String, dynamic>))
        .toList();
    final meta = data['meta'] as Map<String, dynamic>? ?? {};
    return BirthdaysResult(
      people: people,
      total: (meta['total'] as int?) ?? people.length,
      date: meta['date']?.toString(),
      month: meta['month'] is int
          ? meta['month'] as int
          : int.tryParse(meta['month']?.toString() ?? ''),
      year: meta['year'] is int
          ? meta['year'] as int
          : int.tryParse(meta['year']?.toString() ?? ''),
      todayCount: meta['today_count'] is int
          ? meta['today_count'] as int
          : int.tryParse(meta['today_count']?.toString() ?? ''),
    );
  }
}

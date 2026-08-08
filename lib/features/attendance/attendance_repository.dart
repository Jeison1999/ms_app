import 'dart:typed_data';

import 'package:dio/dio.dart';

import '../../core/api/api_client.dart';
import '../../core/api/api_endpoints.dart';
import 'models/absence_report.dart';
import 'models/attendance_event.dart';
import 'models/attendance_group.dart';

class AttendanceExportResult {
  final Uint8List bytes;
  final String filename;

  AttendanceExportResult({required this.bytes, required this.filename});
}

class AttendanceRepository {
  final ApiClient apiClient;

  AttendanceRepository({required this.apiClient});

  // ---- Groups ----

  Future<List<AttendanceGroup>> getGroups({bool? active = true}) async {
    final query = <String, dynamic>{};
    if (active != null) query['active'] = active;
    final response = await apiClient.get(
      ApiEndpoints.attendanceGroups,
      queryParameters: query.isEmpty ? null : query,
    );
    final data = response.data;
    final list = data is Map
        ? (data['groups'] as List? ?? data['attendance_groups'] as List? ?? [])
        : (data as List? ?? []);
    return list
        .whereType<Map>()
        .map((e) => AttendanceGroup.fromJson(Map<String, dynamic>.from(e)))
        .toList();
  }

  Future<AttendanceGroup> getGroup(int id) async {
    final response = await apiClient.get(ApiEndpoints.attendanceGroupById(id));
    final data = response.data is Map
        ? (response.data['group'] ??
              response.data['attendance_group'] ??
              response.data)
        : response.data;
    return AttendanceGroup.fromJson(Map<String, dynamic>.from(data as Map));
  }

  Future<AttendanceGroup> createGroup({
    required Map<String, dynamic> group,
    List<int> personIds = const [],
  }) async {
    final response = await apiClient.post(
      ApiEndpoints.attendanceGroups,
      data: {
        'group': group,
        if (personIds.isNotEmpty) 'person_ids': personIds,
      },
    );
    final data = response.data is Map
        ? (response.data['group'] ??
              response.data['attendance_group'] ??
              response.data)
        : response.data;
    return AttendanceGroup.fromJson(Map<String, dynamic>.from(data as Map));
  }

  Future<AttendanceGroup> updateGroup(
    int id,
    Map<String, dynamic> group,
  ) async {
    final response = await apiClient.patch(
      ApiEndpoints.attendanceGroupById(id),
      data: {'group': group},
    );
    final data = response.data is Map
        ? (response.data['group'] ??
              response.data['attendance_group'] ??
              response.data)
        : response.data;
    return AttendanceGroup.fromJson(Map<String, dynamic>.from(data as Map));
  }

  Future<void> deactivateGroup(int id) async {
    await apiClient.delete(ApiEndpoints.attendanceGroupById(id));
  }

  Future<AttendanceGroup> addMembers(int id, List<int> personIds) async {
    final response = await apiClient.post(
      ApiEndpoints.attendanceGroupAddMembers(id),
      data: {'person_ids': personIds},
    );
    final data = response.data is Map
        ? (response.data['group'] ??
              response.data['attendance_group'] ??
              response.data)
        : response.data;
    return AttendanceGroup.fromJson(Map<String, dynamic>.from(data as Map));
  }

  Future<AttendanceGroup> removeMembers(int id, List<int> personIds) async {
    final response = await apiClient.delete(
      ApiEndpoints.attendanceGroupRemoveMembers(id),
      data: {'person_ids': personIds},
    );
    final data = response.data is Map
        ? (response.data['group'] ??
              response.data['attendance_group'] ??
              response.data)
        : response.data;
    if (data is Map) {
      return AttendanceGroup.fromJson(Map<String, dynamic>.from(data));
    }
    return getGroup(id);
  }

  // ---- Events ----

  Future<List<AttendanceEvent>> getEvents({
    int? groupId,
    int? year,
    int? month,
    String? eventType,
    String? status,
  }) async {
    final query = <String, dynamic>{};
    if (groupId != null) query['group_id'] = groupId;
    if (year != null) query['year'] = year;
    if (month != null) query['month'] = month;
    if (eventType != null && eventType.isNotEmpty) {
      query['event_type'] = eventType;
    }
    if (status != null && status.isNotEmpty) query['status'] = status;

    final response = await apiClient.get(
      ApiEndpoints.attendanceEvents,
      queryParameters: query.isEmpty ? null : query,
    );
    final data = response.data;
    final list = data is Map
        ? (data['events'] as List? ?? data['attendance_events'] as List? ?? [])
        : (data as List? ?? []);
    return list
        .whereType<Map>()
        .map((e) => AttendanceEvent.fromJson(Map<String, dynamic>.from(e)))
        .toList();
  }

  Future<AttendanceEvent> getEvent(int id) async {
    final response = await apiClient.get(ApiEndpoints.attendanceEventById(id));
    final data = response.data is Map
        ? (response.data['event'] ??
              response.data['attendance_event'] ??
              response.data)
        : response.data;
    return AttendanceEvent.fromJson(Map<String, dynamic>.from(data as Map));
  }

  Future<AttendanceEvent> createEvent({
    required Map<String, dynamic> event,
    List<int> personIds = const [],
  }) async {
    final response = await apiClient.post(
      ApiEndpoints.attendanceEvents,
      data: {
        'event': event,
        if (personIds.isNotEmpty) 'person_ids': personIds,
      },
    );
    final data = response.data is Map
        ? (response.data['event'] ??
              response.data['attendance_event'] ??
              response.data)
        : response.data;
    return AttendanceEvent.fromJson(Map<String, dynamic>.from(data as Map));
  }

  Future<AttendanceEvent> updateEvent(
    int id,
    Map<String, dynamic> event,
  ) async {
    final response = await apiClient.patch(
      ApiEndpoints.attendanceEventById(id),
      data: {'event': event},
    );
    final data = response.data is Map
        ? (response.data['event'] ??
              response.data['attendance_event'] ??
              response.data)
        : response.data;
    return AttendanceEvent.fromJson(Map<String, dynamic>.from(data as Map));
  }

  Future<void> deleteEvent(int id) async {
    await apiClient.delete(ApiEndpoints.attendanceEventById(id));
  }

  Future<AttendanceEvent> updateRecords(
    int id,
    List<AttendanceRecord> records,
  ) async {
    final response = await apiClient.patch(
      ApiEndpoints.attendanceEventRecords(id),
      data: {
        'records': records.map((r) => r.toUpdateJson()).toList(),
      },
    );
    final data = response.data is Map
        ? (response.data['event'] ??
              response.data['attendance_event'] ??
              response.data)
        : response.data;
    if (data is Map) {
      return AttendanceEvent.fromJson(Map<String, dynamic>.from(data));
    }
    return getEvent(id);
  }

  Future<AttendanceEvent> closeEvent(int id) async {
    final response = await apiClient.post(ApiEndpoints.attendanceEventClose(id));
    final data = response.data is Map
        ? (response.data['event'] ??
              response.data['attendance_event'] ??
              response.data)
        : response.data;
    if (data is Map) {
      return AttendanceEvent.fromJson(Map<String, dynamic>.from(data));
    }
    return getEvent(id);
  }

  // ---- Reports ----

  Future<AbsenceReportResult> getAbsencesReport({
    required int groupId,
    required int year,
    int? month,
    bool flaggedOnly = true,
    int? threshold,
  }) async {
    final query = <String, dynamic>{
      'group_id': groupId,
      'year': year,
      'flagged_only': flaggedOnly,
    };
    if (month != null) query['month'] = month;
    if (threshold != null) query['threshold'] = threshold;

    final response = await apiClient.get(
      ApiEndpoints.attendanceAbsencesReport,
      queryParameters: query,
    );
    return AbsenceReportResult.fromJson(
      Map<String, dynamic>.from(response.data as Map),
    );
  }

  Future<AttendanceExportResult> exportAbsencesReport({
    required int groupId,
    required int year,
    int? month,
    bool flaggedOnly = true,
    int? threshold,
  }) async {
    final body = <String, dynamic>{
      'group_id': groupId,
      'year': year,
      'flagged_only': flaggedOnly,
    };
    if (month != null) body['month'] = month;
    if (threshold != null) body['threshold'] = threshold;

    final response = await apiClient.post(
      ApiEndpoints.attendanceAbsencesExport,
      data: body,
      options: Options(
        responseType: ResponseType.bytes,
        headers: {'Accept': '*/*'},
      ),
    );

    final bytes = Uint8List.fromList(response.data as List<int>);
    final disposition = response.headers.value('content-disposition');
    var filename = 'ausencias_export.xlsx';
    if (disposition != null) {
      final match = RegExp(
        r'filename[^;=\n]*=(([\"' "'" r']).*?\2|[^;\n]*)',
      ).firstMatch(disposition);
      if (match != null) {
        filename = match.group(1)!.replaceAll('"', '').replaceAll("'", '');
      }
    }
    return AttendanceExportResult(bytes: bytes, filename: filename);
  }
}

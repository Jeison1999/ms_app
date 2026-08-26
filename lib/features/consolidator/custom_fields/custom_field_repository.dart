import '../../../core/api/api_client.dart';
import '../../../core/api/api_endpoints.dart';
import 'models/custom_field_model.dart';

class CustomFieldWriteResult {
  final CustomFieldModel field;
  final bool portalEnabled;
  final String? portalAutoEnabledReason;

  CustomFieldWriteResult({
    required this.field,
    this.portalEnabled = false,
    this.portalAutoEnabledReason,
  });
}

class CustomFieldRepository {
  final ApiClient apiClient;

  CustomFieldRepository({required this.apiClient});

  // GET /api/v1/custom_fields?active=true|false
  Future<List<CustomFieldModel>> getCustomFields({bool? active}) async {
    final query = <String, dynamic>{};
    if (active != null) {
      query['active'] = active;
    }

    final response = await apiClient.get(
      ApiEndpoints.customFields,
      queryParameters: query.isEmpty ? null : query,
    );
    final data = response.data as Map<String, dynamic>;
    return (data['custom_fields'] as List)
        .map((f) => CustomFieldModel.fromJson(f as Map<String, dynamic>))
        .toList()
      ..sort((a, b) => a.position.compareTo(b.position));
  }

  Future<CustomFieldModel> getCustomField(int id) async {
    final response = await apiClient.get(ApiEndpoints.customFieldById(id));
    final data = response.data['custom_field'] as Map<String, dynamic>;
    return CustomFieldModel.fromJson(data);
  }

  Future<CustomFieldWriteResult> createCustomField(
    Map<String, dynamic> fieldData,
  ) async {
    final response = await apiClient.post(
      ApiEndpoints.customFields,
      data: {'custom_field': fieldData},
    );
    return _writeResultFrom(response.data as Map<String, dynamic>);
  }

  Future<CustomFieldWriteResult> updateCustomField(
    int id,
    Map<String, dynamic> fieldData,
  ) async {
    final response = await apiClient.patch(
      ApiEndpoints.customFieldById(id),
      data: {'custom_field': fieldData},
    );
    return _writeResultFrom(response.data as Map<String, dynamic>);
  }

  CustomFieldWriteResult _writeResultFrom(Map<String, dynamic> data) {
    final field = CustomFieldModel.fromJson(
      data['custom_field'] as Map<String, dynamic>,
    );
    final portal = data['person_portal'];
    if (portal is Map) {
      return CustomFieldWriteResult(
        field: field,
        portalEnabled: portal['enabled'] as bool? ?? false,
        portalAutoEnabledReason: portal['auto_enabled_reason']?.toString(),
      );
    }
    return CustomFieldWriteResult(field: field);
  }

  Future<void> deactivateCustomField(int id) async {
    await apiClient.delete(ApiEndpoints.customFieldById(id));
  }

  Future<CustomFieldModel> reactivateCustomField(int id) async {
    final response = await apiClient.post(
      ApiEndpoints.reactivateCustomField(id),
    );
    final data = response.data['custom_field'] as Map<String, dynamic>;
    return CustomFieldModel.fromJson(data);
  }
}

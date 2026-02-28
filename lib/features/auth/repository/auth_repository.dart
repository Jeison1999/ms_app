import '../../../core/api/api_client.dart';
import '../../../core/api/api_endpoints.dart';
import '../../../core/utils/storage_service.dart';
import '../models/auth_response.dart';
import '../models/user_model.dart';

class AuthRepository {
  final ApiClient apiClient;
  final StorageService storageService;

  AuthRepository({required this.apiClient, required this.storageService});

  Future<AuthResponse> login({
    required String email,
    required String password,
  }) async {
    final response = await apiClient.post(
      ApiEndpoints.login,
      data: {'email': email, 'password': password},
    );

    final authResponse = AuthResponse.fromJson(response.data);

    await storageService.saveToken(authResponse.token);
    await storageService.saveUser(authResponse.user.toJson());

    return authResponse;
  }

  Future<AuthResponse> register({
    required String email,
    required String password,
    required String passwordConfirmation,
    required String firstName,
    required String lastName,
    String? phone,
  }) async {
    final response = await apiClient.post(
      ApiEndpoints.register,
      data: {
        'user': {
          'email': email,
          'password': password,
          'password_confirmation': passwordConfirmation,
          'first_name': firstName,
          'last_name': lastName,
          'phone': ?phone,
        },
      },
    );

    final authResponse = AuthResponse.fromJson(response.data);

    await storageService.saveToken(authResponse.token);
    await storageService.saveUser(authResponse.user.toJson());

    return authResponse;
  }

  Future<UserModel> getCurrentUser() async {
    final response = await apiClient.get(ApiEndpoints.me);
    final userData = response.data['user'] as Map<String, dynamic>;
    return UserModel.fromJson(userData);
  }

  Future<AuthResponse> refreshToken() async {
    final response = await apiClient.post(ApiEndpoints.refresh);
    final authResponse = AuthResponse.fromJson(response.data);

    await storageService.saveToken(authResponse.token);
    await storageService.saveUser(authResponse.user.toJson());

    return authResponse;
  }

  Future<void> logout() async {
    await storageService.clearAll();
  }

  Future<UserModel?> getStoredUser() async {
    final userData = await storageService.getUser();
    if (userData != null) {
      return UserModel.fromJson(userData);
    }
    return null;
  }

  Future<bool> hasValidToken() async {
    final token = await storageService.getToken();
    return token != null && token.isNotEmpty;
  }
}

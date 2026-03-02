import 'package:dio/dio.dart';
import '../config/environment.dart';

class CloudinaryService {
  final Dio _dio;

  CloudinaryService({Dio? dio}) : _dio = dio ?? Dio();

  Future<String> uploadImage({
    required String filePath,
    String? fileName,
  }) async {
    if (Environment.cloudinaryCloudName.isEmpty ||
        Environment.cloudinaryUploadPreset.isEmpty) {
      throw Exception(
        'Cloudinary no configurado. Define CLOUDINARY_CLOUD_NAME y CLOUDINARY_UPLOAD_PRESET.',
      );
    }

    final endpoint =
        'https://api.cloudinary.com/v1_1/${Environment.cloudinaryCloudName}/image/upload';

    final formData = FormData.fromMap({
      'upload_preset': Environment.cloudinaryUploadPreset,
      'file': await MultipartFile.fromFile(
        filePath,
        filename: fileName,
      ),
    });

    final response = await _dio.post(endpoint, data: formData);
    final data = response.data;
    if (data is! Map<String, dynamic>) {
      throw Exception('Respuesta inválida de Cloudinary');
    }

    final secureUrl = data['secure_url'];
    if (secureUrl is! String || secureUrl.isEmpty) {
      throw Exception('Cloudinary no retornó secure_url');
    }
    return secureUrl;
  }
}

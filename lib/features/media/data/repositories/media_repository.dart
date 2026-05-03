import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/api_constants.dart';
import '../../../../core/error/api_exception.dart';
import '../../../../core/network/api_provider.dart';
import '../../../../core/network/dio_client.dart';

final mediaRepositoryProvider = Provider<MediaRepository>((ref) {
  return MediaRepository(ref.watch(apiClientProvider));
});

class MediaRepository {
  final DioClient _client;

  const MediaRepository(this._client);

  Future<String> uploadImage({
    required List<int> bytes,
    required String filename,
  }) async {
    try {
      final formData = FormData.fromMap({
        'file': MultipartFile.fromBytes(bytes, filename: filename),
      });
      final response = await _client.post<Map<String, dynamic>>(
        '/media/upload',
        data: formData,
        options: Options(contentType: 'multipart/form-data'),
      );
      final url = response.data?['url']?.toString();
      if (url == null || url.isEmpty) {
        throw const ApiException(
          message: 'El backend no devolvió URL de imagen.',
        );
      }
      return ApiConstants.resolveBackendUrl(url) ?? url;
    } on DioException catch (error) {
      throw ApiException.fromDioException(error);
    }
  }
}

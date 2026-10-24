import 'package:bakery_mobile/src/core/network/api_client.dart';

/// Uploads base64 image data URLs to `/api/upload` for the product form.
///
/// Server constraints (enforced server-side, mirrored here): images only
/// (png/jpeg/webp/avif/heic), ≤5MB each and AT MOST 5 FILES PER REQUEST —
/// so a larger batch is uploaded in sequential chunks of five, preserving
/// order. The server forces its own Cloudinary folder; callers must not
/// send one.
class UploadApiService {
  const UploadApiService(this._client);

  static const int maxFilesPerRequest = 5;

  final ApiClient _client;

  /// Uploads [dataUrls] sequentially in chunks of five and returns the
  /// hosted urls IN THE SAME ORDER as the input. Throws [Exception] with
  /// the failing batch index when any upload fails — nothing is silently
  /// dropped, and the caller must not proceed with a partial upload.
  Future<List<String>> uploadImages(List<String> dataUrls) async {
    final urls = <String>[];
    for (var start = 0; start < dataUrls.length; start += maxFilesPerRequest) {
      final chunk = dataUrls.skip(start).take(maxFilesPerRequest).toList();
      for (final (index, dataUrl) in chunk.indexed) {
        final response = await _client.post(
          '/api/upload',
          body: {'file': dataUrl},
        );
        final data = response is Map<String, dynamic>
            ? (response['data'] is Map<String, dynamic>
                  ? response['data']! as Map<String, dynamic>
                  : const <String, dynamic>{})
            : const <String, dynamic>{};
        final url = data['url']?.toString();
        if (url == null || url.isEmpty) {
          throw Exception('Tải ảnh thất bại (ảnh số ${start + index + 1})');
        }
        urls.add(url);
      }
    }
    return urls;
  }
}

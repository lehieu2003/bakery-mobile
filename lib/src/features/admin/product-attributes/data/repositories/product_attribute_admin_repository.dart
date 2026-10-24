import 'package:bakery_mobile/src/features/admin/product-attributes/data/datasources/product_attribute_admin_api_service.dart';
import 'package:bakery_mobile/src/features/admin/product-attributes/domain/models/product_attribute_models.dart';

AdminCatalogueAttribute catalogueAttributeFromJson(Map<String, dynamic> json) =>
    AdminCatalogueAttribute(
      id: (json['id'] ?? '').toString(),
      name: (json['name'] ?? '').toString(),
      code: (json['code'] ?? '').toString(),
      type: (json['type'] ?? 'SELECT').toString(),
      values: json['values'] is List<dynamic>
          ? [
              for (final value in json['values'] as List<dynamic>)
                if (value is Map<String, dynamic>)
                  AdminCatalogueValue(
                    id: (value['id'] ?? '').toString(),
                    label: (value['label'] ?? value['value'] ?? '').toString(),
                  ),
            ]
          : const [],
    );

/// Vietnamese diacritics → ASCII base letters (server slug does the same).
const Map<String, String> _viTranslit = {
  'à': 'a', 'á': 'a', 'ả': 'a', 'ã': 'a', 'ạ': 'a', //
  'ă': 'a', 'ằ': 'a', 'ắ': 'a', 'ẳ': 'a', 'ẵ': 'a', 'ặ': 'a',
  'â': 'a', 'ầ': 'a', 'ấ': 'a', 'ẩ': 'a', 'ẫ': 'a', 'ậ': 'a',
  'è': 'e', 'é': 'e', 'ẻ': 'e', 'ẽ': 'e', 'ẹ': 'e',
  'ê': 'e', 'ề': 'e', 'ế': 'e', 'ể': 'e', 'ễ': 'e', 'ệ': 'e',
  'ì': 'i', 'í': 'i', 'ỉ': 'i', 'ĩ': 'i', 'ị': 'i',
  'ò': 'o', 'ó': 'o', 'ỏ': 'o', 'õ': 'o', 'ọ': 'o',
  'ô': 'o', 'ồ': 'o', 'ố': 'o', 'ổ': 'o', 'ỗ': 'o', 'ộ': 'o',
  'ơ': 'o', 'ờ': 'o', 'ớ': 'o', 'ở': 'o', 'ỡ': 'o', 'ợ': 'o',
  'ù': 'u', 'ú': 'u', 'ủ': 'u', 'ũ': 'u', 'ụ': 'u',
  'ư': 'u', 'ừ': 'u', 'ứ': 'u', 'ử': 'u', 'ữ': 'u', 'ự': 'u',
  'ỳ': 'y', 'ý': 'y', 'ỷ': 'y', 'ỹ': 'y', 'ỵ': 'y',
  'đ': 'd',
};

/// Derives the server-required `code` from a display name
/// ("Màu Kem" → "MAU_KEM", Vietnamese transliterated), falling back to a
/// timestamp suffix when no usable ASCII letters remain.
String deriveAttributeCode(String name) {
  final translit = name.split('').map((c) => _viTranslit[c] ?? c).join();
  final ascii = translit
      .replaceAll(RegExp(r'[^A-Za-z0-9]+'), '_')
      .replaceAll(RegExp(r'^_+|_+$'), '')
      .toUpperCase();
  if (ascii.isEmpty || !RegExp(r'[A-Z]').hasMatch(ascii)) {
    return 'ATTR_${DateTime.now().millisecondsSinceEpoch}';
  }
  return ascii;
}

class ProductAttributeAdminRepository {
  const ProductAttributeAdminRepository(this._service);

  final ProductAttributeAdminApiService _service;

  Future<List<AdminCatalogueAttribute>> getAttributes() async {
    final data = await _service.getAttributes();
    final rows = data is Map<String, dynamic> ? data['attributes'] : data;
    if (rows is! List<dynamic>) return const [];
    return [
      for (final row in rows)
        if (row is Map<String, dynamic>) catalogueAttributeFromJson(row),
    ];
  }

  Future<AdminCatalogueAttribute> createAttribute({
    required String name,
    required String type,
    List<String> valueLabels = const [],
  }) async {
    final data = await _service.createAttribute({
      'name': name,
      'code': deriveAttributeCode(name),
      'type': type,
      'values': [
        for (final label in valueLabels)
          if (label.trim().isNotEmpty) {'label': label.trim()},
      ],
    });
    final attribute = data is Map<String, dynamic> ? data['attribute'] : data;
    if (attribute is! Map<String, dynamic>) {
      throw StateError('Create attribute: unexpected response');
    }
    return catalogueAttributeFromJson(attribute);
  }

  Future<AdminCatalogueAttribute> updateAttribute({
    required String id,
    String? name,
    String? type,
    List<String>? valueLabels,
  }) async {
    final body = <String, dynamic>{
      if (name != null) 'name': name,
      if (type != null) 'type': type,
      if (valueLabels != null)
        'values': [
          for (final label in valueLabels)
            if (label.trim().isNotEmpty) {'label': label.trim()},
        ],
    };
    final data = await _service.updateAttribute(id, body);
    final attribute = data is Map<String, dynamic> ? data['attribute'] : data;
    if (attribute is! Map<String, dynamic>) {
      throw StateError('Update attribute: unexpected response');
    }
    return catalogueAttributeFromJson(attribute);
  }

  Future<void> deleteAttribute(String id) async {
    await _service.deleteAttribute(id);
  }
}

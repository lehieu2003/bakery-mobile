import 'package:bakery_mobile/src/features/admin/products/data/datasources/product_admin_api_service.dart';
import 'package:bakery_mobile/src/features/admin/products/data/dtos/product_admin_dto.dart';
import 'package:bakery_mobile/src/features/admin/products/data/dtos/product_admin_list_dto.dart';
import 'package:bakery_mobile/src/features/admin/products/domain/models/admin_product.dart';

/// One page of the admin products list.
class ProductAdminPage {
  const ProductAdminPage({
    required this.items,
    required this.totalPages,
    required this.total,
  });

  final List<AdminProductListItem> items;
  final int totalPages;
  final int total;
}

/// Admin product repository: list and delete over `/api/admin/products`.
/// Errors (e.g. a 404 delete) bubble up untouched so the view model can
/// show the server's message.
class ProductAdminRepository {
  const ProductAdminRepository(this._service);

  final ProductAdminApiService _service;

  /// Loads one page of admin products (newest first). [search] matches
  /// name / description server-side.
  Future<ProductAdminPage> getProducts({
    int page = 1,
    int limit = 20,
    String? search,
  }) async {
    final payload = await _service.getProducts(
      page: page,
      limit: limit,
      search: search,
    );
    final dto = AdminProductListDto.fromJson(payload);
    return ProductAdminPage(
      items: dto.products,
      totalPages: dto.pagination.totalPages,
      total: dto.pagination.total,
    );
  }

  /// Deletes a product by id. Failures (404 `Không tìm thấy sản phẩm`,
  /// ...) propagate with the server's message intact.
  Future<void> deleteProduct(String id) async {
    await _service.deleteProduct(id);
  }

  /// Loads one product's full detail (images, variants, category ids,
  /// grouped attribute assignments) for the edit form.
  Future<AdminProductDetail> getProduct(String id) async {
    final data = await _service.getProduct(id);
    return AdminProductDetailDto.fromJson(
      data['data'] is Map<String, dynamic>
          ? data['data']! as Map<String, dynamic>
          : const {},
    );
  }

  /// Creates a product; returns the created detail.
  Future<AdminProductDetail> createProduct(Map<String, dynamic> body) async {
    final data = await _service.createProduct(body);
    return AdminProductDetailDto.fromJson(
      data['data'] is Map<String, dynamic>
          ? data['data']! as Map<String, dynamic>
          : const {},
    );
  }

  /// Updates a product (images/assignments replace their sets); returns
  /// the updated detail.
  Future<AdminProductDetail> updateProduct(
    String id,
    Map<String, dynamic> body,
  ) async {
    final data = await _service.updateProduct(id, body);
    return AdminProductDetailDto.fromJson(
      data['data'] is Map<String, dynamic>
          ? data['data']! as Map<String, dynamic>
          : const {},
    );
  }

  /// The attribute catalogue for the form's filter section.
  Future<List<AdminAttribute>> getAttributes() async {
    final data = await _service.getAttributes();
    if (data is Map<String, dynamic>) {
      return ProductAttributeCatalogueDto.fromJson(
        data['data'] is Map<String, dynamic>
            ? data['data']! as Map<String, dynamic>
            : data,
      );
    }
    return const [];
  }
}

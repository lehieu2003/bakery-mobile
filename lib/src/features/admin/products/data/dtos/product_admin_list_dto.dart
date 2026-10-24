import 'package:bakery_mobile/src/features/admin/products/data/dtos/product_admin_dto.dart';
import 'package:bakery_mobile/src/features/admin/products/domain/models/admin_product.dart';
import 'package:bakery_mobile/src/features/admin/shared/utils/json_num.dart';

/// Envelope of `GET /api/admin/products` (after `ApiClient` unwraps `data`):
/// `{ products: [...], pagination: { page, limit, total, totalPages } }`.
class AdminProductListDto {
  const AdminProductListDto({required this.products, required this.pagination});

  final List<AdminProductListItem> products;
  final AdminProductPaginationDto pagination;

  factory AdminProductListDto.fromJson(Map<String, dynamic> json) {
    final pagination = json['pagination'];
    return AdminProductListDto(
      products: parseJsonList(json['products'], AdminProductDto.fromJson),
      pagination: pagination is Map<String, dynamic>
          ? AdminProductPaginationDto.fromJson(pagination)
          : const AdminProductPaginationDto(),
    );
  }
}

/// `pagination` block of the admin products list envelope.
class AdminProductPaginationDto {
  const AdminProductPaginationDto({
    this.page = 0,
    this.limit = 0,
    this.total = 0,
    this.totalPages = 0,
  });

  final int page;
  final int limit;
  final int total;
  final int totalPages;

  factory AdminProductPaginationDto.fromJson(Map<String, dynamic> json) {
    return AdminProductPaginationDto(
      page: asNum(json['page']).toInt(),
      limit: asNum(json['limit']).toInt(),
      total: asNum(json['total']).toInt(),
      totalPages: asNum(json['totalPages']).toInt(),
    );
  }
}

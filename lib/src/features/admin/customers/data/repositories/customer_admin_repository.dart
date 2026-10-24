import 'package:bakery_mobile/src/features/admin/customers/data/datasources/customer_admin_api_service.dart';
import 'package:bakery_mobile/src/features/admin/customers/data/dtos/customer_admin_dto.dart';
import 'package:bakery_mobile/src/features/admin/customers/domain/models/admin_customer.dart';

/// One page of the admin customers list.
class CustomerAdminPage {
  const CustomerAdminPage({
    required this.items,
    required this.totalPages,
    required this.total,
  });

  final List<AdminCustomer> items;
  final int totalPages;
  final int total;
}

/// Admin customer repository: list, detail and member-level/points updates
/// over `/api/admin/customers`.
class CustomerAdminRepository {
  const CustomerAdminRepository(this._service);

  final CustomerAdminApiService _service;

  /// Loads one page of admin customers (newest first). [search] matches
  /// name / email / phone; [level] filters by an uppercase member level
  /// (null = all).
  Future<CustomerAdminPage> getCustomers({
    int page = 1,
    int limit = 50,
    String? search,
    String? level,
  }) async {
    final payload = await _service.getCustomers(
      page: page,
      limit: limit,
      search: search,
      level: level,
    );
    final dto = AdminCustomerListDto.fromJson(payload);
    return CustomerAdminPage(
      items: dto.customers,
      totalPages: dto.pagination.totalPages,
      total: dto.pagination.total,
    );
  }

  /// Loads one customer by id, including the recent orders, payments and
  /// notifications blocks.
  Future<AdminCustomerDetail> getCustomer(String id) async {
    final payload = await _service.getCustomer(id);
    return AdminCustomerDetailDto.fromJson(payload);
  }

  /// Updates a customer's member level and/or points; only provided keys
  /// are sent. Returns the updated customer parsed from the response (the
  /// customer detail object directly, same shape as [getCustomer]).
  Future<AdminCustomerDetail> updateCustomer(
    String id, {
    String? memberLevel,
    int? points,
  }) async {
    final payload = await _service.updateCustomer(
      id,
      memberLevel: memberLevel,
      points: points,
    );
    return AdminCustomerDetailDto.fromJson(payload);
  }
}

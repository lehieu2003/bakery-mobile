import 'package:bakery_mobile/src/features/admin/membership/data/datasources/membership_admin_api_service.dart';
import 'package:bakery_mobile/src/features/admin/membership/domain/models/membership_models.dart';

MembershipConfig membershipFromJson(Map<String, dynamic> json) =>
    MembershipConfig(
      pointsPerOrder: json['pointsPerOrder'] is num
          ? (json['pointsPerOrder'] as num).toInt()
          : 0,
      totalMembers: json['totalMembers'] is num
          ? (json['totalMembers'] as num).toInt()
          : 0,
      levels: json['levels'] is List<dynamic>
          ? [
              for (final row in json['levels'] as List<dynamic>)
                if (row is Map<String, dynamic>)
                  MembershipLevelConfig(
                    level: (row['level'] ?? '').toString(),
                    label: (row['label'] ?? '').toString(),
                    minPoints: row['minPoints'] is num
                        ? (row['minPoints'] as num).toInt()
                        : 0,
                    discountPercent: row['discountPercent'] is num
                        ? (row['discountPercent'] as num).toInt()
                        : 0,
                    memberCount: row['memberCount'] is num
                        ? (row['memberCount'] as num).toInt()
                        : 0,
                  ),
            ]
          : const [],
    );

class MembershipAdminRepository {
  const MembershipAdminRepository(this._service);

  final MembershipAdminApiService _service;

  Future<MembershipConfig> getMembership() async {
    final data = await _service.getMembership();
    return membershipFromJson(data is Map<String, dynamic> ? data : const {});
  }

  Future<void> putMembership(Map<String, dynamic> body) =>
      _service.putMembership(body);
}

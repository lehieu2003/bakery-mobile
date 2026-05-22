import 'package:bakery_mobile/src/features/membership/data/datasources/membership_api_service.dart';
import 'package:bakery_mobile/src/features/membership/domain/models/membership_benefits.dart';

class MembershipRepository {
  MembershipRepository(this._membershipApiService);

  final MembershipApiService _membershipApiService;

  Future<MembershipBenefits> getBenefits() async {
    return (await _membershipApiService.getBenefits()).toDomain();
  }
}

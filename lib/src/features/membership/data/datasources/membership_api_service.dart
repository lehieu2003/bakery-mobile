import 'package:bakery_mobile/src/core/network/api_client.dart';
import 'package:bakery_mobile/src/features/membership/data/dtos/membership_benefits_dto.dart';

class MembershipApiService {
  MembershipApiService(this._client);

  final ApiClient _client;

  Future<MembershipBenefitsDto> getBenefits() async {
    final response = await _client.get('/api/membership/benefits');
    return MembershipBenefitsDto.fromJson(response as Map<String, dynamic>);
  }
}

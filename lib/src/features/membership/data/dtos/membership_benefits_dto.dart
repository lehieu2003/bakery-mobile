import 'package:bakery_mobile/src/core/utils/parse_utils.dart';
import 'package:bakery_mobile/src/features/membership/domain/models/membership_benefits.dart';

class MembershipBenefitsDto {
  const MembershipBenefitsDto({
    required this.userId,
    required this.memberLevel,
    required this.points,
    required this.currentTier,
    this.nextTier,
    required this.eligibilityMessage,
    required this.isHighestTier,
    required this.pointsPerOrder,
    this.tiers = const [],
  });

  final String userId;
  final String memberLevel;
  final int points;
  final MembershipTierDto currentTier;
  final MembershipNextTierDto? nextTier;
  final String eligibilityMessage;
  final bool isHighestTier;
  final int pointsPerOrder;
  final List<MembershipTierDto> tiers;

  factory MembershipBenefitsDto.fromJson(Map<String, dynamic> json) {
    final user = json['user'] as Map<String, dynamic>? ?? const {};
    final benefits = json['benefits'] as Map<String, dynamic>? ?? const {};
    final eligibility =
        benefits['eligibility'] as Map<String, dynamic>? ?? const {};
    final currentTier =
        benefits['currentTier'] as Map<String, dynamic>? ?? const {};
    final nextTier = benefits['nextTier'];

    return MembershipBenefitsDto(
      userId: (user['id'] ?? '').toString(),
      memberLevel: (user['memberLevel'] ?? currentTier['level'] ?? '')
          .toString(),
      points: ParseUtils.toInt(
        user['points'],
        field: 'MembershipBenefitsDto.points',
      ),
      currentTier: MembershipTierDto.fromJson(currentTier),
      nextTier: nextTier is Map<String, dynamic>
          ? MembershipNextTierDto.fromJson(nextTier)
          : null,
      eligibilityMessage: (eligibility['message'] ?? '').toString(),
      isHighestTier: eligibility['isHighestTier'] == true,
      pointsPerOrder: ParseUtils.toInt(
        benefits['pointsPerOrder'],
        field: 'MembershipBenefitsDto.pointsPerOrder',
      ),
      tiers: (benefits['tiers'] as List<dynamic>? ?? const [])
          .whereType<Map<String, dynamic>>()
          .map(MembershipTierDto.fromJson)
          .toList(),
    );
  }

  MembershipBenefits toDomain() {
    return MembershipBenefits(
      userId: userId,
      memberLevel: memberLevel,
      points: points,
      currentTier: currentTier.toDomain(),
      nextTier: nextTier?.toDomain(),
      eligibilityMessage: eligibilityMessage,
      isHighestTier: isHighestTier,
      pointsPerOrder: pointsPerOrder,
      tiers: tiers.map((e) => e.toDomain()).toList(),
    );
  }
}

class MembershipTierDto {
  const MembershipTierDto({
    required this.level,
    required this.label,
    required this.minPoints,
    required this.discountPercent,
    this.isEligible = false,
  });

  final String level;
  final String label;
  final int minPoints;
  final double discountPercent;
  final bool isEligible;

  factory MembershipTierDto.fromJson(Map<String, dynamic> json) {
    return MembershipTierDto(
      level: (json['level'] ?? '').toString(),
      label: (json['label'] ?? '').toString(),
      minPoints: ParseUtils.toInt(
        json['minPoints'],
        field: 'MembershipTierDto.minPoints',
      ),
      discountPercent: ParseUtils.toDouble(
        json['discountPercent'],
        field: 'MembershipTierDto.discountPercent',
      ),
      isEligible: json['isEligible'] == true,
    );
  }

  MembershipTier toDomain() {
    return MembershipTier(
      level: level,
      label: label,
      minPoints: minPoints,
      discountPercent: discountPercent,
      isEligible: isEligible,
    );
  }
}

class MembershipNextTierDto {
  const MembershipNextTierDto({
    required this.level,
    required this.label,
    required this.minPoints,
    required this.pointsNeeded,
  });

  final String level;
  final String label;
  final int minPoints;
  final int pointsNeeded;

  factory MembershipNextTierDto.fromJson(Map<String, dynamic> json) {
    return MembershipNextTierDto(
      level: (json['level'] ?? '').toString(),
      label: (json['label'] ?? '').toString(),
      minPoints: ParseUtils.toInt(
        json['minPoints'],
        field: 'MembershipNextTierDto.minPoints',
      ),
      pointsNeeded: ParseUtils.toInt(
        json['pointsNeeded'],
        field: 'MembershipNextTierDto.pointsNeeded',
      ),
    );
  }

  MembershipNextTier toDomain() {
    return MembershipNextTier(
      level: level,
      label: label,
      minPoints: minPoints,
      pointsNeeded: pointsNeeded,
    );
  }
}

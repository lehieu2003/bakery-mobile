class MembershipBenefits {
  const MembershipBenefits({
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
  final MembershipTier currentTier;
  final MembershipNextTier? nextTier;
  final String eligibilityMessage;
  final bool isHighestTier;
  final int pointsPerOrder;
  final List<MembershipTier> tiers;
}

class MembershipTier {
  const MembershipTier({
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
}

class MembershipNextTier {
  const MembershipNextTier({
    required this.level,
    required this.label,
    required this.minPoints,
    required this.pointsNeeded,
  });

  final String level;
  final String label;
  final int minPoints;
  final int pointsNeeded;
}

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

  /// VND spent per membership point — despite its server name
  /// (`pointsPerOrder` in bakery-web `lib/membership/rules.ts`, default
  /// 10000, editable by the admin), not a per-order count.
  final int pointsPerOrder;
  final List<MembershipTier> tiers;

  /// Points an order of [orderTotal] VND earns, as the server computes it:
  /// `floor(orderTotal / pointsPerOrder)`.
  int pointsFor(num orderTotal) =>
      pointsPerOrder <= 0 ? 0 : (orderTotal / pointsPerOrder).floor();
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

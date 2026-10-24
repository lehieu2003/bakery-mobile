/// Membership config response (`GET /api/admin/membership`).
class MembershipConfig {
  const MembershipConfig({
    required this.levels,
    required this.pointsPerOrder,
    required this.totalMembers,
  });

  final List<MembershipLevelConfig> levels;
  final int pointsPerOrder;
  final int totalMembers;
}

class MembershipLevelConfig {
  const MembershipLevelConfig({
    required this.level,
    required this.label,
    required this.minPoints,
    required this.discountPercent,
    required this.memberCount,
  });

  final String level;
  final String label;
  final int minPoints;
  final int discountPercent;
  final int memberCount;
}

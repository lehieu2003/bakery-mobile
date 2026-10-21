import 'package:bakery_mobile/src/features/membership/domain/models/membership_benefits.dart';
import 'package:flutter_test/flutter_test.dart';

MembershipBenefits _benefits(int pointsPerOrder) => MembershipBenefits(
  userId: 'u-1',
  memberLevel: 'GOLD',
  points: 420,
  currentTier: const MembershipTier(
    level: 'GOLD',
    label: 'Vàng',
    minPoints: 300,
    discountPercent: 7,
  ),
  eligibilityMessage: '',
  isHighestTier: false,
  pointsPerOrder: pointsPerOrder,
);

void main() {
  test('one point per pointsPerOrder VND, rounded down (server rule)', () {
    // bakery-web: Math.floor(orderTotal / pointsPerOrder), default 10000.
    final benefits = _benefits(10000);

    expect(benefits.pointsFor(790500), 79);
    expect(benefits.pointsFor(9999), 0);
    expect(benefits.pointsFor(10000), 1);
  });

  test('follows an admin-changed rate', () {
    expect(_benefits(5000).pointsFor(790500), 158);
  });

  test('a non-positive rate earns nothing instead of dividing by zero', () {
    expect(_benefits(0).pointsFor(790500), 0);
  });
}

/// Allowed order-status transitions, mirroring the server's
/// `ORDER_STATUS_TRANSITIONS` map (`bakery-web/app/api/admin/orders/[id]/route.ts`).
/// `COMPLETED` and `CANCELLED` are terminal and therefore have no entry —
/// the server still re-validates every transition.
const Map<String, List<String>> orderStatusTransitions = <String, List<String>>{
  'PENDING': <String>['CONFIRMED', 'CANCELLED'],
  'CONFIRMED': <String>['PROCESSING', 'CANCELLED'],
  'PROCESSING': <String>['READY'],
  'READY': <String>['COMPLETED'],
};

/// Statuses the given [current] order status may move to; terminal and
/// unknown statuses yield an empty list.
List<String> nextStatuses(String current) =>
    orderStatusTransitions[current] ?? const <String>[];

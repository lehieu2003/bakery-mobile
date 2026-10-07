import 'package:bakery_mobile/src/features/admin/orders/domain/models/admin_order.dart';

/// One entry of an order's audit trail as exposed by
/// `GET /api/admin/orders/{id|orderNumber}/audit`. Before/after payloads
/// and the raw actor account are intentionally not modeled — the admin UI
/// only renders the actor, mutation kind, metadata note/transition and
/// timestamp.
class OrderAuditLog {
  const OrderAuditLog({
    required this.id,
    this.actorName,
    this.actorRole,
    required this.mutationType,
    this.metadata,
    required this.createdAt,
  });

  final String id;

  /// Display name of the acting account; null when the mutation was made
  /// without an account (payment callbacks, system jobs) — the UI renders
  /// a 'System' fallback in that case.
  final String? actorName;

  /// Role of the actor, e.g. `ADMIN`; null when there was no acting account.
  final String? actorRole;

  /// Kind of mutation, e.g. `STATUS_UPDATE` or `PAYMENT_CALLBACK`.
  final String mutationType;

  /// Free-form extra data, e.g. `{note, transition: 'PENDING->CONFIRMED'}`.
  final Map<String, dynamic>? metadata;
  final DateTime createdAt;
}

/// Result of `GET /api/admin/orders/{id|orderNumber}/investigation`: an
/// order summary plus payment forensics. The endpoint's raw `auditTrail`
/// is intentionally not modeled — the UI reads the paginated audit endpoint
/// instead — and both timeline lists are sliced in the UI layer.
class OrderInvestigation {
  const OrderInvestigation({
    required this.orderNumber,
    required this.orderStatus,
    this.payment,
    required this.callbackEvents,
    required this.attempts,
  });

  final String orderNumber;

  /// Lifecycle status of the investigated order, e.g. `PENDING`.
  final String orderStatus;

  /// Recorded payment, if one exists yet (null for unpaid/CASH orders).
  final AdminPayment? payment;

  /// Provider callback timeline, newest entries included by the server;
  /// the UI shows only the first 10.
  final List<OrderCallbackEvent> callbackEvents;

  /// Reconciliation attempts for callbacks that could not be applied;
  /// the UI shows only the first 10.
  final List<OrderReconciliationAttempt> attempts;
}

/// One provider callback received for the investigated order.
class OrderCallbackEvent {
  const OrderCallbackEvent({
    required this.id,
    required this.provider,
    required this.event,
    this.incomingStatus,
    this.existingStatus,
    this.outcome,
    this.reason,
    required this.createdAt,
  });

  final String id;

  /// e.g. `VNPAY`.
  final String provider;

  /// e.g. `processed` — the provider event type.
  final String event;

  /// Status the provider reported; null when it sent none.
  final String? incomingStatus;

  /// Status the order already had when the callback arrived.
  final String? existingStatus;

  /// How the callback was handled, e.g. `APPLIED`.
  final String? outcome;

  /// Why the callback was skipped/failed; null when applied cleanly.
  final String? reason;
  final DateTime createdAt;
}

/// One reconciliation pass over a stored callback event.
class OrderReconciliationAttempt {
  const OrderReconciliationAttempt({
    required this.callbackEventId,
    required this.provider,
    required this.outcome,
    this.incomingStatus,
    required this.createdAt,
  });

  /// The [OrderCallbackEvent.id] this attempt re-processed.
  final String callbackEventId;
  final String provider;

  /// Result of the attempt, e.g. `MATCHED`.
  final String outcome;

  /// Status the callback carried, when known.
  final String? incomingStatus;
  final DateTime createdAt;
}

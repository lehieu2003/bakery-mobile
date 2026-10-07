import 'package:bakery_mobile/src/core/di/app_providers.dart';
import 'package:bakery_mobile/src/core/di/data_providers.dart';
import 'package:bakery_mobile/src/core/network/api_client.dart';
import 'package:bakery_mobile/src/core/network/api_exception.dart';
import 'package:bakery_mobile/src/features/auth/domain/models/user.dart';
import 'package:bakery_mobile/src/features/auth/presentation/controllers/auth_view_model.dart';
import 'package:bakery_mobile/src/features/reviews/data/datasources/reviews_api_service.dart';
import 'package:bakery_mobile/src/features/reviews/data/repositories/reviews_repository.dart';
import 'package:bakery_mobile/src/features/reviews/presentation/widgets/product_reviews_section.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

/// In-memory fake mirroring `/api/products/{id}/reviews`: per-product
/// review lists, GET counters, capturable submit bodies, and injectable
/// error responses.
class _FakeReviewsApiService extends ReviewsApiService {
  _FakeReviewsApiService()
    : super(
        ApiClient(baseUrl: 'http://localhost:1', tokenProvider: () async => null),
      );

  final Map<String, List<Map<String, dynamic>>> _reviews = {
    'p-1': [
      {
        'id': 'r-1',
        'userId': 'u-1',
        'productId': 'p-1',
        'rating': 5,
        'comment': 'Ngon',
        'createdAt': '2026-10-01T08:00:00.000Z',
        'user': {'id': 'u-1', 'name': 'Nguyễn Văn A'},
      },
    ],
    'p-2': [
      {
        'id': 'r-2',
        'userId': 'u-2',
        'productId': 'p-2',
        'rating': 4,
        'comment': 'Bánh tươi',
        'createdAt': '2026-10-02T08:00:00.000Z',
        'user': {'id': 'u-2', 'name': 'Trần Thị B'},
      },
    ],
    'p-empty': [],
  };

  /// Number of GET list calls per product — used to prove there is no
  /// reload loop when two sections are mounted at once.
  final Map<String, int> getCalls = {};
  final List<Map<String, dynamic>> submitCalls = [];

  /// Errors thrown by the next submit for the given product.
  final Map<String, Object> submitErrors = {};

  @override
  Future<Map<String, dynamic>> getReviews(
    String productId, {
    int limit = 50,
  }) async {
    getCalls[productId] = (getCalls[productId] ?? 0) + 1;
    final reviews = _reviews[productId] ?? const <Map<String, dynamic>>[];
    return {
      'reviews': reviews.map((entry) => Map<String, dynamic>.from(entry)).toList(),
      'pagination': {'page': 1, 'limit': limit, 'total': reviews.length},
    };
  }

  @override
  Future<Map<String, dynamic>> submitReview(
    String productId, {
    required int rating,
    String? comment,
  }) async {
    submitCalls.add({'productId': productId, 'rating': rating, 'comment': comment});
    final error = submitErrors.remove(productId);
    if (error != null) throw error;

    final review = <String, dynamic>{
      'id': 'r-new-${submitCalls.length}',
      'userId': 'u-1',
      'productId': productId,
      'rating': rating,
      'comment': comment,
      'createdAt': '2026-10-03T08:00:00.000Z',
      'user': {'id': 'u-1', 'name': 'Nguyễn Văn A'},
    };
    _reviews.putIfAbsent(productId, () => []).add(review);
    return Map<String, dynamic>.from(review);
  }
}

class _FakeAuthViewModel extends AuthViewModel {
  @override
  AuthState build() => const AuthState(
    user: User(id: 'u-1', email: 'test@bakery.vn', role: 'CUSTOMER'),
  );
}

void main() {
  group('ReviewsViewModel (family by productId)', () {
    late ProviderContainer container;
    late _FakeReviewsApiService datasource;

    setUp(() {
      datasource = _FakeReviewsApiService();
      container = ProviderContainer(
        overrides: [
          reviewsRepositoryProvider.overrideWith(
            (ref) => ReviewsRepository(datasource),
          ),
        ],
      );
      addTearDown(container.dispose);
    });

    test('stacked products keep independent state and load exactly once each',
        () async {
      final notifierA = container.read(
        reviewsViewModelProvider('p-1').notifier,
      );
      final notifierB = container.read(
        reviewsViewModelProvider('p-2').notifier,
      );

      await notifierA.load();
      await notifierB.load();

      final stateA = container.read(reviewsViewModelProvider('p-1'));
      final stateB = container.read(reviewsViewModelProvider('p-2'));

      expect(stateA.reviews.single.comment, 'Ngon');
      expect(stateA.reviewCount, 1);
      expect(stateB.reviews.single.comment, 'Bánh tươi');
      expect(stateB.reviewCount, 1);

      // Each product fetched exactly once — a second screen loading must
      // not trigger reloads on the first one (no ping-pong).
      expect(datasource.getCalls, {'p-1': 1, 'p-2': 1});
    });

    test('load failure is isolated to that product only', () async {
      final failing = _FailingGetService();
      final failingContainer = ProviderContainer(
        overrides: [
          reviewsRepositoryProvider.overrideWith(
            (ref) => ReviewsRepository(failing),
          ),
        ],
      );
      addTearDown(failingContainer.dispose);

      await failingContainer
          .read(reviewsViewModelProvider('p-err').notifier)
          .load();

      final failingState = failingContainer.read(
        reviewsViewModelProvider('p-err'),
      );
      expect(failingState.isLoading, isFalse);
      expect(failingState.error, 'Network error');
      expect(failingState.reviews, isEmpty);

      // Another family instance (main container, healthy datasource)
      // is untouched and still loads normally.
      await container.read(reviewsViewModelProvider('p-1').notifier).load();
      expect(
        container.read(reviewsViewModelProvider('p-1')).error,
        isNull,
      );
    });

    test('submit adds the review and reloads only that product', () async {
      final notifier = container.read(
        reviewsViewModelProvider('p-empty').notifier,
      );
      await notifier.load();
      expect(datasource.getCalls['p-empty'], 1);

      final submitted = await notifier.submit(rating: 5, comment: 'Rất ngon');

      expect(submitted, isTrue);
      expect(datasource.submitCalls.single['productId'], 'p-empty');
      expect(datasource.submitCalls.single, {
        'productId': 'p-empty',
        'rating': 5,
        'comment': 'Rất ngon',
      });
      expect(
        container.read(reviewsViewModelProvider('p-empty')).reviews.single.comment,
        'Rất ngon',
      );
      // Exactly one silent reload after the submit.
      expect(datasource.getCalls['p-empty'], 2);
      // Other products untouched.
      expect(datasource.getCalls.containsKey('p-1'), isFalse);
    });

    test('409 duplicate maps to the dedicated message', () async {
      datasource.submitErrors['p-1'] = ApiException(
        'Duplicate review',
        statusCode: 409,
      );
      final notifier = container.read(
        reviewsViewModelProvider('p-1').notifier,
      );

      final submitted = await notifier.submit(rating: 4);

      expect(submitted, isFalse);
      expect(
        container.read(reviewsViewModelProvider('p-1')).submitError,
        'Bạn đã đánh giá sản phẩm này',
      );
    });

    test('401 maps to the login hint', () async {
      datasource.submitErrors['p-1'] = ApiException(
        'Unauthorized',
        statusCode: 401,
      );
      final notifier = container.read(
        reviewsViewModelProvider('p-1').notifier,
      );

      await notifier.submit(rating: 4);

      expect(
        container.read(reviewsViewModelProvider('p-1')).submitError,
        'Vui lòng đăng nhập để đánh giá sản phẩm',
      );
    });
  });

  group('ProductReviewsSection (two PDPs stacked)', () {
    testWidgets('renders both products without reload ping-pong',
        (tester) async {
      final datasource = _FakeReviewsApiService();

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            reviewsRepositoryProvider.overrideWithValue(
              ReviewsRepository(datasource),
            ),
            authViewModelProvider.overrideWith(_FakeAuthViewModel.new),
          ],
          child: const MaterialApp(
            home: Scaffold(
              body: SingleChildScrollView(
                child: Column(
                  children: [
                    // Mirrors two stacked PDPs: both subtrees stay mounted
                    // (Navigator keeps the covered screen alive), each
                    // screen triggers exactly one load on mount.
                    _FakePdp(productId: 'p-1', key: ValueKey('s1')),
                    _FakePdp(productId: 'p-2', key: ValueKey('s2')),
                    _FakePdp(productId: 'p-empty', key: ValueKey('s3')),
                  ],
                ),
              ),
            ),
          ),
        ),
      );

      // A reload ping-pong between mounted sections would keep scheduling
      // frames forever; a bounded settle proves the loop is gone.
      await tester.pumpAndSettle(
        const Duration(milliseconds: 50),
        EnginePhase.sendSemanticsUpdate,
        const Duration(seconds: 3),
      );

      expect(
        datasource.getCalls,
        {'p-1': 1, 'p-2': 1, 'p-empty': 1},
        reason: 'each mounted section loads its own reviews exactly once',
      );

      // Stay idle for a while — no background reloads may start.
      await tester.pump(const Duration(seconds: 2));
      await tester.pumpAndSettle(
        const Duration(milliseconds: 50),
        EnginePhase.sendSemanticsUpdate,
        const Duration(seconds: 3),
      );
      expect(
        datasource.getCalls,
        {'p-1': 1, 'p-2': 1, 'p-empty': 1},
      );

      // Each section shows its own product's data.
      expect(find.text('Ngon'), findsOneWidget);
      expect(find.text('Nguyễn Văn A'), findsOneWidget);
      expect(find.text('Bánh tươi'), findsOneWidget);
      expect(find.text('Trần Thị B'), findsOneWidget);
      expect(find.text('Chưa có đánh giá nào.'), findsOneWidget);
    });
  });
}

/// Stand-in for the product detail screen: mounts a reviews section and
/// triggers a single load, exactly like
/// `ProductDetailScreen._load()` does after the product resolves.
class _FakePdp extends ConsumerStatefulWidget {
  const _FakePdp({required this.productId, super.key});

  final String productId;

  @override
  ConsumerState<_FakePdp> createState() => _FakePdpState();
}

class _FakePdpState extends ConsumerState<_FakePdp> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        ref.read(reviewsViewModelProvider(widget.productId).notifier).load();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return ProductReviewsSection(productId: widget.productId);
  }
}

class _FailingGetService extends ReviewsApiService {
  _FailingGetService()
    : super(
        ApiClient(baseUrl: 'http://localhost:1', tokenProvider: () async => null),
      );

  @override
  Future<Map<String, dynamic>> getReviews(
    String productId, {
    int limit = 50,
  }) async {
    throw Exception('Network error');
  }
}

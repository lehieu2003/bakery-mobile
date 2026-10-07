# Mobile Admin — Phase 0 + 1 (Foundation & Dashboard) Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Đăng nhập ADMIN trên mobile vào `AdminShell` (drawer 15 mục + logout) và Dashboard hoạt động đầy đủ (KPI, 2 biểu đồ area, đơn mới nhất, đổi window, polling 5 phút).

**Architecture:** Tái dùng kiến trúc hiện có — `ApiClient` (Bearer + envelope unwrap), Riverpod `Notifier`, template feature `data/{datasources,dtos,repositories} → domain/models → presentation/{controllers,screens,widgets}`. Admin là feature mới `lib/src/features/admin/**`; `AppGate` phân nhánh theo `user.role`; các nhánh customer không đổi.

**Tech Stack:** Flutter 3.32.4 (fvm), flutter_riverpod 2.x, http, thêm `intl` + `fl_chart`.

**Spec:** `docs/superpowers/specs/2026-10-07-mobile-admin-design.md` — đọc song song; plan này chỉ cover Phase 0 + 1. Ghi chú: spec Phase 0 ghi "thêm packages" — plan này thêm `intl` (Task 3) và `fl_chart` (Task 6) khi có consumer; `image_picker`/`pdf`/`printing`/`share_plus` sẽ thêm trong plan phase 2/4 (YAGNI).

## Global Constraints

- Mọi lệnh Flutter chạy qua **fvm**: `fvm flutter test`, `fvm flutter analyze`, `fvm flutter pub add ...`.
- Không sửa server (bakery-web); mọi endpoint đã sẵn sàng, auth bằng Bearer tự gắn từ `ApiClient`.
- Chỉ được sửa/created: `auth_view_model.dart` (xóa đúng 2 block gate), `app_gate.dart`, `pubspec.yaml`, `core/di/data_providers.dart`, `core/di/app_providers.dart`, file mới dưới `lib/src/features/admin/**`, file test mới. **Không đụng** thư mục feature customer (`catalog`, `cart`, `orders`, `profile`, `wishlist`, `addresses`, `notifications`, `reviews`, `blog`, `pages`, `chatbot`, `membership`, `auth` trừ auth_view_model, `navigation` trừ app_gate, `onboarding`).
- Chuỗi UI tiếng Việt hardcode inline (không l10n); theming qua `AppTheme` hiện có.
- DTO parse phòng thủ (nullable, số có thể đến dạng `num`/`String` — Decimal từ server luôn coerce `Number` phía web nên JSON có thể nhận cả string).
- Commit conventional (feat/test/chore), mỗi task 1+ commit.
- `fvm flutter analyze` phải 0 issues; test cũ (7 file) phải vẫn xanh.

## Review Focus

Các rủi ro spec ngầm hiểu nhưng không có task nào test trực tiếp — mỗi dòng đã được ghim vào task sở hữu:

1. **Admin bootstrap rơi vào shell customer** (bug token-leak hiện có: login admin bị chặn nhưng token vẫn lưu). Kỳ vọng: bootstrap với token admin hợp lệ → `AdminShell`, không bao giờ `MainLayout`. Ghim: Task 2, test T1.
2. **Regress luồng customer** khi sửa `AppGate`/auth. Kỳ vọng: CUSTOMER chưa xem onboarding → onboarding; đã xem → `MainLayout`; login customer vẫn OK. Ghim: Task 1 (test login customer) + Task 2 (test T2).
3. **Timer polling rò rỉ** (refresh 5 phút không hủy khi VM.dispose → refresh chồng nhau). Kỳ vọng: sau dispose, không còn timer bắn. Ghim: Task 5, test polling với `fakeAsync`.
4. **Số tiền đến dạng string** (Prisma Decimal serialize) làm KPI/đơn hàng hiển thị sai. Kỳ vọng: `'1250000'` parse thành 1250000. Ghim: Task 4, test parse.
5. **Drawer thiếu/sai nhãn mục** so với 15 mục web → mục không điều hướng được. Ghim: Task 2, test T3 đếm đúng 15 tiêu đề.

---

### Task 1: Bỏ gate CUSTOMER trong AuthViewModel

**Files:**
- Modify: `lib/src/features/auth/presentation/controllers/auth_view_model.dart` (xóa block `if (!user.isCustomer)` tại dòng 61-63 trong `login()` và 91-93 trong `verifyRegister()`)
- Test: `test/auth_view_model_test.dart` (mới)

**Interfaces:**
- Consumes: `AuthViewModel` hiện có (`login({required String email, required String password}) → Future<bool>`, `verifyRegister(...)`, `AuthState.user`), `authRepositoryProvider` (`data_providers.dart:83`), `AuthRepository({required TokenStorage tokenStorage, required AuthApiService authApiService})`, `User({required id, email, role, name, phone, memberLevel, points})`.
- Produces: không đổi API — chỉ bỏ ràng buộc role. Task 2 dựa vào việc login admin đặt `state.user` (role `'ADMIN'`).

- [ ] **Step 1: Write the failing test** — `test/auth_view_model_test.dart`:

```dart
// Fake pattern như test/reviews_controller_test.dart: subclass + override,
// SharedPreferences.setMockInitialValues({}) trong setUp() (TokenStorage dùng SharedPreferences).
class _FakeAuthRepository extends AuthRepository {
  _FakeAuthRepository(this._user)
    : super(
        tokenStorage: TokenStorage(),
        authApiService: AuthApiService(
          ApiClient(baseUrl: 'http://localhost:1', tokenProvider: () async => null),
        ),
      );

  final User _user;

  @override
  Future<User> login({required String email, required String password}) async => _user;

  @override
  Future<User> registerVerify({
    required String email,
    required String otp,
    required String password,
    String? name,
  }) async => _user;
}

User _user(String role) => User(id: 'u-1', email: 'test@bakery.vn', role: role);

// 3 test:
// 1) login với repo trả role 'ADMIN' → trả true, container.read(authViewModelProvider).user!.role == 'ADMIN' (hiện FAIL: ném "Mobile app only supports CUSTOMER accounts")
// 2) verifyRegister với role 'ADMIN' → true, state.user set (hiện FAIL cùng lỗi)
// 3) login với role 'CUSTOMER' → true, state.user set (regression — phải pass cả trước lẫn sau fix)
```

Dùng `ProviderContainer(overrides: [authRepositoryProvider.overrideWithValue(fake)])`, `addTearDown(container.dispose)`.

- [ ] **Step 2: Run** `fvm flutter test test/auth_view_model_test.dart` — Expected: test 1 & 2 FAIL ("Mobile app only supports CUSTOMER accounts"), test 3 PASS.
- [ ] **Step 3: Implement** — xóa đúng 2 block `if (!user.isCustomer) { throw ... }` (giữ nguyên mọi thứ khác).
- [ ] **Step 4: Run** lại — Expected: 3/3 PASS.
- [ ] **Step 5: Commit**

```bash
git add lib/src/features/auth/presentation/controllers/auth_view_model.dart test/auth_view_model_test.dart
git commit -m "feat(admin): allow ADMIN login in mobile auth flow"
```

---

### Task 2: AdminShell + AppGate phân nhánh theo role

**Files:**
- Create: `lib/src/features/admin/shell/domain/admin_section.dart`
- Create: `lib/src/features/admin/shell/presentation/screens/admin_shell.dart`
- Create: `lib/src/features/admin/shell/presentation/screens/admin_placeholder_screen.dart`
- Modify: `lib/src/features/navigation/presentation/screens/app_gate.dart`
- Test: `test/admin_shell_test.dart` (mới)

**Interfaces:**
- Consumes: `authViewModelProvider` (`AuthState.user` — `User.name`/`email`; `logout()`), `onboardingViewModelProvider`, widget `MainLayout`/`OnboardingScreen`/`AuthLayout` (chỉ trong test assert), `AppTheme`.
- Produces (phase sau phụ thuộc):
  - `enum AdminSection { dashboard, orders, customers, coupons, products, categories, productAttributes, membership, banners, notifications, blog, pages, menu, audit, settings }` (đúng 15 giá trị) + `enum AdminSectionGroup { overview, sales, store, content, system }` + extension trên `AdminSection`: `String get vietnameseTitle`, `AdminSectionGroup get group`, `IconData get icon`.
  - Nhãn Việt (ghim cứng, thứ tự nhóm như web sidebar): Tổng quan · Đơn hàng, Khách hàng, Coupon · Sản phẩm, Danh mục, Bộ lọc sản phẩm, Thành viên, Banner · Blog, Trang tĩnh, Thông báo, Menu · Nhật ký hệ thống, Cài đặt.
  - `class AdminShell extends ConsumerStatefulWidget` — AppBar tiêu đề = section hiện tại, action avatar `PopupMenuButton` (item "Đăng xuất" → `ref.read(authViewModelProvider.notifier).logout()`), `Drawer` nhóm theo `AdminSectionGroup` (header chữ nhóm + `ListTile` từng mục, footer tên + email user), body = nested `Navigator` (GlobalKey) với root là màn của section; Task 6 sẽ thay builder của `dashboard` (hiện tại mọi section → `AdminPlaceholderScreen`).
  - `class AdminPlaceholderScreen extends StatelessWidget { const AdminPlaceholderScreen(this.title); }` — giữa màn: "Mục «title» sắp ra mắt".
- `AppGate` chèn branch (trước check onboarding — admin không cần onboarding):
```dart
final user = authState.user;
if (authState.isAuthenticated && user?.role == 'ADMIN') {
  return const AdminShell();
}
```
Giữ nguyên thứ tự còn lại: onboarding → `MainLayout` → `AuthLayout`.

- [ ] **Step 1: Write the failing test** — `test/admin_shell_test.dart`:

```dart
class _FakeAdminAuthViewModel extends AuthViewModel {
  bool logoutCalled = false;
  @override
  AuthState build() => const AuthState(
    user: User(id: 'a-1', email: 'admin@bakery.vn', name: 'Hieu', role: 'ADMIN'),
  );
  @override
  Future<void> bootstrap() async {}
  @override
  Future<void> logout() async {
    logoutCalled = true;
    state = state.copyWith(clearUser: true);
  }
}
// Tương tự: _FakeCustomerAuthViewModel (role 'CUSTOMER'), _FakeOnboardingViewModel
// (constructor nhận hasSeenOnboarding, bootstrap() no-op).

// T1 (ghim Review Focus 1): ProviderScope overrides {authViewModel: _FakeAdminAuthViewModel,
// onboardingViewModel: hasSeenOnboarding=false} pump AppGate trong MaterialApp,
// pump(const Duration(milliseconds: 1300)) qua delay gate →
//   expect(find.byType(AdminShell), findsOneWidget);
//   expect(find.byType(OnboardingScreen), findsNothing);
//   expect(find.byType(MainLayout), findsNothing);
// T2 (Review Focus 2): CUSTOMER + hasSeen=false → OnboardingScreen; CUSTOMER + hasSeen=true → MainLayout.
// T3 (Review Focus 5): pump AdminShell trực tiếp (MaterialApp(home: AdminShell)) →
//   mở Drawer (tap icon menu) → 15 tiêu đề trên đều findsOneWidget +
//   5 header nhóm ('Tổng quan','Bán hàng','Cửa hàng','Nội dung','Hệ thống') →
//   tap ListTile 'Đơn hàng' → find.text('Mục "Đơn hàng" sắp ra mắt') (nested navigator) +
//   AppBar title đổi thành 'Đơn hàng'.
// T4: tap avatar action → tap 'Đăng xuất' → fake.logoutCalled == true.
```

- [ ] **Step 2: Run** `fvm flutter test test/admin_shell_test.dart` — Expected: FAIL (`AdminShell` chưa tồn tại — tạo skeleton class rỗng trước để test compile nếu cần).
- [ ] **Step 3: Implement** `admin_section.dart`, `admin_placeholder_screen.dart`, `admin_shell.dart`, sửa `app_gate.dart` như Interfaces trên. Shell dùng `StatefulWidget` giữ `_currentSection` (mặc định `AdminSection.dashboard`) + `_navigatorKey`; chọn ListTile → `setState` + thay root nested navigator (`_navigatorKey.currentState?.pushAndRemoveUntil(...)` hoặc rebuild `Navigator(onGenerateRoute: ...)` với key mới theo section — chọn 1 cách, miêu tả trong comment đầu file).
- [ ] **Step 4: Run** lại — Expected: 4/4 PASS. Sau đó `fvm flutter test` toàn bộ — Expected: PASS (không regress).
- [ ] **Step 5: Commit**

```bash
git add lib/src/features/admin/shell lib/src/features/navigation/presentation/screens/app_gate.dart test/admin_shell_test.dart
git commit -m "feat(admin): role-based AppGate + AdminShell with 15-section drawer"
```

---

### Task 3: Shared admin — StatusPill + format tiền/ngày (intl)

**Files:**
- Modify: `pubspec.yaml` (thêm `intl` qua `fvm flutter pub add intl`)
- Create: `lib/src/features/admin/shared/utils/admin_format.dart`
- Create: `lib/src/features/admin/shared/domain/order_status_display.dart`
- Create: `lib/src/features/admin/shared/presentation/widgets/status_pill.dart`
- Test: `test/admin_shared_format_test.dart` (mới)

**Interfaces:**
- Consumes: không (nền tảng).
- Produces (Task 6 + phase sau dùng):
  - `String formatVnd(num amount)` — `NumberFormat.currency(locale: 'vi_VN', decimalDigits: 0, symbol: '₫')`.
  - `String formatDateVi(DateTime date)` — `dd/MM/yyyy`; `String formatDateTimeVi(DateTime date)` — `dd/MM/yyyy HH:mm`.
  - `String orderStatusLabel(String status)` — map ghim: `PENDING→'Chờ xác nhận'`, `CONFIRMED→'Đã xác nhận'`, `PROCESSING→'Đang chuẩn bị'`, `READY→'Sẵn sàng nhận'`, `COMPLETED→'Hoàn thành'`, `CANCELLED→'Đã huỷ'`; mã lạ → trả nguyên mã.
  - `Color orderStatusColor(String status)` — nền pill (loại màu `Color(0xFFFFF7ED)`-style): `PENDING→0xFFFFF7E6`, `CONFIRMED→0xFFEFF6FF`, `PROCESSING→0xFFFFF7ED`, `READY→0xFFF0FDFA`, `COMPLETED→0xFFF0FDF4`, `CANCELLED→0xFFFEF2F2`; mã lạ → `const Color(0xFFF3F4F6)`.
  - `Color orderStatusTextColor(String status)` — `PENDING→0xFFB45309`, `CONFIRMED→0xFF1D4ED8`, `PROCESSING→0xFFC2410C`, `READY→0xFF0F766E`, `COMPLETED→0xFF15803D`, `CANCELLED→0xFFB91C1C`; lạ → `const Color(0xFF4B5563)`.
  - `class StatusPill extends StatelessWidget { const StatusPill({super.key, required this.status}); }` — `Container` bo tròn (nền `orderStatusColor`), padding 6/10, `Text(orderStatusLabel(status), màu orderStatusTextColor, fontSize 12, w600)`.

- [ ] **Step 1: Write the failing test** — `test/admin_shared_format_test.dart`:
```dart
// formatVnd(1250000) == '1.250.000 ₫'; formatVnd(0) == '0 ₫'
// formatDateVi(DateTime(2026, 10, 7)) == '07/10/2026'
// formatDateTimeVi(DateTime(2026, 10, 7, 14, 30)) == '07/10/2026 14:30'
// orderStatusLabel: đủ 6 mã khớp nhãn trên; orderStatusLabel('WEIRD') == 'WEIRD'
// orderStatusColor('PENDING') == const Color(0xFFFFF7E6); orderStatusTextColor('CANCELLED') == const Color(0xFFB91C1C)
// Widget test: pump MaterialApp(home: Scaffold(body: StatusPill(status: 'PENDING'))) → find.text('Chờ xác nhận')
```
- [ ] **Step 2: Run** — Expected: FAIL (hàm/chưa tồn tại).
- [ ] **Step 3: Implement** đúng Interfaces trên.
- [ ] **Step 4: Run** — Expected: PASS.
- [ ] **Step 5: Commit** — `git commit -m "feat(admin): shared status pill + vi-VN money/date formatters"`

---

### Task 4: Dashboard data layer (service + DTO/model + repository)

**Files:**
- Create: `lib/src/features/admin/dashboard/data/datasources/dashboard_api_service.dart`
- Create: `lib/src/features/admin/dashboard/data/dtos/dashboard_dto.dart`
- Create: `lib/src/features/admin/dashboard/data/repositories/dashboard_repository.dart`
- Create: `lib/src/features/admin/dashboard/domain/models/dashboard_stats.dart`
- Modify: `lib/src/core/di/data_providers.dart` (thêm 2 provider cuối file)
- Test: `test/dashboard_dto_test.dart` (mới)

**Interfaces:**
- Consumes: `ApiClient` (`get(String path, {Map<String, dynamic>? query})` — unwrap envelope sẵn).
- Produces (Task 5/6 phụ thuộc):
  - `class DashboardApiService { const DashboardApiService(ApiClient client); Future<Map<String, dynamic>> getDashboard({int windowDays = 7}) }` → `_client.get('/api/admin/dashboard', query: {'windowDays': windowDays})` cast `Map<String, dynamic>`.
  - Models (domain, immutable const constructor): `DashboardStats{kpi: DashboardKpi, chartData: List<DashboardChartPoint>, orderStates: List<OrderStateCount>, recentOrders: List<DashboardRecentOrder>, meta: DashboardMeta}`; `DashboardKpi{todayOrders:int, todayRevenue:double, pendingOrders:int, totalCustomers:int, totalProducts:int, periodOrders:int, periodCompletedOrders:int, periodCancelledOrders:int, conversionRate:double}`; `DashboardChartPoint{day:String, orders:int, revenue:double, completedOrders:int, cancelledOrders:int}`; `OrderStateCount{status:String, count:int}`; `DashboardRecentOrder{id:String, orderNumber:String, customerName:String, total:double, status:String, createdAt:DateTime, itemsCount:int}`; `DashboardMeta{windowDays:int, refreshIntervalSeconds:int}` (shape ghim từ `bakery-web/types/api.types.ts:493`).
  - `DashboardStatsDto.fromJson(Map<String, dynamic>)` + `toDomain()` — mọi số qua helper `_asNum(dynamic)` chấp nhận `num`/`String` (Review Focus 4); `createdAt` qua `DateTime.tryParse(...) ?? DateTime.now()` (pattern `review_dto.dart`); `meta` vắng mặt → `DashboardMeta(windowDays: 0, refreshIntervalSeconds: 300)`.
  - `class DashboardRepository { const DashboardRepository(DashboardApiService service); Future<DashboardStats> getStats({int windowDays = 7}) }`.
  - Providers `dashboardApiServiceProvider`, `dashboardRepositoryProvider` trong `data_providers.dart` (pattern y như `reviewsApiServiceProvider`).

- [ ] **Step 1: Write the failing test** — `test/dashboard_dto_test.dart` với JSON mẫu ghim:

```dart
const sample = {
  'kpi': {
    'todayOrders': 12, 'todayRevenue': '1250000', // string — ghim coercion
    'pendingOrders': 3, 'totalCustomers': 48, 'totalProducts': 46,
    'periodOrders': 96, 'periodCompletedOrders': 81, 'periodCancelledOrders': 4,
    'conversionRate': 3.2,
  },
  'chartData': [
    {'day': '2026-10-06', 'orders': 9, 'revenue': 890000, 'completedOrders': 7, 'cancelledOrders': 1},
    {'day': '2026-10-07', 'orders': 12, 'revenue': '1250000', 'completedOrders': 9, 'cancelledOrders': 0},
  ],
  'orderStates': [
    {'status': 'PENDING', 'count': 3},
    {'status': 'COMPLETED', 'count': 81},
  ],
  'recentOrders': [
    {'id': 'o-1', 'orderNumber': 'PL-1042', 'customerName': 'Nguyễn Văn A',
     'total': '250000', 'status': 'PENDING', 'createdAt': '2026-10-07T09:30:00.000Z', 'itemsCount': 2},
  ],
  'meta': {'windowDays': 7, 'refreshIntervalSeconds': 300},
};
// Test 1: parse sample → todayRevenue == 1250000.0 (double, từ string),
//   chartData[1].revenue == 1250000.0, recentOrders[0].total == 250000.0,
//   conversionRate == 3.2, recentOrders[0].createdAt == DateTime.utc(2026,10,7,9,30).
// Test 2: `{}` rỗng → kpi toàn 0, chartData/orderStates/recentOrders rỗng,
//   meta.windowDays == 0, meta.refreshIntervalSeconds == 300 (default).
// Test 3: toDomain() giữ nguyên giá trị (spot-check 3 field).
```

- [ ] **Step 2: Run** `fvm flutter test test/dashboard_dto_test.dart` — Expected: FAIL (chưa tồn tại).
- [ ] **Step 3: Implement** service + DTO + model + repository + 2 provider.
- [ ] **Step 4: Run** — Expected: PASS.
- [ ] **Step 5: Commit** — `git commit -m "feat(admin): dashboard stats data layer"`

---

### Task 5: DashboardViewModel (fetch + đổi window + polling 5 phút)

**Files:**
- Create: `lib/src/features/admin/dashboard/presentation/controllers/dashboard_view_model.dart`
- Modify: `lib/src/core/di/app_providers.dart` (thêm `dashboardViewModelProvider`)
- Test: `test/dashboard_view_model_test.dart` (mới)

**Interfaces:**
- Consumes: `dashboardRepositoryProvider` (Task 4), `ApiException`.
- Produces (Task 6 phụ thuộc):
  - `class DashboardState { const DashboardState({this.stats, this.isLoading = false, this.error, this.windowDays = 7}); ... copyWith({stats, clearStats, isLoading, error, clearError, windowDays}) }`
  - `class DashboardViewModel extends Notifier<DashboardState>`:
    - `Future<void> load()` — fetch `getStats(windowDays: state.windowDays)`; đang load → `isLoading: true`; lỗi `ApiException` → `error` = message, `clearStats` giữ false; xong → `isLoading: false`.
    - `Future<void> setWindow(int windowDays)` — set `windowDays` rồi `load()`.
    - `void startAutoRefresh()` — `Timer.periodic(const Duration(seconds: 300), (_) => load())`; gọi lần 2 phải hủy timer cũ trước (chỉ 1 timer sống); `ref.onDispose` hủy timer.
  - `final dashboardViewModelProvider = NotifierProvider<DashboardViewModel, DashboardState>(DashboardViewModel.new);`

- [ ] **Step 1: Write the failing test** — `test/dashboard_view_model_test.dart`:

```dart
// _FakeDashboardApiService extends DashboardApiService (super ApiClient như pattern reviews):
//   đếm calls (List<int> windowDaysSeen), trả raw JSON Task 4, injectable Object? error.
// _FakeDashboardRepository extends DashboardRepository (super với fake service).
// Overrides: dashboardRepositoryProvider.overrideWithValue(fake).

// T1: load() → state.stats != null && isLoading == false && windowDaysSeen == [7].
// T2: await setWindow(14) → windowDaysSeen.last == 14 && state.windowDays == 14.
// T3: error = ApiException('boom') → load() → state.error == 'boom' && state.stats == null.
// T4 (ghim Review Focus 3) — fakeAsync((async) {
//   final c = ProviderContainer(overrides: [...]); final vm = c.read(dashboardViewModelProvider.notifier);
//   vm.startAutoRefresh(); async.elapse(const Duration(minutes: 10));
//   expect(service.calls, greaterThanOrEqualTo(2));   // 2 tick trong 10 phút
//   c.dispose(); final before = service.calls; async.elapse(const Duration(minutes: 5));
//   expect(service.calls, before);                    // timer đã hủy sau dispose
// });
//   và test riêng: gọi startAutoRefresh() 2 lần → elapse 10 phút → calls không nhân đôi.
```

- [ ] **Step 2: Run** — Expected: FAIL.
- [ ] **Step 3: Implement** theo Interfaces.
- [ ] **Step 4: Run** — Expected: PASS.
- [ ] **Step 5: Commit** — `git commit -m "feat(admin): dashboard view model with window switch + 5-min polling"`

---

### Task 6: Dashboard screen (KPI + fl_chart + đơn mới nhất) & cắm vào shell

**Files:**
- Modify: `pubspec.yaml` (`fvm flutter pub add fl_chart`)
- Create: `lib/src/features/admin/dashboard/presentation/screens/dashboard_screen.dart`
- Create: `lib/src/features/admin/dashboard/presentation/widgets/kpi_card.dart`
- Create: `lib/src/features/admin/dashboard/presentation/widgets/dashboard_charts.dart`
- Modify: `lib/src/features/admin/shell/presentation/screens/admin_shell.dart` (builder section `dashboard` → `DashboardScreen`, các section còn lại giữ placeholder)
- Test: `test/dashboard_screen_test.dart` (mới)

**Interfaces:**
- Consumes: `dashboardViewModelProvider` (Task 5), `formatVnd`/`formatDateVi`/`StatusPill` (Task 3), `AppTheme`.
- Produces: `class DashboardScreen extends ConsumerStatefulWidget` — initState post-frame: `load()` + `startAutoRefresh()`. UI dọc, `RefreshIndicator` + ListView: ① `SegmentedButton<int>` 3 segment `7 ngày/14 ngày/30 ngày` (value = `state.windowDays`, chọn → `setWindow`); ② lưới KPI 2×2 — "Đơn hôm nay" (`kpi.todayOrders`), "Doanh thu hôm nay" (`formatVnd(kpi.todayRevenue)`), "Tỷ lệ chuyển đổi" (`'${kpi.conversionRate.toStringAsFixed(1)}%'`), "Trạng thái đơn" (tổng hợp `orderStates` — hàng pill nhỏ `StatusPill` + count, chỉ hiện trạng thái count > 0); ③ `DashboardCharts` — 2 `LineChart` (fl_chart, `LineChartBarData` với `isCurved: true`, `belowBarData` gradient → dạng area) cao 180: "Số đơn theo ngày" (x = `chartData`, y = `orders`) và "Doanh thu theo ngày" (y = `revenue`); ④ "Đơn mới nhất" — tối đa 5 hàng từ `recentOrders`: `orderNumber` + `customerName` + `itemsCount` món, `formatVnd(total)`, `StatusPill(status)`, `formatDateVi(createdAt)`; tap hàng = no-op hiện tại (phase 2 nối detail — comment `// TODO(phase-2): push order detail`).
  - `class KpiCard extends StatelessWidget { const KpiCard({super.key, required this.label, required this.value, this.child}); }` — dùng `Card` theme hiện có.
- Trạng thái rỗng/lỗi: `error != null` → thông báo + nút "Thử lại" (`load()`); `stats == null && isLoading` → spinner giữa; `chartData.isEmpty` → placeholder "Chưa có dữ liệu" thay chart.

- [ ] **Step 1: Write the failing test** — `test/dashboard_screen_test.dart`:

```dart
// Overrides: dashboardRepositoryProvider → fake trả JSON Task 4 (kpi.todayOrders 12,
// todayRevenue 1250000, conversionRate 3.2, recentOrders[0] PL-1042/PENDING).
// T1: pump DashboardScreen trong MaterialApp + ProviderScope(overrides) → pumpAndSettle →
//   find.text('12'), find.text('1.250.000 ₫'), find.text('3.2%'), find.text('Đơn mới nhất').
// T2: tap segment '30 ngày' → await pump() → fake.windowDaysSeen.last == 30.
// T3 (Review Focus 4 ở tầng UI): find.text('Chờ xác nhận') (StatusPill recent order) findsOneWidget.
// T4: error state — fake.error = ApiException('boom') → find.text('Thử lại').
```

- [ ] **Step 2: Run** — Expected: FAIL.
- [ ] **Step 3: Implement** screen + widgets + wire vào `admin_shell.dart`.
- [ ] **Step 4: Run** — Expected: PASS. `fvm flutter test` toàn bộ PASS.
- [ ] **Step 5: Commit** — `git commit -m "feat(admin): dashboard screen with KPI, charts, recent orders"`

---

### Task 7: Verification sweep (không viết code mới)

**Files:** không có — chỉ chạy lệnh + kiểm tra thủ công.

- [ ] **Step 1:** `fvm flutter analyze` — Expected: **0 issues**.
- [ ] **Step 2:** `fvm flutter test` — Expected: toàn bộ PASS (7 file cũ + 6 file mới: auth_view_model, admin_shell, admin_shared_format, dashboard_dto, dashboard_view_model, dashboard_screen).
- [ ] **Step 3: Emulator smoke** (API bakery-web chạy port 3001 + `fvm flutter run` emulator-5554) — checklist:
  1. Login `admin@…` (tài khoản admin thật) → thấy `AdminShell`, KHÔNG onboarding.
  2. Drawer đủ 15 mục, 5 nhóm, footer tên/email admin.
  3. Dashboard: KPI khớp con số web `/admin/dashboard` (cùng window), 2 biểu đồ vẽ, đơn mới nhất hiện.
  4. Đổi window 7→30 → số `periodOrders`/biểu đồ đổi khớp web.
  5. Chờ/quan sát polling không chồng (để 5+ phút nếu tiện) — hoặc tin test T4 Task 5.
  6. Logout → về AuthScreen; login lại bằng CUSTOMER (linh@email.com) → onboarding/shell customer như cũ (Review Focus 2).
  7. Chụp screenshot từng bước vào `gui-test-screenshots/admin-phase1/`.
- [ ] **Step 4:** Nếu có fix — commit riêng `fix(admin): ...` rồi chạy lại Step 1-2. Không có fix → kết thúc phase.

---

## Sau phase này

Phase 2 (Đơn hàng) sẽ có plan riêng `2026-10-07-mobile-admin-phase-2-orders.md` viết trước khi triển khai — plan phase 2 cần: list scaffold dùng chung (thiết kế khi có consumer thật = orders), CSV + `share_plus`, PDF + `printing` + font TTF tiếng Việt, `PATCH` transition. Các phase 3-7 tương tự.

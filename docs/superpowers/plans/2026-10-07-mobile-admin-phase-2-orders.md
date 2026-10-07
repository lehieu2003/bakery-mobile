# Mobile Admin — Phase 2 (Đơn hàng) Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Mục "Đơn hàng" trên mobile admin đầy đủ: danh sách (tìm kiếm + lọc trạng thái + phân trang + export CSV trang hiện tại), chi tiết (items, tiền, khách, thanh toán, đổi trạng thái theo transition map, huỷ đơn bắt buộc lý do, audit log, investigation panel), in/-share hoá đơn PDF.

**Architecture:** Tái dùng hạ tầng phase 0+1 — `ApiClient` (Bearer — server đã fix cookie-only ở bakery-web `24cf5b6`), Riverpod `Notifier`, template feature, `AdminShell` cắm section `orders`. Mới: shared `AdminPagedList` (consumer thật đầu tiên), `AuditLogList`, pattern 401-→logout, CSV share, PDF.

**Tech Stack:** Flutter 3.32.4 (fvm), flutter_riverpod 2.x, thêm `share_plus`, `path_provider`, `pdf`, `printing` + font TTF tiếng Việt (Be Vietnam Pro).

**Spec:** `docs/superpowers/specs/2026-10-07-mobile-admin-design.md` (mục "2. Đơn hàng" + parity table) — đọc song song.

## Global Constraints

- Mọi lệnh qua **fvm**; `fvm flutter analyze` 0 issues; toàn bộ test cũ (74) phải vẫn xanh.
- Chỉ tạo file mới dưới `lib/src/features/admin/**`, sửa `admin_shell.dart` (cắm `orders`), `pubspec.yaml` (+lock, font asset), test mới. **Không đụng** thư mục customer, không sửa `core/network`, không sửa server.
- Chuỗi UI tiếng Việt hardcode; nhãn trạng thái + màu dùng `order_status_display.dart` phase 0+1 (đã có đủ 6 status).
- Tiền từ server là **JSON string** (`"900000.00"`) — mọi field decimal phải coerce qua `_asNum` (pattern `dashboard_dto.dart`). Pull `_asNum`/`_parseList` từ `dashboard_dto.dart` ra `lib/src/features/admin/shared/utils/json_num.dart` (public) và để dashboard_dto import lại — phases sau dùng chung (final review phase 0+1 đề nghị).
- Envelope API **không đồng nhất**: list GET → `data: {orders, pagination}`; detail GET → `data` là order trực tiếp; PATCH → `data: {order}`. Audit GET → `data: {logs, pagination}`. Pin bằng parse test.
- `notes` trong PATCH **không lưu vào Order** — chỉ vào audit metadata (server). Huỷ đơn gửi `{status: 'CANCELLED', notes: <lý do>}`.
- Commit conventional, mỗi task commit riêng; không stage thay đổi lạ trong working tree (.gitignore, analysis_options.yaml, android/gradle.properties, .vscode/*).

## Review Focus

1. **Tiền dạng string ở mọi field decimal** (`subtotal`, `deliveryFee`, `discount`, `total`, `price`, `payment.amount`) — parse test phải pin từng trường với JSON string, không chỉ số.
2. **Envelope 3 kiểu** (list/detail/PATCH khác nhau) — parse test riêng từng loại; sai là toàn màn trắng.
3. **Transition map client phải mirror server chính xác**: PENDING→[CONFIRMED,CANCELLED]; CONFIRMED→[PROCESSING,CANCELLED]; PROCESSING→[READY]; READY→[COMPLETED]; COMPLETED/CANCELLED terminal; same-status là no-op hợp lệ. Unit test đủ 6 status.
4. **401 → logout → AuthLayout**: mọi VM admin bắt `ApiException(401)` → gọi `authViewModelProvider.notifier.logout()` (đã luôn clear user từ fix phase 0+1) → AppGate tự đá về login. VM test với fake auth ghi nhận.
5. **CSV đúng cột + escaping + BOM**: 13 cột đúng thứ tự web, giá trị chứa dấu phẩy/dấu nháy phải wrap `"` (escape `"` thành `""` — web KHÔNG escape, mobile làm đúng chuẩn), BOM `\uFEFF`, tên file `orders_YYYY-MM-DD.csv` theo ngày hôm nay.

---

### Task 1: Packages + font PDF tiếng Việt

**Files:**
- Modify: `pubspec.yaml` (+lock) — `fvm flutter pub add share_plus path_provider pdf printing`
- Create: `assets/fonts/BeVietnamPro-Regular.ttf`, `assets/fonts/BeVietnamPro-Bold.ttf` (tải từ google/fonts GitHub raw: `ofl/bevietnampro/BeVietnamPro-Regular.ttf` + `-Bold.ttf`; nếu tải được woff2 thì bỏ, cần TTF)
- Modify: `pubspec.yaml` flutter.assets — thêm `assets/fonts/`

**Interfaces:**
- Produces: font assets khai báo sẵn cho Task 6 (`rootBundle.load('assets/fonts/BeVietnamPro-Regular.ttf')`).

- [ ] **Step 1:** `fvm flutter pub add share_plus path_provider pdf printing`; tải 2 file TTF vào `assets/fonts/`; thêm vào `pubspec.yaml` assets.
- [ ] **Step 2:** `fvm flutter pub get` + `fvm flutter analyze` — 0 issues. `fvm flutter test` — vẫn 74+ xanh.
- [ ] **Step 3: Commit** — `chore(admin): pdf/share packages + Be Vietnam Pro fonts`

### Task 2: Orders data layer — list + detail + PATCH (+ tách json_num dùng chung)

**Files:**
- Create: `lib/src/features/admin/shared/utils/json_num.dart` (`num asNum(dynamic value)` — chấp nhận num/String, trả 0; copy logic `_asNum` từ `dashboard_dto.dart`); Modify `dashboard_dto.dart` import lại (xoá private copy).
- Create: `lib/src/features/admin/orders/domain/models/order_status_transitions.dart` — `const orderStatusTransitions = <String, List<String>>{...}` đúng map server + `List<String> nextStatuses(String current)`.
- Create: `lib/src/features/admin/orders/domain/models/admin_order.dart` — `AdminOrder{id, orderNumber, userId?, customerName, customerPhone, customerEmail?, customerAddress?, pickupDate?, status, subtotal(double), deliveryFee(double), discount(double), total(double), paymentMethod?, createdAt, updatedAt, items: List<AdminOrderItem>, payment: AdminPayment?, user: AdminOrderUser?}`; `AdminOrderItem{id, productId?, name, message?, price(double), quantity(int), subtotal(double), imageUrl?}` (imageUrl từ `product.images[0].url` khi có); `AdminPayment{provider, transactionId?, amount(double), status, createdAt}`; `AdminOrderUser{id, name?, email?, phone?, memberLevel?}` (list trả không có email — nullable).
- Create: `lib/src/features/admin/orders/data/dtos/order_admin_dto.dart` — `AdminOrderDto.fromJson` (parse cả 2 ngữ cảnh list/detail — cùng shape), `AdminOrderListDto{orders, pagination{page, limit, total, totalPages}}`, `AdminOrderPatchResultDto{order}` (PATCH bọc `{order}`).
- Create: `lib/src/features/admin/orders/data/datasources/order_admin_api_service.dart` — `getOrders({int page = 1, int limit = 20, String? search, String? status})` → GET `/api/admin/orders`; `getOrder(String idOrOrderNumber)` → GET `/api/admin/orders/{id}`; `updateOrder(String idOrOrderNumber, {String? status, String? notes})` → PATCH `/api/admin/orders/{id}` body `{status?, notes?}` (body chỉ chứa key non-null).
- Create: `lib/src/features/admin/orders/data/repositories/order_admin_repository.dart` — `Future<AdminOrderPage> getOrders(...)` (`AdminOrderPage{items, totalPages, total}`), `Future<AdminOrder> getOrder(...)`, `Future<AdminOrder> updateOrder(...)`.
- Modify: `lib/src/core/di/data_providers.dart` — `ordersAdminApiServiceProvider`, `ordersAdminRepositoryProvider`.
- Test: `test/admin_order_dto_test.dart`

**Interfaces:**
- Consumes: `ApiClient.get/post/patch`, pattern DTO `dashboard_dto.dart`.
- Produces (Task 5/6/7 phụ thuộc): `AdminOrder` + fields trên; `orderStatusTransitions`, `nextStatuses()`; repo signatures; `AdminOrderPage{items: List<AdminOrder>, total: int, totalPages: int}`.

- [ ] **Step 1: Write the failing test** — `test/admin_order_dto_test.dart`:
```dart
// Sample JSON khớp contract server: tiền là STRING ('900000.00', '250000.00', ...),
// payment.amount là string, detail trả order trực tiếp, PATCH trả {order}.
// T1: parse list item — subtotal 900000.0 (double từ '900000.00'), total, price từng item,
//     payment.amount; imageUrl = product.images[0].url; product rỗng images → imageUrl null;
//     user không có email → null; customerEmail/address null OK.
// T2: AdminOrderListDto — pagination {page:1, limit:20, total:35, totalPages:2}.
// T3: PATCH shape — data:{order} bọc, parse ra AdminOrder (status mới).
// T4: nextStatuses: PENDING→[CONFIRMED,CANCELLED]; CONFIRMED→[PROCESSING,CANCELLED];
//     PROCESSING→[READY]; READY→[COMPLETED]; COMPLETED→[]; CANCELLED→[]; mã lạ→[].
```
- [ ] **Step 2: Run** `fvm flutter test test/admin_order_dto_test.dart` — FAIL (chưa tồn tại).
- [ ] **Step 3: Implement** theo Interfaces; tách `json_num.dart`, dashboard_dto import lại, chạy thêm `fvm flutter test test/dashboard_dto_test.dart` phải vẫn xanh.
- [ ] **Step 4: Run** — PASS; full suite xanh; analyze 0.
- [ ] **Step 5: Commit** — `feat(admin): orders data layer (list/detail/patch + transitions)`

### Task 3: Audit + investigation data layer

**Files:**
- Create: `lib/src/features/admin/orders/domain/models/order_audit.dart` — `OrderAuditLog{id, actorName? (actor.name, fallback 'System'), actorRole?, mutationType, metadata (Map<String,dynamic>?) , createdAt}`; `OrderInvestigation{orderNumber, orderStatus, payment: ({provider, status, transactionId?, amount(double), createdAt})?, callbackEvents: List<OrderCallbackEvent>, attempts: List<OrderReconciliationAttempt>}`; `OrderCallbackEvent{id, provider, event, incomingStatus?, existingStatus?, outcome?, reason?, createdAt}`; `OrderReconciliationAttempt{callbackEventId, provider, outcome, incomingStatus?, createdAt}`.
- Create: `lib/src/features/admin/orders/data/dtos/order_audit_dto.dart` — parse `{logs, pagination}` và investigation shape (payment.amount ở đây là **number** — server đã `Number()`; callback events null-normalized).
- Modify: `order_admin_api_service.dart` — `getOrderAudit(String idOrOrderNumber, {int page, int limit})`, `getInvestigation(String idOrOrderNumber)`; `order_admin_repository.dart` — tương ứng (`Future<({List<OrderAuditLog> logs, int totalPages})>`, `Future<OrderInvestigation>`).
- Test: `test/admin_order_audit_dto_test.dart`

**Interfaces:**
- Produces (Task 7): `OrderAuditLog`, `OrderInvestigation` + repo methods signatures trên. (callbackTimeline/attempts UI chỉ hiện 10 đầu như web — slice ở UI.)

- [ ] **Step 1: Write failing test** — sample JSON: 2 logs (1 có actor name, 1 actor null → 'System' khi render? — DTO giữ null, fallback ở widget; DTO test pin actor null giữ null), metadata {note, transition:'PENDING->CONFIRMED'}; investigation với payment null VÀ payment đủ (amount là number 250000), callbackEvents có event 'processed' + reason null, attempts 1 item; pagination totalPages.
- [ ] **Step 2: Run** — FAIL. **Step 3: Implement.** **Step 4: Run** PASS + full suite + analyze. **Step 5: Commit** — `feat(admin): order audit + investigation data layer`

### Task 4: Shared `AdminPagedList` widget

**Files:**
- Create: `lib/src/features/admin/shared/presentation/widgets/admin_paged_list.dart` — `class AdminPagedList<T> extends StatelessWidget` với props: `items: List<T>`, `isLoading: bool`, `error: String?`, `onRetry: VoidCallback`, `isLoadingMore: bool`, `hasMore: bool`, `onLoadMore: VoidCallback`, `onRefresh: Future<void> Function()`, `itemBuilder: Widget Function(BuildContext, T)`, `searchHint`, `searchText: String?`, `onSearchChanged: ValueChanged<String>?`, `filters: List<AdminFilterChip>` (`{label, value: String?}`), `selectedFilter: String?`, `onFilterSelected: ValueChanged<String?>?`, `emptyText = 'Chưa có dữ liệu'`. Nội dung: ô tìm kiếm (TextField, onChanged → onSearchChanged), hàng chip lọc (ALL mặc định value null), `RefreshIndicator` + `ListView.builder` + ScrollController — gần đáy (~600px) khi `hasMore && !isLoadingMore` → `onLoadMore` (dùng NotificationListener<ScrollNotification> hoặc controller listener trong StatefulWidget con), footer spinner khi isLoadingMore, trạng thái loading (spinner giữa), empty (text giữa), error (text + TextButton 'Thử lại' → onRetry).
- Test: `test/admin_paged_list_test.dart`

**Interfaces:**
- Consumes: không (pure presentation).
- Produces (Task 5, phases sau): widget như trên.

- [ ] **Step 1: Write failing test** — pump trong MaterialApp + SizedBox kích thước: (1) hiện itemBuilder cho 2 items; (2) nhập text → onSearchChanged nhận; (3) tap chip 'Đã xác nhận' → onFilterSelected 'CONFIRMED'; (4) items rỗng + isLoading false → 'Chưa có dữ liệu'; (5) error → 'Thử lại' → onRetry gọi; (6) 30 items + hasMore → drag cuộn cuối → onLoadMore gọi ≥1 lần; hasMore false → không gọi.
- [ ] **Step 2: Run** FAIL → **Step 3: Implement** → **Step 4: PASS** + full + analyze. **Step 5: Commit** — `feat(admin): shared paged list widget (search/filter/pagination)`

### Task 5: Orders list — VM + màn hình + CSV export

**Files:**
- Create: `lib/src/features/admin/orders/presentation/controllers/orders_admin_view_model.dart` — `OrdersAdminState{items, page, totalPages, search, statusFilter, isLoading, isLoadingMore, error}`; `load()` (page 1, từ state), `setSearch(String)` (trim; set + load), `setStatusFilter(String?)` (null=ALL; set + load), `loadMore()`, `retry()`; bắt `ApiException` statusCode 401 → `ref.read(authViewModelProvider.notifier).logout()` (không set error).
- Create: `lib/src/features/admin/orders/presentation/widgets/order_card.dart` — card: orderNumber (bold) + StatusPill; customerName; formatVnd(total); paymentMethod + payment.status; formatDateTimeVi(createdAt); onTap callback.
- Create: `lib/src/features/admin/orders/utils/orders_csv.dart` — `String buildOrdersCsv(List<AdminOrder> orders, {DateTime? now})` — 13 cột đúng thứ tự web: `Order Number, Customer Name, Phone, Email, Address, Subtotal, Delivery Fee, Discount, Total, Payment Method, Payment Status, Status, Created At`; values: customerEmail ?? '', address ?? '', paymentMethod ?? '', payment?.status ?? 'N/A', tiền `asNum` in thập phân gọn, createdAt `toIso8601String()`; escape CSV chuẩn (wrap `"` khi chứa `,` `"` `\n`, nháy đôi thành `""`); BOM `\uFEFF` đầu chuỗi; `String ordersCsvFileName({DateTime? now})` → `orders_YYYY-MM-DD.csv`.
- Create: `lib/src/features/admin/orders/presentation/screens/orders_screen.dart` — ConsumerStatefulWidget: initState → load(); `AdminPagedList<AdminOrder>` với filters = 6 status + ALL; nút export (IconButton icon Icons.ios_share/Icons.file_download_outlined trong hàng search — chỉ active khi có items): ghi file vào temp dir (`path_provider` getTemporaryDirectory) → `Share.shareXFiles([XFile(path)])`; snackbar lỗi share.
- Modify: `lib/src/core/di/app_providers.dart` — `ordersAdminViewModelProvider`; `admin_shell.dart` — section `orders` → `OrdersScreen`; `orders_screen.dart` — onTap của card: stub no-op (`// TODO(phase-2-task-6): push OrderDetailScreen` — màn chi tiết chưa tồn tại ở task này).
- Test: `test/orders_admin_vm_test.dart` + `test/orders_csv_test.dart`

**Interfaces:**
- Consumes: Task 2 repo + Task 4 widget; `authViewModelProvider` (fake test); `StatusPill/formatVnd/formatDateTimeVi`.
- Produces: `ordersAdminViewModelProvider`, `OrdersScreen`.

- [ ] **Step 1: Write failing tests** — CSV (pure): đúng 13 cột header; dòng giá trị khớp; giá trị chứa dấu phẩy (`customerName: 'Trần Văn B, QN'`) được wrap quote; chứa nháy bị escape `""`; BOM đầu file; tên file ngày ghim. VM (fake repo + fake AuthViewModel ghi logout): load → items + totalPages; setSearch('PL-10') → repo nhận search, page reset 1; setStatusFilter('CONFIRMED') tương tự; loadMore khi page<totalPages → items ghép; error thường → state.error; **error 401 → auth logout được gọi + error null**.
- [ ] **Step 2: Run** FAIL → **Step 3: Implement** → **Step 4: PASS** + full + analyze. **Step 5: Commit** — `feat(admin): orders list with filters, csv export, 401 handling`

### Task 6: Order detail — VM + màn hình + hoá đơn PDF

**Files:**
- Create: `lib/src/features/admin/orders/presentation/controllers/order_detail_view_model.dart` — family `NotifierProvider.family<OrderDetailViewModel, OrderDetailState, String>` (key = idOrOrderNumber); `OrderDetailState{order, audit: List<OrderAuditLog>?, investigation: OrderInvestigation?, isLoading, isUpdating, error}`; `load()` (order + audit song song; investigation lazy — `loadInvestigation()` gọi riêng); `updateStatus(String next, {String? notes})` → repo.updateOrder → cập nhật order từ `{order}` trả về + snackbar thành công do UI; 401 → logout pattern.
- Create: `lib/src/features/admin/orders/presentation/screens/order_detail_screen.dart` — nhận `orderNumber` qua constructor; sections cuộn dọc: header (orderNumber + StatusPill + createdAt), card Khách hàng (tên, SĐT, email?, địa chỉ?, user.memberLevel badge nếu có), card Thanh toán (paymentMethod, payment provider/status/transactionId/amount), danh sách items (ảnh thumbnail `imageUrl` qua resolve pattern — nếu ảnh relative ghép base URL, placeholder icon khi null; tên, message cá nhân hoá in nghiêng, SL × giá, subtotal), phân tích tiền (subtotal → phí giao nếu >0 → giảm nếu >0 → tổng bold), section 'Cập nhật trạng thái': hàng chip `nextStatuses(order.status)` (chip nhãn Việt `orderStatusLabel`) — chip thường → `updateStatus(next)`; chip 'Đã huỷ' → bottom sheet bắt buộc nhập lý do (TextField, nút xác nhận disable khi rỗng/whitespace) → `updateStatus('CANCELLED', notes: reason)`; section 'Nhật ký' (AuditLogList); section 'Điều tra thanh toán' (expandable — ExpansionTile): trạng thái đơn/payment + timeline callback (≤10, mỗi event: thời gian + provider + event + outcome/reason) + attempts (≤10); nút AppBar action 'Hoá đơn' (icon Icons.print) → bottom sheet 2 lựa chọn: **'In hoá đơn'** (`Printing.layoutPdf(onLayout: (_) => buildInvoicePdf(order))`) và **'Chia sẻ PDF'** (ghi bytes vào temp dir `invoice_{orderNumber}.pdf` → `Share.shareXFiles`).
- Create: `lib/src/features/admin/orders/presentation/widgets/invoice_pdf.dart` — `Future<Uint8List> buildInvoicePdf(AdminOrder order, {String brand = 'Phương Loan Bakery'})` — dùng `pdf` package + 2 font TTF Task 1; cấu trúc mirror web: header orderNumber + brand + badge trạng thái (nhãn Việt), 2 cột KHÁCH HÀNG (Tên/SĐT/Địa chỉ nếu có) + THÔNG TIN (Ngày formatDateTimeVi, Thanh toán paymentMethod ?? 'N/A'), bảng items (Tên/Mon/Đơn giá/Tiền), totals (tạm tính → phí giao nếu >0 → giảm nếu >0 với dấu '-' → tổng), footer 'Cảm ơn bạn đã đặt hàng! • Phương Loan Bakery'.
- Modify: `admin_shell.dart`? — không cần (detail push từ OrdersScreen `Navigator.push(MaterialPageRoute(OrderDetailScreen(orderNumber: ...)))`).
- Modify: `orders_screen.dart` — thay stub onTap bằng `Navigator.push(MaterialPageRoute(builder: (_) => OrderDetailScreen(orderNumber: order.orderNumber)))`; `app_providers.dart`? — không, đã có từ Task 5.
- Test: `test/order_detail_vm_test.dart` + `test/invoice_pdf_test.dart`

**Interfaces:**
- Consumes: Task 2/3 repo; Task 1 fonts; shared widgets.
- Produces: `orderDetailViewModelProvider` (family), `OrderDetailScreen`.

- [ ] **Step 1: Write failing tests** — VM: load ghép order+audit; updateStatus('CONFIRMED') → repo nhận body `{status: 'CONFIRMED'}` (fake bắt body, không có notes); updateStatus('CANCELLED', notes: 'Khách huỷ') → body `{status: 'CANCELLED', notes: 'Khách huỷ'}`; state cập nhật order mới; 401 → logout. PDF: `buildInvoicePdf` với order có tiếng Việt ('Bánh sinh nhật Trần Thị B') + payment null + deliveryFee 0 + discount >0 → bytes non-empty, bắt đầu `%PDF`, không throw. (Widget test màn hình: chip transition PENDING hiện đúng 2 chip 'Đã xác nhận' + 'Đã huỷ'; COMPLETED → không có chip + text 'Đơn đã hoàn tất'.)
- [ ] **Step 2: Run** FAIL → **Step 3: Implement** → **Step 4: PASS** + full + analyze. **Step 5: Commit** — `feat(admin): order detail with status transitions, cancel reason, audit, investigation, invoice pdf`

### Task 7: Verify + regression sweep

**Files:** không có code mới (fix nếu phát hiện).

- [ ] **Step 1:** `fvm flutter analyze` — 0 issues; `fvm flutter test` — tất cả xanh (74 cũ + mới).
- [ ] **Step 2: Emulator smoke** (API 3001 + app): Đơn hàng list hiện dữ liệu thật → tìm kiếm theo số đơn → lọc 'Chờ xác nhận' → mở 1 đơn → dữ liệu khớp web `/admin/orders` → đổi trạng thái PENDING→CONFIRMED → web refresh thấy đổi + audit log hiện entry → quay list, export CSV → share sheet hiện file → mở đơn có payment → section investigation mở được → in hoá đơn → dialog in Android hiện tiếng Việt đúng dấu → huỷ 1 đơn PENDING với lý do → status pill 'Đã huỷ'. Chụp screenshot vào `gui-test-screenshots/admin-phase2/`. (In + share PDF nếu emulator có print service; thiếu thì ghi nhận trong report.)
- [ ] **Step 3:** Fix nếu có (commit riêng `fix(admin): ...`) rồi chạy lại Step 1.

## Sau phase này

Phase 3 (Khách hàng) plan riêng trước khi triển khai. Backlog kế thừa: load() race poll-vs-setWindow (phase hardening), chart tooltip, `meta.refreshIntervalSeconds` dùng động, test fixture dùng chung.

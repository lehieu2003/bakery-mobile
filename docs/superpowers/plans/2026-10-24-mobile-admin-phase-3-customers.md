# Mobile Admin — Phase 3 (Khách hàng) Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Thay placeholder mục "Khách hàng" trong AdminShell bằng module thật: danh sách (search server-side + filter hạng + phân trang), chi tiết (3 card thống kê + đơn/thanh toán/thông báo gần đây), sửa hạng + điểm qua bottom sheet (`PATCH`).

**Architecture:** Mirror phase 2 (orders) — data layer DTO/service/repository + Riverpod Notifier, list dùng lại `AdminPagedList<T>`, pattern 401→logout, DI trong `core/di`. Mới: `member_level_badge.dart` (badge hạng 3 màu theo web).

**Tech Stack:** Flutter 3.32.4 (fvm), flutter_riverpod 2.x — không thêm package.

**Spec:** `docs/superpowers/specs/2026-10-07-mobile-admin-design.md` mục "3. Khách hàng" (đã Hieu duyệt 10-07). Contract tham chiếu: bakery-web `app/api/admin/customers/route.ts` + `[id]/route.ts` + `tests/admin/admin-customers-routes.test.ts`.

## Global Constraints

- Mọi lệnh qua **fvm**; `fvm flutter analyze` 0 issues; full suite (311 baseline) phải xanh sau mỗi task.
- Branch `feature/admin-phase-3-customers` từ `origin/dev`; commit conventional từng task; PR vào `dev` sau khi xong (không tự merge master).
- Envelope: list GET → `data: {customers, pagination{page,limit,total,totalPages}}`; detail GET → `data` là customer trực tiếp; PATCH → `data` là customer (bỏ qua no-change 200 shape — parse cùng DTO).
- **Money:** `totalSpent` có thể là number HOẮC string (aggregate) → coerce qua `asNum` (`admin/shared/utils/json_num.dart`); `recentOrders[].total` và `recentPayments[].amount` server đã `Number()` nhưng vẫn parse qua `asNum` (phòng server đổi).
- `level` là **alias trùng `memberLevel`** — DTO chỉ cần đọc 1 trong hai (ưu tiên `memberLevel`).
- MEMBER_LEVELS = `SILVER | GOLD | PLATINUM`; PATCH body `{memberLevel?, points?}` — points phải **integer ≥ 0** (server 400 'Invalid points'); client cũng gate trước khi gửi.
- Màu badge hạng copy web `MEMBER_LEVEL_COLORS` (Tailwind hex): SILVER bg `#F1F5F9` text `#475569` border `#E2E8F0`; GOLD bg `#FFFBEB` text `#B45309` border `#FDE68A`; PLATINUM bg `#FDF2F8` text `#BE185D` border `#FBCFE8`.
- Chuỗi UI tiếng Việt hardcode; nhãn hạng hiển thị giữ mã (SILVER/GOLD/PLATINUM) như web.
- 401 → `ref.read(authViewModelProvider.notifier).logout()` (pattern `orders_admin_view_model.dart`).
- List default `limit = 50` (test web pin 50); `recentOrders`/`recentNotifications` server trả tối đa 10.

## Review Focus

1. **`totalSpent` number-vs-string** — parse test phải pin cả hai dạng (number + string) cùng một field.
2. **Envelope 3 kiểu** (list có `customers`, detail là object trần, PATCH trả customer) — parse test riêng từng loại.
3. **`points` không nguyên hoặc âm** — client gate chặn trước PATCH (snackbar lỗi), test VM pin cả trường hợp server 400.
4. **401 → logout → AuthLayout** — VM test với fake auth ghi nhận logout được gọi.
5. **Danh sách rỗng sau filter lạ** (level không hợp lệ → server trả list rỗng) — UI phải hiện empty-state, không crash.

---

### Task 1: Data layer — DTO + API service + repository + DI

**Files:**
- Create: `lib/src/features/admin/customers/domain/models/admin_customer.dart`
- Create: `lib/src/features/admin/customers/data/dtos/customer_admin_dto.dart`
- Create: `lib/src/features/admin/customers/data/datasources/customer_admin_api_service.dart`
- Create: `lib/src/features/admin/customers/data/repositories/customer_admin_repository.dart`
- Modify: `lib/src/core/di/data_providers.dart` (providers đăng ký — pattern orders)
- Test: `test/customer_admin_dto_test.dart`

**Interfaces:**
- Consumes: `ApiClient.get/patch` (Bearer), `asNum` từ `admin/shared/utils/json_num.dart`.
- Produces (Task 2/3/4 phụ thuộc):
  - `AdminCustomer{id, email, name, phone, memberLevel, points(int), isActive, createdAt, totalOrders(int), totalSpent(double)}`
  - `AdminCustomerDetail` extends shape trên + `recentOrders: List<AdminCustomerOrder>`, `recentPayments: List<AdminCustomerPayment>`, `recentNotifications: List<AdminCustomerNotification>`, `notificationSummary: AdminNotificationSummary{totalRead, unreadPublished}`
  - `AdminCustomerOrder{id, orderNumber, total(double), status, paymentMethod, createdAt, payment: AdminCustomerPaymentInfo?}`; `AdminCustomerPaymentInfo{id, provider, transactionId, amount(double), status, createdAt}`; `AdminCustomerPayment{paymentId, orderId, orderNumber, provider, transactionId, amount(double), status, createdAt}`; `AdminCustomerNotification{notificationId, title, status, audience, publishedAt, createdAt, readAt}`
  - `CustomerAdminPage{items: List<AdminCustomer>, total, totalPages}`
  - repo: `Future<CustomerAdminPage> getCustomers({int page, int limit = 50, String? search, String? level})`, `Future<AdminCustomerDetail> getCustomer(String id)`, `Future<AdminCustomerDetail> updateCustomer(String id, {String? memberLevel, int? points})`

- [ ] **Step 1: Write the failing test** — `test/customer_admin_dto_test.dart`, 4 test theo contract:
  - T1 parse list item: `points: 10` (int), `totalSpent: "1250000.00"` (STRING) → `1250000.0`; `name: null`, `phone: null` OK; `level` alias bỏ qua khi có `memberLevel`
  - T2 parse list item với `totalSpent: 990000` (NUMBER) → `990000.0` — pin hai dạng money
  - T3 parse detail: `recentOrders` (payment null → `null`; payment amount `"500000.00"` string → 500000.0), `recentPayments` (amount number), `recentNotifications` (`readAt` null OK), `notificationSummary{totalRead: 3, unreadPublished: 1}`
  - T4 parse PATCH response (`data` = customer detail) + validation model: `AdminMemberLevel.valid('SILVER'|'GOLD'|'PLATINUM')` true, `'DIAMOND'` false
- [ ] **Step 2: Run** `fvm flutter test test/customer_admin_dto_test.dart` — FAIL (chưa tồn tại)
- [ ] **Step 3: Implement** theo Interfaces — DTO parse qua `asNum`; api service: `getCustomers({page, limit = 50, search, level})` GET `/api/admin/customers` query `{page, limit, if search 'search', if level 'level'}`; `getCustomer(id)` GET `/api/admin/customers/$id`; `updateCustomer` PATCH `/api/admin/customers/$id` body chỉ chứa key non-null; repository wrap DTO; DI providers `customersAdminApiServiceProvider`, `customersAdminRepositoryProvider`
- [ ] **Step 4: Run** — PASS; `fvm flutter analyze` 0; full suite xanh
- [ ] **Step 5: Commit** — `feat(admin): customers data layer (list/detail/patch)`

### Task 2: List UI — CustomersScreen + VM + badge hạng + cắm AdminShell

**Files:**
- Create: `lib/src/features/admin/customers/presentation/widgets/member_level_badge.dart`
- Create: `lib/src/features/admin/customers/presentation/controllers/customers_admin_view_model.dart`
- Create: `lib/src/features/admin/customers/presentation/screens/customers_screen.dart`
- Modify: `lib/src/features/admin/shell/presentation/screens/admin_shell.dart` — case `AdminSection.customers` → `CustomersScreen` (thay placeholder)
- Test: `test/customers_admin_vm_test.dart`

**Interfaces:**
- Consumes: Task 1 repo; `AdminPagedList<T>` (`items/isLoading/error/onRetry/isLoadingMore/hasMore/onLoadMore/onRefresh/itemBuilder/searchHint/searchText/onSearchChanged/filters/selectedFilter/onFilterSelected/emptyText`); pattern VM 401→logout từ `orders_admin_view_model.dart`.
- Produces: `CustomersScreen` (điều hướng được từ AdminShell); `MemberLevelBadge(level: String)` — pill 3 màu theo Global Constraints; `customersAdminViewModelProvider`.

- [ ] **Step 1: Write the failing VM test** — `test/customers_admin_vm_test.dart` (fake repo + fake auth, pattern `orders_admin_vm_test.dart`):
  - load đầu tiên → state items theo page 1, `hasMore` theo totalPages
  - `setSearch('linh')` debounce-reset về page 1 + gọi repo với search
  - `setFilter('GOLD')` → gọi repo với level='GOLD'; filter 'ALL' → level null
  - `loadMore` khi hasMore → page 2 cộng dồn items; không loadMore khi !hasMore
  - repo ném `ApiException(401)` → authViewModel.logout được gọi
- [ ] **Step 2: Run** — FAIL
- [ ] **Step 3: Implement** — VM mirror `orders_admin_view_model.dart` (search/filter/loadMore/401); `CustomersScreen`: `AdminPagedList` searchHint 'Tìm tên, email, số điện thoại', filters `[Tất cả(ALL), SILVER, GOLD, PLATINUM]`, itemBuilder = card: avatar tròn chữ cái đầu (tên hoặc email), tên + email, `MemberLevelBadge`, dòng điểm (`points` + 'điểm'), `totalOrders` + `totalSpent` qua `formatVnd`; tap card **chưa điều hướng** (Task 3 cắm push `CustomerDetailScreen`); cắm case `AdminSection.customers` trong admin_shell
- [ ] **Step 4: Run** — PASS; analyze 0; full suite xanh
- [ ] **Step 5: Commit** — `feat(admin): customers list screen with tier filter and search`

### Task 3: Detail UI — CustomerDetailScreen + VM

**Files:**
- Create: `lib/src/features/admin/customers/presentation/screens/customer_detail_screen.dart`
- Create: `lib/src/features/admin/customers/presentation/controllers/customer_detail_view_model.dart`
- Modify: `lib/src/features/admin/customers/presentation/screens/customers_screen.dart` — tap card push `CustomerDetailScreen(customerId: id)` (Task 2 để trống)
- Test: `test/customer_detail_vm_test.dart`

**Interfaces:**
- Consumes: Task 1 `getCustomer`; `formatVnd`/`formatDateVi` từ `lib/src/shared/utils/format_utils.dart`; `MemberLevelBadge`; pattern 401→logout.
- Produces: `CustomerDetailScreen({required String customerId})`; `customerDetailViewModelProvider` (family theo id); state expose `detail`, `isLoading`, `error`, `isSaving`, phương thức `update({memberLevel, points})` cho Task 4.

- [ ] **Step 1: Write the failing VM test** — `test/customer_detail_vm_test.dart`:
  - load detail → state.detail parse từ fixture Task 1 T3
  - repo 401 → logout được gọi
  - repo lỗi khác → state.error có message, retry gọi lại
- [ ] **Step 2: Run** — FAIL
- [ ] **Step 3: Implement** — màn cuộn dọc: header tên + email + `MemberLevelBadge`; **3 card thống kê** (Tổng đơn `totalOrders` / Tổng chi `formatVnd(totalSpent)` / Điểm `points`); **Đơn gần đây** (≤10: orderNumber, status, `formatVnd(total)`, ngày — tap điều hướng ra order detail của phase 2 nếu tiện, không bắt buộc); **Thanh toán gần đây** (provider, transactionId, `formatVnd(amount)`, status); **Thông báo gần đây** (title, đã đọc/chưa đọc, ngày) + dòng tổng hợp 'X đã đọc · Y chưa đọc' từ `notificationSummary`; nút 'Chỉnh sửa' mở bottom sheet Task 4; nút retry khi error
- [ ] **Step 4: Run** — PASS; analyze 0; full suite xanh
- [ ] **Step 5: Commit** — `feat(admin): customer detail screen with stats and recents`

### Task 4: Edit bottom sheet — đổi hạng + điểm

**Files:**
- Create: `lib/src/features/admin/customers/presentation/widgets/customer_edit_sheet.dart`
- Test: `test/customer_detail_vm_test.dart` (bổ sung case update)

**Interfaces:**
- Consumes: Task 3 `customerDetailViewModelProvider` state + `update({memberLevel, points})` (gọi repo `updateCustomer`, thành công → refresh detail, đóng sheet, snackbar 'Đã cập nhật khách hàng'); `MemberLevelBadge` preview.
- Produces: `showCustomerEditSheet(context, detail)` — bottom sheet 2 trường.

- [ ] **Step 1: Bổ sung failing VM tests** — trong `test/customer_detail_vm_test.dart`:
  - `update(memberLevel: 'GOLD')` → repo nhận `{memberLevel: 'GOLD'}` (points null → không gửi key), detail refresh sau save
  - `update(points: -5)` → **client gate**: repo KHÔNG được gọi, state.error 'Điểm phải là số nguyên không âm'
  - repo PATCH 400 'Invalid points' → state.error hiện message server
- [ ] **Step 2: Run** — FAIL
- [ ] **Step 3: Implement** — VM `update` validate `points == null || (points is int && points >= 0)`; sheet: dropdown/choice chips hạng (3 lựa chọn, badge preview theo lựa chọn), TextField điểm số nguyên (keyboard number, validate parse int ≥ 0), nút Lưu (disable khi isSaving), lỗi hiện trong sheet; thành công → pop + snackbar
- [ ] **Step 4: Run** — PASS; analyze 0; full suite xanh
- [ ] **Step 5: Commit** — `feat(admin): customer edit sheet for member level and points`

### Task 5: Verify + smoke emulator

- [ ] **Step 1:** `fvm flutter analyze` 0 issues; `fvm flutter test` toàn bộ xanh (311 + test mới).
- [ ] **Step 2: Smoke trên emulator-5554** (server dev port 3000 đang chạy; credential admin@bakeryshop.com/admin123): login admin → drawer Khách hàng → list render (badge hạng 3 màu, điểm, tổng chi) → filter GOLD → search 'linh' → mở chi tiết 1 khách → 3 card thống kê + 3 list recents → Chỉnh sửa → đổi hạng GOLD→PLATINUM + điểm → lưu → detail refresh đúng → (verify chéo: web admin/customers thấy thay đổi). **Quay lại hạng gốc** sau smoke.
- [ ] **Step 3: PR** `fix/../feat(admin): customers module (phase 3)` vào `dev` — body liệt kê task + kết quả smoke; chờ merge theo kỷ luật PR.

# Mobile Feature Parity Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Thêm 4 tính năng thiếu vào bakery-mobile (VNPAY, chi tiết đơn hàng, sổ địa chỉ, đánh giá sản phẩm) dùng API bakery-web đã có.

**Architecture:** Theo kiến trúc hiện có của bakery-mobile: feature folder `lib/src/features/<name>/{data,domain,presentation}` với dto → datasource (ApiClient Bearer) → repository → Riverpod controller → screens. UI tiếng Việt theo theme hiện có.

**Tech Stack:** Flutter 3.32.4 (fvm), Dart 3.8.1, flutter_riverpod, flutter_dotenv; test bằng `fvm flutter test`.

**Spec:** `docs/superpowers/specs/2026-10-03-mobile-feature-parity-design.md`

## Global Constraints

- Mọi lệnh flutter chạy qua `fvm flutter ...` trong `bakery-mobile/`.
- KHÔNG đổi bất kỳ file nào dưới `app/`, `lib/` của bakery-web (chỉ dùng API có sẵn).
- Server giữ nguyên: bodies login/refresh vẫn trả token (mobile Bearer); `Set-Cookie` không đổi.
- UI text tiếng Việt; error → SnackBar theo pattern hiện có.
- Mỗi task: `fvm flutter analyze` 0 issues + `fvm flutter test` pass trước khi commit.
- TDD nơi test được (DTO parse + payload), widget test khi wiring cho phép.

## Review Focus

- Auth: các call mới phải đi qua ApiClient tokenProvider (Bearer) — không tự đọc storage.
- Checkout sửa xong: guest vẫn đặt được COD; các payment method cũ không vỡ.
- Order detail: order của người khác phải 404 (endpoint scope user) — hiển thị thông báo, không crash.
- Address payload khớp validate server: phone VN `^(0|\+84)(3|5|7|8|9)\d{8}$`, text 1-200 ký tự.
- Review: 409 trùng đánh giá → thông báo riêng, không toast lỗi chung.

---

### Task 1: VNPAY ở checkout

**Files:**
- Modify: `lib/src/features/cart/presentation/screens/checkout_screen.dart` (danh sách `_paymentMethods` dòng 23-25 + label/icon map nếu có)
- Test: `test/checkout_payment_test.dart` (mới)

**Interfaces:**
- Consumes: `order_checkout_service.placeOrder(... paymentMethod: String)` (đã pass-through).
- Produces: payment method `'VNPAY'` gửi thẳng qua placeOrder.

- [ ] **Step 1: Viết test** — widget test với `ProviderScope` overrides (pattern `test/widget_test.dart`): màn checkout hiện 4 lựa chọn (COD/BANK_TRANSFER/MOMO/VNPAY); chọn VNPAY + placeOrder qua fake repository → captured `paymentMethod == 'VNPAY'`. Nếu wiring provider nặng quá: unit test assert danh sách method chứa 'VNPAY' + placeOrder forward (fake repo) là mức tối thiểu chấp nhận.
- [ ] **Step 2: FAIL** — chạy `fvm flutter test test/checkout_payment_test.dart`, expected FAIL (chưa có VNPAY).
- [ ] **Step 3: Implement** — thêm lựa chọn; nhãn "VNPAY (QR/ATM/Visa)".
- [ ] **Step 4: PASS** — test + `fvm flutter analyze`.
- [ ] **Step 5: Commit** — `feat(orders): add VNPAY payment method at checkout`

### Task 2: Màn chi tiết đơn hàng

**Files:**
- Modify: `lib/src/features/orders/data/datasources/order_api_service.dart` (thêm `getOrder(orderNumber)`)
- Modify: `lib/src/features/orders/data/repositories/order_repository.dart` + DTO (bổ sung trường payment/deliveryFee/discount nếu thiếu — đối chiếu `serializeOrder` của web)
- Create: `lib/src/features/orders/presentation/screens/order_detail_screen.dart`
- Modify: `lib/src/features/profile/presentation/screens/profile_screen.dart` (tile Order History → push detail)
- Test: `test/order_detail_dto_test.dart` (fixture JSON khớp response web)

**Interfaces:**
- Consumes: ApiClient Bearer; `serializeOrder` shape web: `{ order: { orderNumber, status, paymentMethod, pickupDate, customerName, customerAddress, deliveryFee, discount, total, createdAt, orderItems: [{ name, price, quantity, subtotal, product: { images } }], payment: { status } } }`.
- Produces: `OrderRepository.getOrder(String orderNumber) → Order` (ném ApiException 404 khi không thấy).

- [ ] **Step 1: Viết DTO parse test với fixture** (JSON mẫu đủ trường, kể cả product.images) — FAIL trước.
- [ ] **Step 2: Implement service + repository + DTO mở rộng → PASS.**
- [ ] **Step 3: Implement OrderDetailScreen + điều hướng từ Order History tile.**
- [ ] **Step 4: `fvm flutter analyze` + `fvm flutter test` + Commit** — `feat(orders): order detail screen from history`

### Task 3: Sổ địa chỉ + tích hợp checkout

**Files:**
- Create: `lib/src/features/addresses/` (dto, datasource, repository, controller, screens/addresses_screen.dart) — pattern wishlist
- Modify: `lib/src/features/cart/presentation/screens/checkout_screen.dart` (delivery mode: radio địa chỉ đã lưu + ô nhập mới giữ nguyên)
- Modify: `lib/src/features/profile/presentation/screens/profile_screen.dart` (section "Sổ địa chỉ")
- Test: `test/address_dto_test.dart` + `test/addresses_controller_test.dart` (fake datasource)

**Interfaces:**
- Consumes: `/api/addresses` GET/POST, `/api/addresses/{id}` PUT/DELETE; payload `{ fullName, phone, street, ward, district, province, isDefault }`.
- Produces: `AddressesController` (StateNotifier list + add/update/delete/setDefault); checkout gửi `addressId` + dòng địa chỉ khi chọn địa chỉ lưu.

- [ ] **Step 1: DTO test** (parse list + isDefault) — FAIL trước.
- [ ] **Step 2: Controller test với fake datasource** (add → list cập nhật; delete → rời list; setDefault → chỉ 1 default) — FAIL trước.
- [ ] **Step 3: Implement datasource/repository/controller.**
- [ ] **Step 4: Implement màn addresses + section Profile.**
- [ ] **Step 5: Tích hợp checkout** (delivery + có địa chỉ → radio; không có → giữ input).
- [ ] **Step 6: analyze + test + Commit** — `feat(addresses): address book with checkout integration`

### Task 4: Đánh giá sản phẩm

**Files:**
- Create: `lib/src/features/reviews/` (dto, datasource, repository, controller)
- Modify: `lib/src/features/catalog/presentation/screens/product_detail_screen.dart` (section reviews + form)
- Test: `test/reviews_dto_test.dart` (parse list + payload gửi)

**Interfaces:**
- Consumes: `GET /api/products/{id}/reviews` (list + ratingAverage/reviewCount), `POST` ({rating, comment}) — 409 khi trùng.
- Produces: `ReviewsController.load(productId)`, `ReviewsController.submit(productId, rating, comment)` (409 → message riêng "Bạn đã đánh giá sản phẩm này").

- [ ] **Step 1: DTO test** — FAIL trước.
- [ ] **Step 2: Implement data layer → PASS.**
- [ ] **Step 3: Implement section PDP** (header sao TB, list, form sao + textarea; guest → nút đăng nhập).
- [ ] **Step 4: analyze + test + Commit** — `feat(reviews): product reviews on product detail`

# Design — Mobile Feature Parity (VNPAY, Order Detail, Addresses, Reviews)

*Ngày: 2026-10-03 · Dự án: bakery-mobile (Flutter 3.32.4, fvm-pinned) · Nguồn chuẩn: bakery-web (Next.js)*

## Bối cảnh và mục tiêu

App mobile đã đồng bộ thương hiệu/nội dung với web nhưng còn thiếu 4 tính năng mà web có và **API phía bakery-web đều đã sẵn sàng** (không sửa backend). Mục tiêu: đưa 4 tính năng vào mobile theo đúng pattern web, tái dùng kiến trúc hiện có (features/ theo layer dto → datasource → repository → controller → screens, Riverpod, ApiClient Bearer).

Ràng buộc: không đổi server; không phá luồng mobile-Bearer hiện có; UI theo theme hiện có; mỗi tính năng có test riêng; `fvm flutter analyze` sạch.

## F1 — Thanh toán VNPAY

- **API:** `POST /api/orders` đã chấp nhận `paymentMethod: 'VNPAY'` (web dùng), trả `paymentUrl` như MoMo.
- **Thay đổi:** `checkout_screen.dart` — thêm `'VNPAY'` vào `_paymentMethods` (nhãn "VNPAY (QR/ATM/Visa)", icon `QrCode` hoặc `account_balance_wallet`). Luồng xử lý `paymentUrl` (dialog Copy URL / Pay now mở ngoài) **dùng lại nguyên trạng** — không code mới ngoài lựa chọn.
- **Lỗi:** server lỗi → SnackBar hiện có. Không thêm xử lý riêng.

## F2 — Màn chi tiết đơn hàng

- **API:** `GET /api/orders/{orderNumber}` — yêu cầu đăng nhập, trả order + orderItems (kèm product ảnh) + payment. Response shape khớp `serializeOrder` của web.
- **Mới:** `order_api_service.getOrder(orderNumber)`, `order_repository.getOrder(orderNumber)`, DTO mở rộng nếu thiếu trường (payment, deliveryFee, discount), `order_detail_screen.dart`.
- **Điều hướng:** Profile → Order History tile → `Navigator.push` OrderDetailScreen(orderNumber).
- **UI:** header (mã đơn + badge trạng thái), danh sách món (ảnh/tên/SL/giá), tạm tính → giảm giá → phí giao → tổng cộng, phương thức + trạng thái thanh toán, ngày nhận/địa chỉ, ngày đặt. Trạng thái lỗi 404 → thông báo + nút quay lại.
- **Guest:** không có (endpoint yêu cầu đăng nhập — khớp web).

## F3 — Sổ địa chỉ (CRUD + tích hợp checkout)

- **API:** `GET /api/addresses` (list), `POST /api/addresses` (tạo), `PUT/DELETE /api/addresses/{id}`. Payload: `fullName, phone, street, ward, district, province, isDefault` (validate 1-200 ký tự, phone VN `^(0|\+84)(3|5|7|8|9)\d{8}$`).
- **Mới:** feature `addresses/` (dto/repository/datasource/controller) + màn `addresses_screen.dart` (list + form thêm/sửa trong dialog/bottom sheet + xoá confirm + đặt mặc định).
- **Tích hợp checkout:** khi chọn "Giao tận nơi" — nếu có địa chỉ lưu: radio picker (mặc định chọn `isDefault`), chọn → gửi `addressId` + dòng địa chỉ ghép sẵn; vẫn giữ ô "Nhập địa chỉ mới" (gửi không kèm addressId). Model đơn đã nhận `addressId` (web gửi vậy).
- **Lỗi:** xoá/sửa địa chỉ của người khác → 404 từ server → hiện "Không tìm thấy".

## F4 — Đánh giá sản phẩm

- **API:** `GET /api/products/{id}/reviews` (list + ratingAverage + reviewCount), `POST` cùng endpoint ({rating 1-5, comment ≤2000}) — yêu cầu đăng nhập, mỗi user 1 review/sản phẩm (server chặn, 409 → thông báo "Bạn đã đánh giá sản phẩm này").
- **Mới:** feature `reviews/` (dto/repository/datasource) + section trong `product_detail_screen.dart`: header (sao TB + tổng số), danh sách review (tên/ ngày/ sao/ nội dung), nút "Viết đánh giá" → guest dẫn sang /auth (pattern wishlist), form: star selector + textarea + gửi.
- **Render:** nội dung comment là plain text (Text widget) — không render HTML.

## Kiểm thử

- Mỗi feature: test parse DTO + logic controller/view model (node pattern như test/ hiện có — widget test cho màn mới where feasible).
- Tổng: `fvm flutter analyze` 0 issues, `fvm flutter test` pass.
- Smoke thủ công (controller): VNPAY hiện trong checkout; địa chỉ tạo/sửa/xoá/mặc định; chi tiết đơn mở từ lịch sử; review gửi + hiện.

## Thứ tự triển khai

F1 → F2 → F3 → F4 (tăng dần độ phức tạp; 4 tính năng độc lập kỹ thuật với nhau).

## Ngoài phạm vi

Guest order tracking theo mã đơn, sổ địa chỉ offline-first, chỉnh sửa review đã gửi, ảnh đính kèm review.

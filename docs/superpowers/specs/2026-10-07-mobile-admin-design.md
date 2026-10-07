# Design — Mobile Admin (Full Parity Khu Admin, port từ Web Admin)

*Ngày: 2026-10-07 · Dự án: bakery-mobile (Flutter 3.32.4, fvm-pinned) · Nguồn chuẩn: bakery-web admin (`app/admin/**`, `components/admin/**`, `hooks/admin/**`, `services/admin/**`)*

## Bối cảnh và mục tiêu

App mobile hiện chặn tài khoản ADMIN khi đăng nhập (`auth_view_model.dart:61-63` và `:91-93` — `"Mobile app only supports CUSTOMER accounts"`), kèm 1 bug: login admin bị chặn nhưng **token vẫn được lưu** → lần mở app sau `bootstrap()` vẫn khôi phục admin vào shell customer.

Mục tiêu: đăng nhập được bằng ADMIN trên mobile và có **UI admin full parity với web admin — 15 mục sidebar** (Blog là 1 mục drawer gồm 3 màn con: Bài viết/Danh mục/Thẻ). Backend bakery-web đã hỗ trợ **Bearer token trên toàn bộ `/api/admin/*`** (`getCurrentUserFromRequest`, `lib/session.ts:148`) → **không sửa server**. Toàn bộ work nằm ở client Flutter, theo đúng template feature hiện có.

Ràng buộc: không đổi server; không phá luồng customer hiện có (các nhánh `lib/src/features/{catalog,cart,orders,profile,...}` không sửa); UI theo `AppTheme` hiện có; tiếng Việt cho toàn bộ UI admin; `fvm flutter analyze` 0 issues; mọi test cũ vẫn xanh. Độc lập kỹ thuật với spec `2026-10-03-mobile-feature-parity-design.md` (4 tính năng parity customer — side customer, khác nhánh code).

## Quyết định thiết kế (đã duyệt với chủ dự án)

1. **Phạm vi:** Full parity 15 mục sidebar web admin (Blog gồm 3 màn con); triển khai chia 8 phase (mục "Lộ trình").
2. **Approach A — Mobile-native redesign:** giữ nguyên logic + endpoint + trường dữ liệu của web, đổi cách trình bày cho mobile (bảng → card list, form nhiều cột → section cuộn dọc, drag-drop → `ReorderableListView`).
3. **Điều hướng:** 1 app duy nhất, **role quyết định shell** — login screen dùng chung; `ADMIN` → `AdminShell`, `CUSTOMER` → `MainLayout` như cũ. Roles chỉ có `ADMIN | CUSTOMER`, 1 account 1 role.
4. **Ngôn ngữ:** tiếng Việt toàn bộ (label, nút, dialog, thông báo); mã trạng thái giữ nguyên code gốc (PENDING, CONFIRMED...) kèm nhãn Việt.

## Kiến trúc

### Auth foundation

- Bỏ gate CUSTOMER-only tại `auth_view_model.dart:61-63` (login) và `:91-93` (register verify) — login trả về user mọi role, không chặn ở controller.
- `app_gate.dart` phân nhánh sau `bootstrap()`: `user.role == 'ADMIN'` → `AdminShell`; ngược lại → `MainLayout` (customer). Bootstrap gọi `GET /api/auth/me` như hiện có — role là nguồn sự thật, đồng thời tự sửa bug token-leak ở trên.
- Logout admin: xoá token (`token_storage.dart`) → về AuthScreen (thay toàn bộ stack). `POST /api/auth/logout` như hiện có.
- Token vẫn lưu SharedPreferences key `bakery_auth_token` (không chuyển secure-storage trong đợt này — nhất quán flow customer; xem "Ngoài phạm vi").

### AdminShell — `lib/src/features/admin/shell/`

- `Scaffold` gồm **AppBar topbar** (hamburger + tiêu đề section hiện tại + menu avatar: Đăng xuất) và **Navigation Drawer 15 mục**, nhóm giống `AdminSidebar` web:
  - *Tổng quan*: Tổng quan (Dashboard)
  - *Bán hàng*: Đơn hàng, Khách hàng, Coupon
  - *Cửa hàng*: Sản phẩm, Danh mục, Bộ lọc sản phẩm, Thành viên, Banner
  - *Nội dung*: Blog (Bài viết / Danh mục / Thẻ), Trang tĩnh, Thông báo, Menu
  - *Hệ thống*: Nhật ký hệ thống, Cài đặt
  - Footer drawer: tên + email người đăng nhập (mirror web).
- Body là **nested `Navigator`** riêng (GlobalKey<NavigatorState>): chọn mục drawer = thay root stack admin; màn chi tiết/form push lên trên. Drawer + topbar luôn hiển thị — mirror `AdminShell` web. Màn admin không có AppBar riêng (dùng topbar chung, title đổi theo section).
- Quỹ đạo 401: mọi lỗi 401 từ API admin → xoá token → đẩy AuthScreen thay toàn bộ stack. 403 → snackbar "Không có quyền".

### Tổ chức code & shared widgets

- Feature folder: `lib/src/features/admin/<module>/{data/{datasources,dtos,repositories},domain/models,presentation/{controllers,screens,widgets}}` — đúng convention hiện có; controller là Riverpod `Notifier`; đăng ký provider trong `core/di/data_providers.dart` + `core/di/app_providers.dart`.
- `lib/src/features/admin/shared/`:
  - `admin_list_scaffold` — tìm kiếm (server-side) + filter chip + phân trang cuộn vô hạn + 3 trạng thái chuẩn (loading / empty có CTA / error có thử lại). Dùng lại cho ~10 module.
  - `status_pill` + bảng màu port từ `ORDER_STATUS_COLORS` (`lib/admin-data.ts:480`) — amber PENDING, blue CONFIRMED, orange PROCESSING, teal READY, green COMPLETED, red CANCELLED; nhãn Việt: PENDING=Chờ xác nhận, CONFIRMED=Đã xác nhận, PROCESSING=Đang chuẩn bị, READY=Sẵn sàng nhận, COMPLETED=Hoàn thành, CANCELLED=Đã huỷ (pill hiển thị nhãn Việt, giữ mã gốc trong tooltip/subtitle khi cần tra cứu dữ liệu web).
  - `audit_log_list` — list audit dùng ở order detail + product edit (endpoint audit riêng từng entity).
  - `image_upload_field` — `image_picker` → base64 data URL → `POST /api/upload` (JSON, không multipart), nhận `{url, publicId}`; validate ≤5MB/ảnh, ≤5 ảnh/request, chấp nhận png/jpeg/webp/avif/heic; hành vi xoá khỏi form giữ như web (URL chỉ ghi DB khi Lưu; không gọi `/api/upload/delete` khi chỉ bỏ khỏi form).
  - `money_text` + `date_text` — `intl` vi-VN (`formatVND` tương đương `lib/admin-data.ts:464`; ngày `vi-VN`).
  - `vnd_input` — ô nhập tiền VND (format nhóm nghìn khi gõ).
  - `confirm_dialog` — xác nhận phá huỷ (thay AlertDialog web).
- **Package mới:** `fl_chart` (biểu đồ dashboard), `image_picker`, `pdf` + `printing` (hoá đơn; nhúng font TTF hỗ trợ dấu tiếng Việt, ví dụ Be Vietnam Pro/Roboto — cần thêm asset font), `intl`, `share_plus` (share CSV/PDF).
- Theming: tái dùng `AppTheme` (primaryPink khớp brand web); chuỗi tiếng Việt hardcode inline (không thêm l10n).
- Landing sau login admin = **Tổng quan** (tương đương redirect `/admin` → `/admin/dashboard` trên web; mobile không có khái niệm URL).

## Spec 16 module

Quy ước chung: mọi endpoint trả envelope `{success, data}` (ApiClient tự unwrap); mọi `/api/admin/*` server tự enforce ADMIN (`requireAdmin`) — client gate chỉ là điều hướng, không phải security boundary. Tham chiếu contract: `bakery-web/tests/admin/*` (13 file test route).

### Nhóm Bán hàng

**1. Tổng quan (Dashboard)** — `GET /api/admin/dashboard?windowDays={7|14|30}`
- KPI lưới card 2×2: Đơn hôm nay, Doanh thu hôm nay, Tỷ lệ chuyển đổi, Trạng thái đơn (`kpi`, `orderStates`).
- Segmented chip chọn 7/14/30 ngày; 2 biểu đồ area (số đơn + doanh thu) vẽ `fl_chart` thay Recharts (gradient + tooltip tương đương, chấp nhận sai khác thẩm mỹ nhỏ); source `chartData[{day, orders, revenue, completedOrders, cancelledOrders}]`.
- "Đơn mới nhất" top 5 (`recentOrders`) — tap → chi tiết đơn.
- Polling 5 phút như web (Timer periodic trong view model, `refreshIntervalSeconds:300` từ meta) + refresh tay.
- Lưu ý: doanh thu chỉ tính đơn COMPLETED, bucket ngày theo TZ `Asia/Ho_Chi_Minh` — đã xử lý server-side, mobile chỉ vẽ.

**2. Đơn hàng** — list + chi tiết
- *List* `GET /api/admin/orders?page&limit&search&status` (limit max 50): list card — số đơn, khách, tổng tiền, phương thức thanh toán, status pill, thời gian tạo. Tìm kiếm server-side (orderNumber/tên/SĐT khách); filter chip nhanh ALL + 6 trạng thái; phân trang cuộn.
- *Export CSV trang hiện tại* (parity web — Blob UTF-8 BOM): cột Order Number, Customer, Phone, Email, Address, Subtotal, Delivery Fee, Discount, Total, Payment Method, Payment Status, Status, Created At → ghi file + `share_plus` share sheet.
- *Chi tiết* `GET /api/admin/orders/{id}` (id **hoặc orderNumber**): items kèm thumbnail + message cá nhân hoá bánh + phân tích tiền (subtotal → deliveryFee → discount → total, luôn coerce `Number`); card Khách hàng (tên, SĐT, email, địa chỉ, ngày nhận); card Thanh toán (phương thức, provider, transactionId, trạng thái).
- *Đổi trạng thái* `PATCH /api/admin/orders/{id}` — chip **chỉ hiện transition hợp lệ** (map mirror web `NEXT_STATUSES`): PENDING→CONFIRMED|CANCELLED; CONFIRMED→PROCESSING|CANCELLED; PROCESSING→READY; READY→COMPLETED; COMPLETED/CANCELLED terminal. Server vẫn enforce lại.
- *Huỷ đơn*: bắt buộc nhập lý do (bottom sheet, gửi `{status: 'CANCELLED', notes}`); dialog xác nhận.
- *In hoá đơn*: dựng PDF khớp template hoá đơn web (header store, items, totals) → dialog in Android (`printing`) + share PDF.
- *Audit đơn* `GET /api/admin/orders/{id}/audit` — `audit_log_list` expandable.
- *Investigation* `GET /api/admin/orders/{id}/investigation` — section mở rộng: trạng thái đơn, trạng thái payment, timeline payment-callback (top 10), các lần reconciliation (top 10).

**3. Khách hàng** — `GET /api/admin/customers?page&limit&search&level`
- List card: avatar (chữ cái đầu), tên/email, badge hạng (SILVER/GOLD/PLATINUM — màu gold/silver/platinum như web), điểm, số đơn, tổng chi; filter chip hạng; tìm kiếm server-side.
- Chi tiết `GET /api/admin/customers/{id}` (screen riêng thay slide-over web): 3 card thống kê (Tổng đơn / Tổng chi / Điểm), Đơn gần đây, Thanh toán gần đây, Thông báo gần đây + số chưa đọc (`notificationSummary`).
- Sửa: bottom sheet gửi `PATCH /api/admin/customers/{id}` `{memberLevel?, points?}` (chỉ 2 trường này — web cũng vậy).

### Nhóm Cửa hàng

**4. Sản phẩm** — list + form
- *List* `GET /api/admin/products?page&limit&search`: card ảnh + tên + giá + tồn kho + pill trạng thái; tìm kiếm server-side; filter trạng thái + danh mục (lọc client trên trang hiện tại — như web); **multi-select nhấn giữ** → xoá hàng loạt (loop `DELETE /api/admin/products/{id}` từng id — parity web); FAB "Thêm sản phẩm".
- *Form* (screen full, section cuộn dọc + sticky bottom bar; tách file widget theo section — không gom 1 file 1001 dòng như web):
  - ① Thông tin: tên (slug tự sinh theo web), danh mục chọn 1 (cây cha/con), giá VND, switch Bật bán, mô tả ngắn + đầy đủ.
  - ② Ảnh: tối đa 10, gallery/camera, preview cục bộ defer upload đến Lưu (parity web), chạm ảnh → đặt chính / xoá; `images[{url,isPrimary}]`.
  - ③ Biến thể: dòng động (tên, SKU, giá, tồn kho) — `variants[]`.
  - ④ Bộ lọc: chip multi-select theo attribute (`attributeAssignments[{attributeId, valueIds[]}]`; SELECT chọn 1, MULTI_SELECT chọn nhiều).
  - Nút: Lưu nháp (isActive=false) / Xuất bản (isActive=true); edit mode hiện audit log `GET /api/admin/products/{id}/audit`.
  - Payload create/update: `GET/POST /api/admin/products`, `GET/PUT/DELETE /api/admin/products/{id}`.
  - **Bỏ 2 field cosmetic web** (type toggle CAKE/INGREDIENT, SEO metaTitle/metaDescription — web không lưu).

**5. Danh mục** — `GET/POST /api/admin/categories`, `GET/PUT/DELETE /api/admin/categories/{id}`, `PATCH /api/admin/categories/reorder`
- Cây 2 cấp, card có ảnh + tên + slug + số sản phẩm + thứ tự; **sắp xếp danh mục gốc** bằng `ReorderableListView` + thanh "Lưu thứ tự" (`{items:[{id, displayOrder}]}` — chỉ root, như web); nút thêm con / sửa / xoá.
- Xoá bị server chặn khi còn sản phẩm/con → snackbar giải thích (không tự pre-check như web — trust server message).
- Dialog form: ảnh (upload), danh mục cha (select), tên, slug, mô tả, thứ tự hiển thị.

**6. Bộ lọc sản phẩm (attributes)** — `GET/POST /api/admin/product-attributes`, `GET/PUT/DELETE .../{id}`
- Card list (tên, code, kiểu, số giá trị, switch trạng thái).
- Dialog form: tên, slug, code, kiểu (SELECT/MULTI_SELECT/TEXT/NUMBER/BOOLEAN), mô tả, thứ tự, 4 switch (isRequired/isFilterable/isVariantAxis/isActive), textarea giá trị (mỗi dòng 1 giá trị → `values[]`).

### Nhóm Nội dung

**7. Banner** — `GET/POST /api/admin/banners`, `GET/PUT/DELETE .../{id}`, `PATCH .../reorder`
- Card ảnh lớn; `ReorderableListView` + thanh "Lưu thứ tự" (`{items:[{id, displayOrder}]}`); switch hoạt động ngay trên card.
- Dialog form: tiêu đề, mô tả, linkUrl, ảnh (upload), hoạt động.

**8. Thông báo (broadcast)** — `GET/POST /api/admin/notifications?page&limit&search&status`, `GET/PUT/DELETE .../{id}`
- List card pill DRAFT/PUBLISHED/ARCHIVED; tìm kiếm + filter trạng thái; đổi trạng thái nhanh bằng menu chip trên card.
- Bottom-sheet form: tiêu đề, nội dung, ảnh (upload), linkUrl, trạng thái, thời gian publish (datetime picker).

**9. Blog** — 3 màn con trong 1 mục drawer
- *Bài viết* `GET/POST /api/admin/blog/posts?page&limit&search&categoryId&tagId&status`, `GET/PUT/DELETE .../{id}`, `PATCH .../{id}/status` `{DRAFT|PUBLISHED|ARCHIVED}`: list card thumbnail + pill trạng thái + filter (trạng thái, danh mục); đổi trạng thái nhanh menu chip. **Form screen full** (nội dung dài, không dùng dialog): tiêu đề, slug, tóm tắt, nội dung multiline thuần (web cũng chỉ textarea — không rich editor), ảnh cover (upload), danh mục (select), tags (chip multi-select), trạng thái; section thu gọn "Nâng cao" chứa metaTitle/metaDescription (blog lưu thật các field này — khác product).
- *Danh mục blog* `GET/POST /api/admin/blog/categories`, `GET/PUT/DELETE .../{id}`: CRUD nhỏ — card list + dialog (tên, slug).
- *Thẻ* `GET/POST /api/admin/blog/tags`, `GET/PUT/DELETE .../{id}`: như danh mục.

**10. Trang tĩnh (Pages)** — `GET/POST /api/admin/pages`, `GET/PUT/DELETE .../{id}`
- List + filter published/draft; form screen full: tiêu đề, slug, nội dung multiline, switch Xuất bản. (Nội dung render qua template customer `page_templates.dart` — chỉ quản lý text.)

**11. Menu điều hướng** — `GET/POST /api/admin/menu`, `GET/PUT/DELETE .../{id}`
- Danh sách cây thụt đầu dòng + icon theo loại (CATEGORY/PAGE/LINK).
- Dialog form cascade: chọn loại → hiện đúng 1 trong 3 (url / chọn danh mục / chọn trang tĩnh), chọn mục cha (parent), thứ tự, switch hoạt động.

### Nhóm Hệ thống

**12. Coupon** — `GET/POST /api/admin/coupons`, `PUT/DELETE .../{id}`
- Card: code, giảm giá (PERCENTAGE/FIXED), hiệu lực (startAt–endAt), đã dùng, switch bật/tắt.
- Dialog form: code, kiểu PERCENTAGE/FIXED, giá trị, bắt đầu/kết thúc (datetime picker), giới hạn lượt; xoá có xác nhận.

**13. Thành viên (Membership)** — `GET/PUT /api/admin/membership`
- 3 card hạng SILVER/GOLD/PLATINUM (số thành viên, điểm tối thiểu, % giảm — nhập liệu); ô điểm/đơn (`pointsPerOrder`).
- **Máy mô phỏng trực tiếp** (nhập điểm/đơn → hạng + điểm đạt, tính client-side như web); nút Lưu → `PUT` payload `{levels:[{level,minPoints,discountPercent}], pointsPerOrder}`.

**14. Cài đặt** — `GET/PUT /api/admin/settings`
- Form section cuộn dọc + sticky Lưu: ① Thông tin cửa hàng (tên, email, điện thoại, địa chỉ, giờ mở cửa) ② Khung giờ nhận hàng (chip list + ô thêm giờ — `pickup_slots[]`) ③ Vận chuyển (switch cho phép giao — `allow_delivery`, phí giao `delivery_fee`, đơn tối thiểu `min_order_amount`, ngưỡng freeship `free_delivery_threshold`).
- **Bỏ form đổi mật khẩu admin** — trên web là UI chết (không wired endpoint).

**15. Nhật ký hệ thống (Audit)** — `GET /api/admin/audit?page&limit&module&entity&actorUserId&mutationType&from&to`
- Card: thời gian, actor, hành động (mutationType + module), entity, tóm tắt; filter text module + entity; tap → mở rộng correlation (requestId, httpMethod, route, orderId, transactionId); phân trang.

## Bảng quyết định parity (web ↔ mobile)

| Tình huống | Quyết định |
|---|---|
| Product type toggle + SEO meta (web không lưu) | Bỏ trên mobile |
| Đổi mật khẩu admin trong Settings (web không wired) | Bỏ trên mobile |
| Export CSV đơn hàng | Giữ — file CSV + share sheet, chỉ trang hiện tại như web |
| In hoá đơn | PDF khớp template web → dialog in Android + share PDF |
| Polling dashboard 5 phút | Giữ (Timer + refresh tay) |
| Coupon nằm ngoài dashboard shell trên web (quirk layout) | Bỏ quirk — đặt trong drawer nhóm Bán hàng |
| Giới hạn upload | Client validate ≤5MB/ảnh, ≤5 ảnh/request, ≤10 ảnh/sản phẩm (theo server cap `app/api/upload/route.ts`) |
| Slide-over khách hàng, bảng rộng, hover-only image actions | Đổi thành screen riêng / card list / chạm để thao tác |
| Session refresh (`POST /api/auth/refresh` rotation) | Không thêm — flow customer hiện cũng không refresh; hết hạn → 401 → đăng nhập lại (xem Ngoài phạm vi) |

## Luồng dữ liệu và lỗi

- Mọi request qua `ApiClient` hiện có: Bearer tự gắn từ `token_storage`, unwrap `{success, data}`, lỗi ném `ApiException` (`core/network/api_exception.dart`).
- Hành động CRUD → snackbar kết quả (thay toast web). Phá huỷ (xoá sản phẩm/danh mục/coupon/banner..., huỷ đơn) → `confirm_dialog`; huỷ đơn bắt buộc lý do.
- 401 → xoá token → AuthScreen thay toàn bộ stack admin. 403 → snackbar "Không có quyền".
- List scaffold 3 trạng thái chuẩn (loading/empty/error-retry); loading dùng pattern hiện có của app (không thêm shimmer).

## Kiểm thử

- **Unit** (pattern hiện có — fake API service + `ProviderScope.overrides`): parse DTO nullable (comparePrice, payment, userId, meta...); logic ưu tiên: map transition trạng thái đơn, máy mô phỏng membership, builder CSV, sinh slug.
- **Widget**: drawer admin đủ 15 mục + điều hướng; chip trạng thái đơn chỉ hiện transition hợp lệ; validate form sản phẩm (tên, giá, slug); membership simulator.
- **Integration**: mở rộng `integration_test/app_e2e_test.dart` — flow admin (login admin → dashboard load → orders list → đổi status đơn).
- **Thủ công trên emulator Android**: mỗi phase chạy pass toàn bộ màn mới + chụp screenshot vào `gui-test-screenshots/`.
- **Regression**: 7 test file hiện có phải xanh; `fvm flutter analyze` 0 issues; luồng customer không đổi hành vi.
- Tham chiếu contract API: `bakery-web/tests/admin/*`.

## Lộ trình 8 phase (mỗi phase = 1 chu kỳ plan chi tiết → triển khai → test → verify emulator → commit)

| Phase | Nội dung | Deliverable |
|---|---|---|
| 0 | Auth role-branch + fix bootstrap token-leak; AdminShell + drawer + topbar; shared widgets; DI scaffolding; thêm packages | Login admin → shell rỗng điều hướng được, logout OK; customer không đổi |
| 1 | Dashboard | KPI, fl_chart, polling, đơn mới nhất |
| 2 | Đơn hàng | List + CSV, chi tiết + transition + huỷ + PDF + audit + investigation |
| 3 | Khách hàng | List + chi tiết + sửa hạng/điểm |
| 4 | Sản phẩm, Danh mục, Bộ lọc | Form đầy đủ + upload ảnh + reorder — phase nặng nhất |
| 5 | Banner, Thông báo, Blog ×3, Trang tĩnh, Menu | Nhóm nội dung |
| 6 | Coupon, Thành viên, Cài đặt, Nhật ký | CRUD nhẹ |
| 7 | E2E + polish + regression toàn diện | Cả customer lẫn admin; nghiệm thu |

Thứ tự theo giá trị nghiệp vụ: vận hành đơn hàng trước (việc chủ shop hay làm nhất trên di động), catalog nặng sau, CRUD nhẹ cuối.

## Ngoài phạm vi

- `l10n`/multi-language infra (hardcode tiếng Việt như codebase hiện có); dark mode; flutter_secure_storage migration; token refresh rotation; iOS verification (chỉ bảo đảm compile — verify trên Android emulator như môi trường hiện có); push notification cho admin (web cũng không có — dashboard polling là parity); refactor phần customer; bổ sung endpoint mới phía server; quản lý user/role (web cũng không có trang này — roles là enum cố định).

## Rủi ro

- `fl_chart` không map 1-1 Recharts gradient/tooltip → chấp nhận sai khác thẩm mỹ nhỏ, giữ đúng dữ liệu.
- PDF tiếng Việt cần font TTF có glyph dấu → thêm asset font (Be Vietnam Pro hoặc Roboto) cho package `pdf`.
- Upload ảnh qua mạng di động (5MB/ảnh) → validate client trước khi gửi, hiện progress.
- Form sản phẩm là phức tạp nhất → tách widget theo section + test từng phần, đặt ở phase 4 sau khi shared widgets ổn định.

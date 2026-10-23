# bakery-mobile — hướng dẫn cho Claude

App Flutter của tiệm bánh (khách hàng + khu quản trị cho ADMIN). Backend là **bakery-web** (Next.js,
thư mục anh em `../bakery-web`) — app gọi `app/api/**` của web qua `API_BASE_URL` trong `.env`.

@CONTRIBUTING.md

## Lệnh

Luôn dùng **fvm** (Flutter ghim trong `.fvmrc`). `flutter` global là bản khác: test widget sẽ lỗi
shader `ink_sparkle` và `pub get` sửa lung tung file ios/android.

- `bash scripts/validate.sh` — gate trước PR (format file đổi · analyze · test)
- `fvm flutter test [test/<file>_test.dart]` · `fvm flutter analyze` · `fvm dart format <files>`
- Chạy app — môi trường chọn lúc build (xem CONTRIBUTING.md "Môi trường"):
  - Android: `fvm flutter run --flavor dev --dart-define-from-file=config/dev.json` (bắt buộc `--flavor` vì có productFlavors)
  - iOS: `fvm flutter run --dart-define-from-file=config/dev.json` (chưa có scheme theo flavor)
  - `.env` (`API_BASE_URL`) chỉ là override cục bộ cho **dev** (vd máy thật dùng IP LAN); bản prod bỏ qua `.env`.
- `fvm flutter test integration_test/app_e2e_test.dart -d <device> --flavor dev --dart-define-from-file=config/dev.json` (thêm `--dart-define=E2E_WRITE=true` để chạy cả bước tạo dữ liệu thật: lưu địa chỉ, đặt đơn, gửi chatbot) — e2e, cần emulator

## Kiến trúc

- `lib/src/core/` — `network/` (`ApiClient`, `ApiException`), `di/` (`app_providers.dart` cho view model,
  `data_providers.dart` cho service/repository), `theme/`, `storage/`, `auth/` (`SessionManager`), `utils/`.
- `lib/src/features/<feature>/` — feature-first, mỗi feature chia tầng:
  `data/{datasources,dtos,repositories}` → `domain/models` → `presentation/{controllers,screens,widgets}`
  (+ `application/services` khi có nghiệp vụ nhiều bước).
- `lib/src/shared/` — dùng chung toàn app, **không gắn nghiệp vụ của một feature**:
  - `widgets/` — UI tái sử dụng: ảnh mạng (`AppNetworkImageWidget`), loading/lỗi/rỗng (`LoadingWidget`,
    `ErrorRetryWidget`, `EmptyStateWidget`), giá + badge giảm giá (`PriceWidget`, `DiscountBadgeWidget`),
    card/dòng thông tin (`SectionCardWidget`, `InfoRowWidget`, `SummaryRowWidget`), `OrderStatusPillWidget`,
    `InitialAvatarWidget`, `FavoriteIconWidget`, `AppTextInputWidget`, các `Skeleton*Widget`,
    `OfflineBannerWidget` (gắn ở `main.dart`).
  - `utils/` — `format_utils.dart` (`formatVnd`, `formatDateVi`, `formatDateTimeVi`), `order_status_display.dart`,
    `error_message.dart` (`userErrorMessage(error)` — luôn dùng thay vì `error.toString()`).
- Khu admin: `lib/src/features/admin/{shell,shared,dashboard,orders,…}`; `AdminShell` chọn màn theo `AdminSection`.
- State: Riverpod 2 `Notifier` + state class immutable có `copyWith`; provider khai báo tập trung ở `core/di/`.

## Quy ước code

- Datasource trả JSON thô; DTO parse phòng thủ (field thiếu → mặc định); tiền từ server là **string**
  (`"900000.00"`) → coerce bằng helper (`admin/shared/utils/json_num.dart`).
- Chuỗi UI tiếng Việt viết trực tiếp.
- Lỗi 401 ở khu admin → `authViewModelProvider.notifier.logout()` (AppGate tự về màn login).
- Lỗi request: `ApiException.kind` (`network`/`timeout`/`server`/`unauthorized`/`client`) — quyết định theo loại,
  không theo chuỗi; hiển thị bằng `userErrorMessage`. Trạng thái mạng: `isOnlineProvider` (`core/network/connectivity.dart`);
  `ErrorRetryWidget` tự hiện "Mất kết nối" và tự thử lại khi có mạng.
- Test: fake repository/service (subclass + override) + `ProviderContainer(overrides: …)`; DTO test bằng
  payload giống server thật. Mỗi thay đổi hành vi đi kèm test.
- **Trước khi viết UI mới, xem `lib/src/shared/widgets/`** — dùng widget có sẵn (chọn đúng `variant`) thay vì
  tự viết `Image.network`/spinner/khối lỗi/giá/badge. Thấy cùng một đoạn UI ở ≥ 2 feature → đưa vào `shared/widgets`.
- Quy ước `shared/widgets`: **mỗi file một public widget**; tên file `<tên>_widget.dart`, tên class `<Tên>Widget`;
  biến thể khai báo bằng `enum <Tên>Variant` trong cùng file (vd `PriceVariant.card`), không tạo class riêng cho từng
  biến thể. Widget gắn nghiệp vụ một feature (vd `AdminPagedList`) ở lại trong feature đó.
- Tiền luôn hiển thị qua `formatVnd` (`120.000 ₫`); ngày qua `formatDateVi`/`formatDateTimeVi` (nhớ `.toLocal()`).
- **Không viết số trần cho spacing/màu/bo góc/thời lượng** — dùng token trong `lib/src/core/theme/`:
  `AppSpacing` (lưới 4px: `xxs` 2 · `xs` 4 · `sm` 8 · `md` 12 · `lg` 16 · `xl` 20 · `xxl` 24 · `x3l` 32 · `x4l` 40 ·
  `x5l` 48) cho `EdgeInsets`/`spacing:`; khoảng cách giữa phần tử anh em dùng `Gap(AppSpacing.md)` (package `gap`)
  trong `Row`/`Column`/`ListView` thay vì `SizedBox(height/width:)`; `AppRadius`, `AppDurations`, màu `AppTheme.*`.
  Giá trị ngoài thang là kích thước bố cục (vd khoảng chừa thanh điều hướng) → hằng có tên trong file đó.
  Ngoại lệ: `invoice_pdf.dart` dùng đơn vị point của PDF, không theo token màn hình.
- Tái dùng widget/helper có sẵn trước khi viết mới; xem feature gần nhất làm mẫu.

## Quy tắc riêng cho Claude

- **Nhánh**: nếu đang ở `master`/`dev`, dùng skill `start-task` trước khi sửa code. Hook
  `.claude/hooks/guard-git.sh` chặn commit trên master/dev, push thẳng, force push, `--no-verify`, `gh pr merge`.
- **Xong task** = `bash scripts/validate.sh` xanh (skill `validate`) → skill `open-pr`. Không báo "xong" khi
  chưa chạy gate; bỏ bước nào thì nói rõ.
- **Commit**: chỉ stage file thuộc task, không stage thay đổi có sẵn của người dùng trừ khi được yêu cầu.
  `ios|macos/Podfile` và dòng `#include? "Pods/…"` trong `*.xcconfig` đã được track — nếu `pub get` đổi chúng
  ngoài ý muốn thì hỏi trước khi commit. Message theo Conventional Commits, kết thúc bằng dòng `Co-Authored-By`
  theo cấu hình của phiên.
- **Format**: chỉ `fvm dart format` các file mình sửa — không format cả thư mục.
- **API**: cần endpoint/field mới → kiểm tra route trong `../bakery-web/app/api/**` thay vì đoán; ghi phụ
  thuộc vào PR. Không sửa code bakery-web từ repo này.
- **Secrets**: không đọc/in `.env`; biến mới thêm vào `.env.example`.

## Tài nguyên agent trong repo

- `.claude/skills/` — `start-task`, `validate`, `open-pr`, `release` (chỉ khi người dùng yêu cầu).
  `code-review-and-quality` — tiêu chí review 5 trục (vendored từ addyosmani/agent-skills).
- `.claude/agents/code-reviewer.md` — review diff so với `origin/dev`, áp dụng skill `code-review-and-quality`.
- `docs/superpowers/{specs,plans}/` — spec/plan theo ngày; `.superpowers/sdd/<plan>/progress.md` —
  sổ theo dõi khi thực thi plan theo từng task (đọc trước khi "tiếp tục" một plan).
- `.agents/skills/flutter-*` — hướng dẫn Flutter (kiến trúc, state, HTTP/JSON, testing).
- `.claude/settings.local.json` — cấu hình cá nhân, không commit.

# Push notifications (Android)

Thông báo đẩy qua Firebase Cloud Messaging (FCM). Web (`bakery-web`) gửi, app nhận.

| Sự kiện | Ai nhận | Bấm vào mở |
|---|---|---|
| Admin đổi trạng thái đơn (xác nhận, chuẩn bị, sẵn sàng, hoàn tất, huỷ) | Chủ đơn (có tài khoản) | Chi tiết đơn |
| Đặt đơn / thanh toán online xong | Chủ đơn | Chi tiết đơn |
| Admin đăng thông báo chung | Mọi máy đã đăng nhập ít nhất một lần (topic `announcements`) | Màn Thông báo |

Khi app đang mở, thông báo hiện dạng SnackBar có nút "Xem" (Android không tự hiện).

## Cài đặt một lần

### 1. Tạo project Firebase (miễn phí)

1. Vào <https://console.firebase.google.com> → **Add project** → đặt tên (vd `phuong-loan-bakery`).
   Google Analytics: tắt cũng được.
2. **Add app → Android**, package name `vn.phuongloan.bakery` → Register app.
3. Thêm app Android thứ hai cho bản dev: `vn.phuongloan.bakery.dev`.
4. Tải **`google-services.json`** (sau khi thêm đủ 2 app, file chứa cả hai) và đặt vào
   `android/app/google-services.json`. Bỏ qua các bước "Add Firebase SDK" của console — đã có sẵn.

`google-services.json` không phải bí mật (chỉ định danh project); commit để mọi máy build đều có push.
Thiếu file này app vẫn build và chạy, chỉ tắt push (log `Push notifications off`).

### 2. Cho web quyền gửi

1. Firebase console → ⚙️ **Project settings → Service accounts → Generate new private key** → tải file JSON.
   **File này là bí mật** — không commit, không gửi qua chat.
2. Vercel → project bakery-web → **Settings → Environment Variables** (Production), lấy từ file JSON:

   | Biến | Lấy từ |
   |---|---|
   | `FIREBASE_PROJECT_ID` | `project_id` |
   | `FIREBASE_CLIENT_EMAIL` | `client_email` |
   | `FIREBASE_PRIVATE_KEY` | `private_key` (dán nguyên chuỗi, kể cả `\n`) |
   | `PUSH_TX_ENABLED` | `true` |

3. Redeploy bakery-web để nhận biến mới. Xoá file JSON trên máy sau khi đã dán.

### 3. Build app

`fvm flutter build appbundle --flavor prod --dart-define-from-file=config/prod.json` như thường lệ.
Lần đầu mở app sau khi đăng nhập, Android 13+ hỏi quyền thông báo.

## Thử nhanh

- **Từ console**: Firebase → Messaging → **New campaign → Notifications** → gửi tới topic `announcements`
  (hoặc "Send test message" với FCM token, xem trong log debug).
- **Từ web**: đăng nhập app bằng tài khoản khách, đặt một đơn, rồi trên trang admin đổi trạng thái đơn đó
  → máy nhận "Đơn hàng đã được xác nhận".
- **Thông báo chung**: admin → Thông báo → tạo và đăng → mọi máy nhận.

Nhật ký gửi: bảng `PushNotificationLog` và `NotificationDispatch` (cột `channel` có `PUSH` khi gửi được).

## Code

- App: `lib/src/core/push/push_messaging.dart` (bọc Firebase; `DisabledPushMessaging` khi chưa cấu hình),
  `features/notifications/application/services/push_registration_service.dart` (đăng ký/gỡ token, topic),
  `features/notifications/presentation/widgets/push_notifications_host.dart` (SnackBar, mở màn khi bấm).
- Android: kênh `bakery_default` tạo trong `MainActivity.kt`, tên trong `res/values/strings.xml`;
  plugin `com.google.gms.google-services` chỉ bật khi có `google-services.json`.
- Web: `lib/notifications/firebase.ts` (gửi theo token / topic), `lib/notifications/dispatcher.ts`
  (nội dung tiếng Việt, ai nhận), `app/api/notifications/device-token` (đăng ký/gỡ token).

## Chưa làm

- **iOS**: cần Apple Developer account, APNs key upload lên Firebase, `GoogleService-Info.plist`,
  capability Push Notifications + Background Modes. Không có file thì iOS chạy với push tắt.
- Icon nhỏ riêng cho thông báo (hiện dùng icon app, Android vẽ thành khối một màu).
- Token API mới (Installation ID) của firebase_messaging 17 — cần đổi cả web và app cùng lúc.

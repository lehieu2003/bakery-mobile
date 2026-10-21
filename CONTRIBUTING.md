# Quy trình làm việc (Git workflow & governance)

Áp dụng cho mọi người và mọi agent (Claude, Codex…). Các quy tắc được ép bằng git hooks
(`.githooks/`), CI (`.github/workflows/ci.yml`) và hook của Claude (`.claude/hooks/`).

## Nhánh

| Nhánh | Vai trò | Thay đổi bằng |
|---|---|---|
| `master` | Code production — build/deploy từ đây | PR từ `release/*` hoặc `hotfix/*` (merge commit) |
| `dev` | Nhánh tích hợp — mọi task merge vào đây | PR từ nhánh task (squash merge) |
| `<type>/<mô-tả>` | Một task | Commit trực tiếp |

**Không commit / push trực tiếp lên `master` hay `dev`.**

Repo private trên gói GitHub Free nên không bật được branch protection phía server. Thay vào đó,
workflow `protected-branch-guard.yml` kiểm tra mọi push vào `master`/`dev`: commit phải là merge của
một PR vào đúng nhánh đó. Push thẳng hoặc force push sẽ làm workflow fail và **tự tạo issue cảnh báo**.
Khi nâng GitHub Pro, bật branch protection (bắt buộc PR + check `test` xanh) để chặn hẳn.

Tên nhánh task: `<type>/<mô-tả-kebab-case>` — chữ thường, số, `.`, `_`, `-`.

| type | Dùng cho | Tách từ → PR vào |
|---|---|---|
| `feature` | Tính năng mới | `dev` → `dev` |
| `fix` | Sửa lỗi | `dev` → `dev` |
| `refactor`, `perf`, `test`, `docs`, `chore`, `ci` | Tương ứng | `dev` → `dev` |
| `hotfix` | Lỗi production khẩn cấp | `master` → `master` (rồi đồng bộ lại `dev`) |
| `release` | Chuẩn bị phát hành `X.Y.Z` | `dev` → `master` |

Ví dụ: `feature/orders-csv-export`, `fix/checkout-vnpay-callback`, `release/1.4.0`.

## Commit message — Conventional Commits

```
<type>(<scope>): <mô tả ngắn, mệnh lệnh>      ← header ≤ 100 ký tự

<body: vì sao thay đổi, ảnh hưởng — tuỳ chọn>

<footer: BREAKING CHANGE: …, Refs #123 — tuỳ chọn>
```

- `type` ∈ `feat` `fix` `chore` `docs` `refactor` `test` `perf` `build` `ci` `style` `revert`
- `scope` chữ thường (ví dụ `orders`, `auth`, `admin`, `story-6.2`); thay đổi phá vỡ tương thích thêm `!`: `feat(api)!: …`
- Mỗi commit một ý, build/test được. Không commit secret (`.env`), file build, thay đổi lạ không thuộc task.

Hook `commit-msg` kiểm tra header; CI kiểm tra lại mọi commit trong PR và PR title.

## Vòng đời một task

1. **Tạo nhánh** từ `dev` mới nhất: `git fetch origin && git switch -c feature/xyz origin/dev`
2. **Code + test**, commit theo quy ước.
3. **Validate** (bắt buộc trước PR): `bash scripts/validate.sh` — xem bảng dưới.
4. **Cập nhật với dev** nếu dev đã đi tiếp: `git fetch origin && git rebase origin/dev` (rồi validate lại).
5. **Mở PR vào `dev`** theo template; title theo Conventional Commits (squash merge sẽ dùng title này).
6. **Review + CI xanh** → người review merge bằng **Squash and merge**. Xoá nhánh sau khi merge.

Nhánh nhiều commit có ý nghĩa riêng (ví dụ thực thi plan theo từng task) có thể dùng
**Rebase and merge** để giữ từng commit — mọi commit đều đã qua kiểm tra quy ước.

## Gate trước khi mở PR — `bash scripts/validate.sh`

Script chạy lần lượt (dừng ở bước lỗi đầu tiên); CI chạy đúng script này trên mọi PR:

| # | Bước | Lệnh |
|---|---|---|
| 1 | Tên nhánh | `scripts/git-conventions.sh branch` |
| 2 | Commit messages từ `origin/dev` | `scripts/git-conventions.sh commits origin/dev` |
| 3 | `.env` (tạo từ `.env.example` nếu thiếu — là asset bắt buộc) | — |
| 4 | Dependencies | `fvm flutter pub get` |
| 5 | Format các file `.dart` thay đổi so với `dev` | `fvm dart format --set-exit-if-changed <files>` |
| 6 | Analyze — **0 issues** (kể cả info) | `fvm flutter analyze` |
| 7 | Unit + widget tests | `fvm flutter test` |

Luôn dùng **fvm** (SDK ghim trong `.fvmrc`) — `flutter` global là phiên bản khác.

Ngoài ra, theo loại thay đổi:
- Phụ thuộc endpoint/field mới của **bakery-web** → ghi rõ trong PR; app chỉ release sau khi web đã có.
- Thay đổi luồng chính (đăng nhập, giỏ hàng, checkout) → chạy integration test trên emulator:
  `fvm flutter test integration_test/app_e2e_test.dart -d <device> --flavor dev --dart-define-from-file=config/dev.json`.
- Thay đổi UI → chạy app kiểm tra thủ công, đính kèm ảnh chụp.
- Không stage file do công cụ tự sinh/sửa (`ios|macos/Flutter/*.xcconfig`, `Podfile`, `.env`).

## Môi trường (dev / prod)

| | dev | prod |
|---|---|---|
| Config Dart | `config/dev.json` | `config/prod.json` |
| `API_BASE_URL` | `http://10.0.2.2:3001` (bakery-web local, emulator Android) | `https://phuong-loan-bakery.vercel.app` |
| Android app id / tên | `….dev` / "Bakery Dev" — cài song song với prod | `com.example.bakery_mobile` / "Phương Loan Bakery" |
| Dải "DEV" ở góc | có | không |
| `.env` | override cục bộ (vd IP LAN cho máy thật) | **bị bỏ qua** |

- Chạy: `fvm flutter run --flavor dev --dart-define-from-file=config/dev.json` (iOS: bỏ `--flavor`).
- Build phát hành: `fvm flutter build appbundle --flavor prod --dart-define-from-file=config/prod.json`.
- Build thiếu `API_BASE_URL` sẽ dừng ngay khi khởi động; không truyền `FLAVOR` thì luôn là dev (không bao giờ vô tình thành prod).
- Thêm môi trường (vd staging): thêm `config/<env>.json` + một `productFlavors` trong `android/app/build.gradle.kts`.

## Release & hotfix

- **Release**: `release/X.Y.Z` từ `dev` → bump `version: X.Y.Z+N` trong `pubspec.yaml` (tăng cả build
  number `N`; commit `chore(release): vX.Y.Z`) → validate → PR vào `master` → **merge commit** → tag
  `vX.Y.Z` trên `master` → build store từ tag bằng lệnh build prod ở mục Môi trường.
- **Hotfix**: `hotfix/<mô-tả>` từ `master` → PR vào `master` → sau khi merge, mở PR `master → dev`
  để dev không mất bản sửa.

## Cài đặt local

Sau khi clone: `bash scripts/setup-hooks.sh` (bật git hooks), `cp .env.example .env` (để trống = dùng
`config/dev.json`; điền IP LAN khi chạy máy thật), `fvm install` để cài đúng Flutter SDK. Phiên Claude Code tự bật hooks khi khởi động.
Maintainer cần push thẳng lên nhánh bảo vệ (hiếm, ví dụ khởi tạo): `ALLOW_PROTECTED_PUSH=1 git push …`.

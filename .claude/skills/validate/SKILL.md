---
name: validate
description: Chạy gate kiểm tra trước PR (tên nhánh, commit message, dart format, flutter analyze, flutter test) bằng scripts/validate.sh và sửa cho tới khi xanh. Dùng trước khi mở PR, trước khi báo task hoàn thành, hoặc khi người dùng hỏi "đã pass chưa".
---

# Validate trước PR

Gate duy nhất: `scripts/validate.sh` — CI chạy đúng script này. Không tự chế lệnh khác thay thế.

## Chạy

```bash
bash scripts/validate.sh                       # base mặc định origin/dev
bash scripts/validate.sh --base origin/master  # nhánh hotfix
```

Script tự dùng `fvm flutter` (SDK ghim trong `.fvmrc`). Khi chạy lệnh Flutter lẻ, **luôn dùng `fvm`** —
`flutter` global là bản khác và làm test widget lỗi shader `ink_sparkle`.

## Khi fail

- **Branch name / commit message**: đổi tên nhánh (`git branch -m`) hoặc sửa message
  (`git commit --amend` cho commit cuối; nhiều commit thì hỏi người dùng trước khi rebase).
- **Format**: `fvm dart format <đúng các file được liệt kê>` — KHÔNG format cả thư mục/repo
  (sẽ kéo theo hàng loạt file ngoài task).
- **Analyze / test**: sửa nguyên nhân gốc. Không thêm `// ignore:`, không `skip:` test, không nới
  `analysis_options.yaml`, không xoá test — nếu thật sự cần, hỏi người dùng.
- Lỗi có sẵn từ trước (không do thay đổi của task): báo rõ, không âm thầm sửa lan ra ngoài scope.

## Sau khi chạy

`pub get`/`test` có thể tự sửa `ios/Flutter/*.xcconfig`, `macos/Flutter/*.xcconfig` (dòng `#include? Pods…`)
và sinh `ios/Podfile`, `macos/Podfile` — đó là sản phẩm phụ của công cụ, không stage vào commit của task.

## Báo cáo

Nêu kết quả từng bước với số liệu thật (số test pass/fail, số issue analyze). Integration test
(`integration_test/`, cần emulator) không nằm trong gate — chạy khi task đụng luồng chính và người dùng yêu cầu.

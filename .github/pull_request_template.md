<!-- Title: Conventional Commits, ví dụ `feat(orders): add CSV export` — sẽ là commit squash trên dev. -->

## Tóm tắt

<!-- Thay đổi gì, vì sao. Link plan/spec/issue. -->

## Loại thay đổi

- [ ] feat · [ ] fix · [ ] refactor/perf · [ ] test/docs/chore · [ ] hotfix · [ ] release

## Rủi ro & ảnh hưởng

- [ ] Phụ thuộc API mới/thay đổi của **bakery-web**: <!-- endpoint, PR/commit bên web, hoặc "không" -->
- [ ] Thêm/nâng package (`pubspec.yaml`) hoặc quyền iOS/Android
- [ ] Ảnh hưởng auth / giỏ hàng / checkout / thanh toán
- [ ] Cần biến môi trường mới (đã thêm vào `.env.example`)

<!-- Ghi chú rủi ro, cách rollback nếu cần. -->

## Kiểm tra

- [ ] `bash scripts/validate.sh` xanh (format · analyze 0 issues · flutter test)
- [ ] Đã chạy app kiểm tra thủ công (thiết bị/emulator: …) — ảnh chụp nếu đổi UI
- [ ] Integration test (nếu đụng luồng chính)

```
<!-- Dán kết quả chính: số test pass, analyze "No issues found!" -->
```

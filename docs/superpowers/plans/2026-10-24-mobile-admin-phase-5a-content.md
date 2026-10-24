# Mobile Admin — Phase 5a (Nội dung: Banner + Thông báo + Trang tĩnh) Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 3 mục drawer "Banner", "Thông báo", "Trang tĩnh" hoạt động thật: Banner (list ảnh + CRUD + reorder), Thông báo (list + chips trạng thái + tạo), Trang tĩnh (list + CRUD lite). Blog×3 + Menu thuộc plan 5b.

**Architecture:** Mirror phases 2-4 — mỗi module 1 feature folder data layer + VM + screen; tái dụng `AdminPagedList`, `UploadApiService` (banner image defer upload), pattern 401→logout.

**Tech Stack:** Flutter 3.32.4 (fvm) — không package mới.

**Spec:** `docs/superpowers/specs/2026-10-07-mobile-admin-design.md` mục "5. Content". Contract: bakery-web `app/api/admin/{banners,notifications,pages}/**`.

## Global Constraints

- fvm; analyze 0 + full suite (382 baseline) + **dart format (dùng `git status --short` + diff, gồm file untracked!) TRƯỚC commit**; branch `feature/admin-phase-5a-content`; PR dev; CI xanh mới merge.
- Envelope mọi list `{<key>: [...], pagination?}`; detail/PATCH trả object trực tiếp trừ product (`data.product`) — pin từng fixture bằng test, KHÔNG đoán.
- Banner: list `GET /api/admin/banners` → `data{banners:[{id,title,subtitle?,imageUrl?,linkUrl?,displayOrder,isActive,createdAt}]}` orderBy displayOrder; POST `{title, subtitle?, imageUrl?, linkUrl?, isActive?, displayOrder?}`; PUT `/{id}` partial; DELETE `/{id}`; `PATCH /reorder {orderedIds}` (giống categories — service tự map nếu server cần items; verify bằng curl 1 lần khi T1).
- Notification: `GET /api/admin/notifications?page&limit&search&status` → `data{notifications:[{id,title,content,imageUrl?,linkUrl?,status,audience?,createdAt}], pagination}`; status ∈ DRAFT|PUBLISHED|ARCHIVED; POST `{title, content, imageUrl?, linkUrl?, status? = DRAFT}`.
- Page: `GET /api/admin/pages` → `data{pages:[{id,title,slug,content,isPublished,createdAt}]}`; POST `{title, slug?(auto), content, isPublished?}`; PUT/DELETE `/{id}`.
- Banner image: image_picker → defer upload lúc Lưu (tái dùng `UploadApiService` + facade `imagePickerProvider` của 4b).
- 401→logout; chuỗi Việt; mọi mutation thành công → reload list.

## Review Focus

1. Banner reorder wire shape giống categories (`{items}` hay `{orderedIds}`) — pin bằng curl T1, đừng copy nhầm.
2. Notification POST thiếu title/content → server 400; client gate trước.
3. Page content multi-line gửi nguyên văn (không trim mất xuống dòng).
4. List banner orderBy displayOrder — reorder optimistic rồi reload (giống categories 4a).
5. Xoá banner đang active không cần confirmextra — 1 confirm dialog chuẩn.

---

### Task 1: Data layer 3 module + parse tests
**Files:** `lib/src/features/admin/content/{banners,notifications,pages}/...` (mỗi module: model + dto + api service + repo) + DI (3 cặp providers) + `test/content_admin_dto_test.dart`.
- [ ] Curl 1 banner + 1 notification + 1 page thật (admin token) làm fixture; failing tests pin: banner parse (orderBy field, isActive), banner reorder body (curl PATCH thử trên 2 id thật rồi revert — HOẶC đọc route nguồn nếu không muốn đụng data: đọc `banners/reorder/route.ts`), notification list envelope + status enum parse, page parse (content giữ nguyên)
- [ ] Implement → PASS + gates → commit `feat(admin): content data layer (banners, notifications, pages)`

### Task 2: Banner screen — list + CRUD + reorder
**Files:** `banners/presentation/{controllers/banners_admin_view_model.dart, screens/banners_screen.dart, widgets/banner_edit_sheet.dart}` + admin_shell case banners + `test/banners_admin_vm_test.dart`.
- [ ] VM tests: load; create gửi đúng body (imageUrl defer upload qua fake UploadApiService); update partial; delete; moveUp same-level → reorder orderedIds mới; 401→logout
- [ ] Screen: AdminPagedList không search (banner ít) — list card: ảnh thumb + title + subtitle + pill Đang hiện/Ẩn + lên/xuống; FAB '+'; sheet: title, subtitle, ảnh (picker 1 ảnh + preview), linkUrl, isActive switch; xoá confirm
- [ ] commit `feat(admin): banners screen with crud and reorder`

### Task 3: Notifications screen — list + filter + create
**Files:** `notifications/presentation/{controllers,presentation...}` + shell case + `test/notifications_admin_vm_test.dart`.
- [ ] VM tests: load + hasMore; search server-side; status filter chip (Tất cả/DRAFT/PUBLISHED/ARCHIVED); create gate thiếu title/content; create thành công reload; 401→logout
- [ ] Screen: AdminPagedList searchHint 'Tìm thông báo…', chips trạng thái, card title + content 2 dòng + pill trạng thái + thời gian; FAB '+' sheet: title, content multi-line, linkUrl, ảnh, status dropdown (DRAFT mặc định)
- [ ] commit `feat(admin): notifications screen with status filter and create`

### Task 4: Pages screen — list + CRUD
**Files:** `pages/presentation/...` + shell case + `test/pages_admin_vm_test.dart`.
- [ ] VM tests: load; create {title, content, isPublished} slug auto (trống); update title + isPublished; delete; 401→logout
- [ ] Screen: list card title + slug + pill Đã xuất bản/Bản nháp; FAB '+'; sheet: title, slug hint auto, content multi-line (8 dòng), switch Xuất bản
- [ ] commit `feat(admin): static pages screen with crud`

### Task 5: Verify + smoke + PR
- [ ] analyze + suite + format (kể untracked) → PR → CI xanh → merge → smoke emulator: Banner (thêm banner test không ảnh → hiện list → ẩn → xoá); Thông báo (list, chip PUBLISHED, tạo DRAFT test → xoá nếu có DELETE? notification [id] không có → tạo rồi ARCHIVED qua... không có update route? Kiểm T1 — nếu không xoá được thì tạo 1 thông báo test PUBLISHED thật tặng shop, ghi chú); Pages (tạo 'Trang test' → sửa → xoá).

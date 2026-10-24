# Mobile Admin — Phase 4b (Form sản phẩm) Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Form sản phẩm đầy đủ (thêm + sửa): ① Thông tin (tên/slug/gía VND/kho/Bật bán/mô tả) + danh mục, ② Ảnh (image_picker, defer upload, đặt chính/xoá, ≤10), ③ Biến thể động, ④ Bộ lọc attributes (chips SELECT/MULTI_SELECT) — POST/PUT thật, wire từ list 4a.

**Architecture:** 1 màn `ProductFormScreen` cuộn section dọc + sticky bottom Lưu (tách widget theo section theo spec); form state trong 1 VM (`Notifier`) giữ `AdminProductForm` immutable; upload ảnh chỉ chạy lúc Lưu (parity web). Data layer mở rộng feature products của 4a.

**Tech Stack:** +`image_picker` (pubspec). Flutter 3.32.4 fvm.

**Spec:** `docs/superpowers/specs/2026-10-07-mobile-admin-design.md` mục "4. Sản phẩm — Form". Contract: bakery-web `app/api/admin/products/route.ts` (POST), `products/[id]/route.ts` (GET/PUT), `lib/product-attributes.ts` (assignment rows), `app/api/admin/product-attributes/route.ts` (GET list), `app/api/upload/route.ts`.

## Global Constraints

- fvm; analyze 0; suite (359 baseline) xanh; **dart format trước commit**; branch `feature/admin-phase-4b-product-form`; PR dev, CI xanh mới merge.
- POST body: `{name (bắt buộc non-empty), slug? (trống → server tự sinh từ name), price: number ≥0, stock: int ≥0, comparePrice?: number, shortDescription?, description?, isActive?, isFeatured?, categoryIds: [id] (UI chọn 1, gửi mảng 1), variants?: [{id?, name, sku?, price: number, stock: int}], images?: [{url, isPrimary?}] (≤10; ảnh mới upload trước khi POST), attributeAssignments?: [{attributeId, valueIds: [...]}]}`. PUT `/{id}` same keys partial; images = replace set.
- GET `/{id}` detail gồm `images[{id,url,isPrimary}] orderBy displayOrder`, `variants[{id,name,sku,price,stock}]`, `categories[{categoryId}]`, `attributeAssignments[{attributeId, valueIds?|valueId?}]` — **T1 phải pin bằng fixture lấy từ server chạy thật** (curl admin) vì shape assignment từ lib/product-attributes.dart có thể là valueId đơn hoặc valueIds mảng.
- Attributes `GET /api/admin/product-attributes` → `[{id, name, type: 'SELECT'|'MULTI_SELECT', values:[{id, value, label}]}]` (live đã verify 2026-10-24).
- Upload `POST /api/upload` JSON `{file: 'data:image/...;base64,...'}` → `{data:{url, publicId}}`; whitelist png/jpeg/webp/avif/heic; ≤5MB/ảnh; **≤5 files/request → upload theo chunk 5** khi Lưu; folder bị server ép — không gửi.
- Giá nhập theo VND có group nghìn (dùng/wrap `vnd_input` nếu phase 0+1 đã có — check `admin/shared/presentation/widgets/`; không có thì TextFormField parse int).
- 401→logout; chuỗi Việt; FAB 4a thay snackbar bằng mở form create; tap card products list mở form edit.

## Review Focus

1. PUT images replace-set: sửa sản phẩm giữ ảnh cũ + thêm ảnh mới phải gửi ĐỦ cả cũ (url sẵn có) lẫn mới — thiếu là mất ảnh.
2. Upload chunk: 7 ảnh mới → 2 batch (5+2) theo thứ tự; 1 ảnh lỗi → lỗi surface, KHÔNG POST nửa vời.
3. price VND input '1.250.000' → gửi 1250000 (number), không gửi string có dấu chấm.
4. attributeAssignments shape đúng lib (valueIds mảng; nếu server expect valueId đơn cho SELECT thì map 1 phần tử) — pin bằng fixture thật ở T1.
5. Đổi danh mục rồi Lưu: categoryIds gửi [idMới] — server replace m2m set.

---

### Task 1: Form data layer — detail DTO + attributes + upload + form repo

**Files:**
- Modify: `lib/src/features/admin/products/domain/models/admin_product.dart` (+`AdminProductDetail` full fields theo Global Constraints + `AdminAttribute`/`AdminAttributeValue`)
- Modify: `lib/src/features/admin/products/data/dtos/product_admin_dto.dart` (+detail parse; fixture từ curl server thật — copy vào test)
- Modify: `lib/src/features/admin/products/data/datasources/product_admin_api_service.dart` (+`getProduct`, `createProduct(body)`, `updateProduct(id, body)`, +`getAttributes()` → `product_admin_api_service` hoặc file riêng `attribute_admin_api_service.dart` — chọn theo độ gọn, đặt cùng feature)
- Create: `lib/src/features/admin/products/data/datasources/upload_api_service.dart` (`uploadImages(List<String> dataUrls)` chunk 5, tuần tự, trả `List<String> urls` — ném lỗi kèm index)
- Modify: repo + DI (+2 providers)
- Test: `test/product_form_dto_test.dart`

**Interfaces — Produces:** `AdminProductDetail` (fields trên), `AdminAttribute{id,name,type,values:List<AdminAttributeValue{id,label}>}`, `ProductAdminRepository.getProduct(id)/createProduct/updateProduct` (nhận `Map<String,dynamic>` body đã build), `UploadApiService.uploadImages`.

- [ ] Step 1: curl GET detail 1 sản phẩm có ảnh+variant+assignment (admin token) → copy JSON làm fixture; viết failing parse test (detail + attributes + assignment shape thật)
- [ ] Step 2: FAIL → Step 3: implement → Step 4: PASS + gates → Step 5: commit `feat(admin): product form data layer (detail, attributes, upload)`

### Task 2: Form VM + màn scaffold + section Thông tin & Danh mục

**Files:**
- Create: `lib/src/features/admin/products/presentation/controllers/product_form_view_model.dart` (`ProductFormState{detail?, name, slug, priceText, stockText, comparePriceText, shortDesc, desc, isActive, categoryId?, variants:[FormVariant], images:[FormImage{url,isPrimary,isNewLocal}], assignments:Map<String,Set<String>>, isSaving, error}`; `load(productId)` edit / init create; validators: tên non-empty, price parse > =0 int VND, stock int ≥0)
- Create: `lib/src/features/admin/products/presentation/screens/product_form_screen.dart` (scaffold + section ① + dropdown danh mục từ attributes/categories provider + sticky Lưu — Lưu noop T2, wired T5)
- Test: `test/product_form_vm_test.dart` (init create rỗng / load edit parse / validators bắt lỗi từng trường / setCategory replace)

- [ ] Steps: failing tests → implement → gates → commit `feat(admin): product form scaffold with info section and category picker`

### Task 3: Section Ảnh — picker + defer upload + chính/xoá

**Files:**
- Modify: pubspec (+image_picker, +lock — `fvm flutter pub add image_picker`)
- Modify: `product_form_view_model.dart` (+addLocalImages(List<XFile>) ≤10 tổng, setPrimary, removeImage)
- Create: `lib/src/features/admin/products/presentation/widgets/product_images_section.dart` (grid preview: local file vs network url, badge "Chính", tap → đặt chính, nút xoá; nút Thêm ảnh → image_picker pickMultiple limit còn thiếu)
- Test: bổ sung `product_form_vm_test.dart` (addLocalImages chặn >10; setPrimary đổi cờ duy nhất; remove giữ ≥0)

- [ ] Steps như T2 → commit `feat(admin): product image picker with deferred upload`

### Task 4: Section Biến thể + Bộ lọc attributes

**Files:**
- Modify: VM (+addVariant/removeVariant/updateVariant; setAssignmentValue(attrId, valueId, selected) — SELECT: replace 1, MULTI_SELECT: toggle; buildAssignments lọc attr rỗng)
- Create: `lib/src/features/admin/products/presentation/widgets/product_variants_section.dart` (dòng động: tên/SKU/giá VND/kho + xoá dòng; nút Thêm biến thể)
- Create: `lib/src/features/admin/products/presentation/widgets/product_attributes_section.dart` (mỗi attribute: label + FilterChips values theo type)
- Test: VM tests (variant CRUD; SELECT replace; MULTI toggle; build ra `{attributeId, valueIds}` đúng; bỏ attr không chọn)

- [ ] Steps → commit `feat(admin): product variants and attribute filter sections`

### Task 5: Save flow + wire từ list + verify + smoke + PR

**Files:**
- Modify: VM (+`save()`: validate → upload ảnh mới (chunk, lỗi → error giữ form) → build body (images = cũ+mới urls, isPrimary đúng 1 — default ảnh đầu) → create/update → pop về list + reload list)
- Modify: `products_screen.dart` (FAB → push form create; tap card (ngoài select mode) → push form edit; thay snackbar placeholder)
- Test: VM save tests (fake upload+repo: create body đúng shape; update giữ ảnh cũ + thêm mới; upload fail → error, repo không gọi; 7 ảnh → upload chunk 5+2)
- [ ] analyze + suite + format → PR → CI xanh → merge → smoke emulator (TẠO sản phẩm test "Bánh test 4b" giá 10000 + ảnh nếu picker mở được trên emulator (có ảnh mẫu trong gallery không — nếu không, tạo không ảnh) + 1 biến thể + 1 attribute → Lưu → thấy trong list → SỬA tên → Lưu → XÓA qua multi-select 4a (dọn sạch) → verify xong)

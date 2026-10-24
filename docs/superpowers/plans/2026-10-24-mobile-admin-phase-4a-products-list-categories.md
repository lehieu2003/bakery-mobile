# Mobile Admin — Phase 4a (Sản phẩm list + Danh mục) Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Hai mục drawer "Sản phẩm" và "Danh mục" hoạt động thật: danh sách sản phẩm (search server-side, filter chip trạng thái + danh mục client-side, multi-select xoá hàng loạt) và CRUD danh mục dạng cây (thêm/sửa/xoá/đổi thứ tự).

**Architecture:** Mirror phase 2/3 — data layer DTO/service/repo + Riverpod Notifier; list dùng `AdminPagedList<T>`; form đầy đủ (POST/PUT product, ảnh, biến thể, bộ lọc) thuộc **plan 4b riêng** — FAB "Thêm sản phẩm" ở 4a chỉ snackbar "Sắp có" (tránh dead-end).

**Tech Stack:** Flutter 3.32.4 (fvm), riverpod — không package mới.

**Spec:** `docs/superpowers/specs/2026-10-07-mobile-admin-design.md` mục "4. Sản phẩm" (list phần) + "5. Danh mục". Contract: bakery-web `app/api/admin/products/route.ts`, `products/[id]/route.ts` (DELETE), `categories/route.ts`, `categories/[id]/route.ts`, `categories/reorder/route.ts`.

## Global Constraints

- fvm mọi lệnh; analyze 0; full suite (330 baseline) xanh sau mỗi task; **dart format mọi file .dart thay đổi trước khi commit** (CI gate check format).
- Branch `feature/admin-phase-4a-products-list` từ `origin/dev`; conventional commits từng task; PR vào dev, CI phải xanh mới merge.
- Products list `GET /api/admin/products?page&limit&search` → `data:{products, pagination}`; item: `id, name, slug, price (STRING '45000.00'), comparePrice?, stock(int), isActive, images[{url, isPrimary?}] (orderBy displayOrder), variants[], category{id,name,slug}|null, categoryIds[]` — money qua `asNum`.
- Xoá sản phẩm `DELETE /api/admin/products/{id}`: 404 `Không tìm thấy sản phẩm`; xoá nhiều = loop từng id (parity web), đếm thành công/thất bại hiển thị snackbar.
- Categories `GET` → `data:{categories: TREE}` (root nodes, children lồng 2 cấp — mỗi node `{id, name, slug, parentId?, children[]}`); POST `{name, slug?, parentId?}` (slug tự sinh từ name nếu thiếu); PUT `/{id} {name?, slug?, parentId?}`; DELETE `/{id}` (server chặn khi còn con/sản phẩm — message hiển thị); `PATCH /reorder {orderedIds: [id...]}`.
- Filter sản phẩm: chip trạng thái (Tất cả/Đang bán/Tạm ngừng — từ `isActive`) + dropdown danh mục (flat tên từ tree) lọc **client-side trên trang hiện tại** (parity web); search là server-side.
- Multi-select: long-press 1 card vào chế độ chọn → tap thêm/bỏ; appbar chế độ chọn hiện "N đã chọn" + nút xoá (confirm dialog) + nút huỷ.
- 401→logout pattern như phases trước; chuỗi UI tiếng Việt.

## Review Focus

1. `price` string-parse — parse test pin `'45000.00'` → 45000.0 (như phases trước, nhưng verify lại — field mới).
2. Categories tree lồng nhau — parse test pin root + con + cháu (2 cấp) và node không children → list rỗng.
3. Bulk delete một phần fail (1 id 404) — VM phải đếm OK/fail, không crash, list refresh theo kết quả.
4. Reorder gửi đúng `orderedIds` thứ tự mới sau move-up/move-down ở cùng cấp.
5. Filter client-side + phân trang: đổi filter khi đang ở trang 3 → reset về trang 1 (không giữ offset cũ).

---

### Task 1: Data layer — products list/delete + categories CRUD/reorder

**Files:**
- Create: `lib/src/features/admin/products/domain/models/admin_product.dart` (`AdminProductListItem{id,name,slug,price(double),comparePrice(double?),stock(int),isActive,thumbnailUrl(String? — images[0].url),categoryName(String?),categoryIds:List<String>}`)
- Create: `lib/src/features/admin/products/data/dtos/product_admin_dto.dart` + `product_admin_list_dto.dart` (envelope `{products, pagination}`)
- Create: `lib/src/features/admin/products/data/datasources/product_admin_api_service.dart` (`getProducts({page,limit=20,search})`, `deleteProduct(id)`)
- Create: `lib/src/features/admin/products/data/repositories/product_admin_repository.dart` (`ProductAdminPage{items,totalPages,total}`, `Future<void> deleteProduct(id)` — throw giữ nguyên message)
- Create: `lib/src/features/admin/categories/domain/models/admin_category.dart` (`AdminCategoryNode{id,name,slug,children:List<AdminCategoryNode>}` + `List<AdminCategoryNode> flatten()` util cho dropdown)
- Create: `lib/src/features/admin/categories/data/dtos/category_admin_dto.dart`; `datasources/category_admin_api_service.dart` (`getCategories()`, `createCategory({name,slug?,parentId?})`, `updateCategory(id,{name?,slug?,parentId?})`, `deleteCategory(id)`, `reorderCategories(orderedIds)`)
- Create: `lib/src/features/admin/categories/data/repositories/category_admin_repository.dart`
- Modify: `lib/src/core/di/data_providers.dart` (+4 providers)
- Test: `test/product_category_admin_dto_test.dart`

**Interfaces — Produces:** mọi class trên với tên chính xác (Task 2/3 consume); repo methods trả domain models.

- [ ] **Step 1: Failing tests** — pin: product list parse (price string '45000.00', thumbnail từ images[0], category null OK, pagination); product delete pass-through error message; category tree 2 cấp parse + flatten (đúng thứ tự depth-first) + leaf rỗng; reorder body `{orderedIds}`.
- [ ] **Step 2:** FAIL → **Step 3:** implement (asNum money; query chỉ key non-null)
- [ ] **Step 4:** PASS + analyze 0 + suite xanh → **Step 5:** commit `feat(admin): product/category data layer (list, delete, crud, reorder)`

### Task 2: Danh mục screen — cây + CRUD + reorder

**Files:**
- Create: `lib/src/features/admin/categories/presentation/controllers/categories_admin_view_model.dart` (state: tree, isLoading, error, isSaving; load/save/delete/move)
- Create: `lib/src/features/admin/categories/presentation/screens/categories_screen.dart` (tree ExpansionTile-style: indent theo depth, trailing lên/xuống đổi thứ tự cùng cấp, FAB '+' thêm root, tap node → edit sheet; confirm dialog xoá — lỗi server (còn con/sản phẩm) hiện snackbar)
- Create: `lib/src/features/admin/categories/presentation/widgets/category_edit_sheet.dart` (tên + slug (hint tự sinh, để trống = auto) + parent dropdown từ flatten — cho phép "Không có")
- Modify: `admin_shell.dart` — case `AdminSection.categories` (đang placeholder)
- Test: `test/categories_admin_vm_test.dart`

- [ ] **Step 1: Failing VM tests** — load tree; create gửi `{name, parentId?}` slug null khi trống; update đổi tên; delete fail message surfacing; move-up cùng cấp → repo.reorderCategories nhận orderedIds mới đúng; 401→logout.
- [ ] **Step 2:** FAIL → **Step 3:** implement (mirror orders/customers VM; sau mỗi mutation thành công → reload tree)
- [ ] **Step 4:** PASS + gates → **Step 5:** commit `feat(admin): categories screen with tree, crud and reorder`

### Task 3: Sản phẩm list screen + multi-select delete

**Files:**
- Create: `lib/src/features/admin/products/presentation/controllers/products_admin_view_model.dart` (search server-side; status/category filter client-side reset page; selection set; bulk delete loop)
- Create: `lib/src/features/admin/products/presentation/screens/products_screen.dart` (AdminPagedList + card: thumbnail, tên, giá, kho, pill Đang bán/Tạm ngừng; long-press select mode; appbar chọn + xoá confirm; FAB "Thêm sản phẩm" → snackbar 'Form sản phẩm đầy đủ sắp có' — plan 4b)
- Modify: `admin_shell.dart` — case `AdminSection.products`
- Test: `test/products_admin_vm_test.dart`

- [ ] **Step 1: Failing VM tests** — load+hasMore; setSearch reset page; setStatusFilter('inactive') lọc client items; setCategory lọc theo categoryIds; toggleSelect; bulkDelete với fake repo (2 ok + 1 lỗi 'Không tìm thấy sản phẩm') → state.report '{ok} đã xoá, {fail} lỗi' + list reload; 401→logout.
- [ ] **Step 2:** FAIL → **Step 3:** implement
- [ ] **Step 4:** PASS + gates → **Step 5:** commit `feat(admin): products list with filters and bulk delete`

### Task 4: Verify + smoke + PR

- [ ] analyze 0; suite xanh; **dart format mọi file đổi**; push → PR vào dev → **CI phải xanh** (public repo — free) → merge.
- [ ] Smoke emulator: drawer Danh mục (thêm "Test 4a" → sửa tên → xoá), reorder lên/xuống; drawer Sản phẩm (list 46, search 'tiramisu', filter Tạm ngừng, filter theo danh mục, long-press multi-select xoá 1 sản phẩm test rồi tạo lại? — KHÔNG: chỉ smoke read + UI chọn, KHÔNG xoá sản phẩm thật; bulk-delete verified qua VM test).

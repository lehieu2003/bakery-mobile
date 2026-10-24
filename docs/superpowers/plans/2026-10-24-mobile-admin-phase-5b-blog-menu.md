# Mobile Admin — Phase 5b (Blog×3 + Menu) Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 4 mục drawer cuối: **Blog** (3 màn con: Bài viết/Blog categories/Blog tags — drawer expand như web), **Menu** (header menu items CRUD). Sau phase này toàn bộ 15 mục spec đã live.

**Architecture:** Mirror 5a — data layer + VM + screen; blog posts dùng AdminPagedList (search + pagination thật có data); Blog categories/tags dùng pattern list-crud của pages; Menu = list đơn (bare array) CRUD.

**Tech Stack:** Flutter 3.32.4 — không package mới.

**Spec:** mục "5. Content — Blog"; contract bakery-web `app/api/admin/blog/**`, `app/api/admin/menu/**` (đã curl verify 10-24: menu list hiện rỗng, POST `{title, type='LINK', url, displayOrder?, isActive?}`).

## Global Constraints

- fvm; analyze 0 + suite (404 baseline) + **dart format bằng `git diff --name-only origin/dev..HEAD` + untracked** trước commit; branch `feature/admin-phase-5b-blog-menu`; PR dev; CI xanh mới merge.
- Blog posts list `GET /api/admin/blog/posts?page&limit&search` → `data:{posts:[{id,title,slug,excerpt?,status(DRAFT/PUBLISHED),coverUrl?,createdAt,...}],pagination}`; POST `{title (req), slug?, excerpt?, content, coverUrl?, categoryId?, status='DRAFT', publishedAt?}`; `PATCH /{id}/status {status}`; PUT/DELETE `/{id}`.
- Blog categories: `GET → data:[...]` bare (verify khi T3), POST `{name, slug?, description?, isActive?}`; tags tương tự `{name, slug?}`.
- Menu: `GET → data:[]` bare array `{id,title,type('LINK'),url,displayOrder,isActive,parentId}`; POST `{title, type='LINK', url, displayOrder?, isActive?}`; PUT/DELETE `/{id}`.
- 401→logout; chuỗi Việt; mutation → reload.

## Review Focus

1. Blog list envelope `{posts, pagination}` — không bare array (khác banners/pages).
2. Post create thiếu title/content → server 400 'title is required' — client gate.
3. Drawer "Blog" phải EXPAND 3 mục con (Bài viết/Categories/Tags) — tap mục cha toggle, không điều hướng thẳng.
4. Menu create khi list rỗng — empty-state phải có CTA, không đâm crash.
5. Status PATCH blog post dùng endpoint riêng `/status` — không phải PUT.

---

### Task 1: Data layer — blog posts/categories/tags + menu
**Files:** `lib/src/features/admin/content/blog/**` (posts/categories/tags: model+dto+service+repo) + `content/menu/**` + DI (+4 providers cặp) + `test/blog_menu_admin_dto_test.dart`.
- [ ] Failing parse tests (fixture thật đã curl: post item; menu item rỗng → tự viết theo route shape; blog categories/tags bare arrays)
- [ ] Implement → gates → commit `feat(admin): blog and menu data layer`

### Task 2: Blog screen — drawer con + posts list + categories/tags
**Files:** `blog/presentation/**` (blog_screen drawer-expand 3 mục con; posts_screen AdminPagedList + status pill; post_create_sheet title/excerpt/content/categoryId dropdown/categories+tags inline screens CRUD-lite) + `categories_admin_vm/blog_tags` VMs + shell: AdminSection.blog → BlogScreen (expand) + 3 case con + tests (posts VM: load/search/create gate/publish-status PATCH; categories & tags VM: load/create/delete).
- [ ] Steps → commit `feat(admin): blog posts, categories and tags screens`

### Task 3: Menu screen + wire + PR
**Files:** `menu/presentation/**` + shell case + `test/menu_admin_vm_test.dart` (load empty CTA; create; update; delete; 401).
- [ ] Steps → commit `feat(admin): menu screen`
- [ ] analyze + suite + format (diff origin/dev..HEAD + untracked) → PR → **CI xanh** → merge → smoke emulator (Blog list thật + tạo post DRAFT test; Menu thêm 'Test Menu' → xoá; Blog categories thêm/xoá).

## Hạ tầng
Subagent đang chết concurrency — CONTROLLER làm toàn bộ (pattern 4b). Mỗi task: tests RED → implement → analyze 0 + suite + format → commit.

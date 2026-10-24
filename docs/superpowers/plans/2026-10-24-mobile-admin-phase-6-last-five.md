# Mobile Admin — Phase 6 (5 mục cuối) Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Hoàn tất 15/15: **Coupon** (list + CRUD), **Bộ lọc sản phẩm** (attributes CRUD), **Thành viên** (cấu hình hạng + điểm/đơn), **Nhật ký hệ thống** (audit list), **Cài đặt** (GET/PUT).

**Architecture:** Mirror 5a/5b — mỗi module data layer + VM + screen; unwrap-safe (`ApiClient` tự unwrap `data` — KHÔNG đọc `response['data']`); tái dụng AdminPagedList, pattern 401→logout.

**Tech Stack:** Flutter 3.32.4 — không package mới.

**Spec:** mục "6. Coupons/Membership/Settings/Audit" + "Bộ lọc sản phẩm". Contract: bakery-web `app/api/admin/{coupons,membership,product-attributes,audit,settings}/**` (đã pin source 10-24).

## Global Constraints

- fvm; analyze 0 + suite (413 baseline) + dart format (`git diff --name-only origin/dev..HEAD` + untracked) trước commit; branch `feature/admin-phase-6-last-five`; PR dev; CI xanh mới merge.
- **Unwrap-safe: KHÔNG đọc `response['data']`** — ApiClient đã unwrap (bài học #57).
- Coupon: list `GET /api/admin/coupons` → `data:[{id, code, type:'PERCENTAGE'|'FIXED', value(number), minOrder?, maxDiscount?, usageLimit?, perUserLimit?, startAt?, endAt?, isActive}]` bare array; POST body `{code (req), type (PERCENTAGE|FIXED), value (number), minOrder?, maxDiscount?, usageLimit?, perUserLimit?, startAt?, endAt?, isActive?}`; PUT `/{id}` partial; DELETE `/{id}`.
- Product-attributes: GET list `{id, name, type: 'SELECT'|'MULTI_SELECT', values:[{id,value,label}]}`; POST `{name, type, values:[{value,label}]}`; PUT/DELETE `/{id}`.
- Membership: `GET → data{levels:[{key,label,minPoints,memberCount,...}], pointsPerOrder, totalMembers}`; PUT `{levels:[{key,minPoints}], pointsPerOrder}`.
- Audit: `GET /api/admin/audit?page&limit&module...` → `{logs:[...], pagination}` (list-only, không CRUD).
- Settings: GET → `data{...}` map; PUT partial body. Read-only UI hiển thị giá trị hiện tại + PUT các trường server chấp nhận (xem T5 đọc route khi implement).
- 401→logout; chuỗi Việt; mutation → reload.

## Review Focus

1. Coupon value theo type: PERCENTAGE (0-100) vs FIXED (₫) — VM validate theo type, nhãn hiển thị "%"/"₫".
2. Membership PUT gửi đủ `levels` 3 hạng (server replace) — thiếu hạng là mất cấu hình.
3. Attributes POST values rỗng → server chặn — client gate.
4. Audit list pagination + module filter (chip) — server-side.
5. unwrap-safe: KHÔNG response['data'] ở bất kỳ repo nào (grep 0 khi review).

---

### Task 1: Data layer 5 module
**Files:** `lib/src/features/admin/{coupons,product-attributes,membership,audit,settings}/` (model+dto+service+repo mỗi module, mirror 5a) + DI (+5 cặp) + `test/phase6_admin_dto_test.dart`.
- [ ] Failing parse tests: coupon (PERCENTAGE/FIXED), membership levels, attributes, audit envelope, settings map — fixture thật qua curl
- [ ] Implement → gates → commit `feat(admin): last-five data layer (coupons, attributes, membership, audit, settings)`

### Task 2: Coupon screen
**Files:** `coupons/presentation/**` + shell case + `test/coupons_admin_vm_test.dart` (load; create PERCENTAGE+FIXED; gate value; delete; 401).
- [ ] Screen: AdminPagedList, card code + type badge + value + hạn; FAB sheet: code, type chips, value (nhãn %/₫ theo type), minOrder, hạn; xoá confirm.
- [ ] commit `feat(admin): coupons screen`

### Task 3: Bộ lọc sản phẩm (attributes) + Thành viên screens
**Files:** `product-attributes/presentation/**` (list attr + values; sheet thêm attr: name/type/values dynamic; xoá) + `membership/presentation/**` (3 card hạng + minPoints edit + pointsPerOrder edit → PUT) + shell 2 case + 2 test file.
- [ ] commit `feat(admin): product attributes and membership settings screens`

### Task 4: Nhật ký hệ thống + Cài đặt screens
**Files:** `audit/presentation/**` (AdminPagedList: card actor/action/entity/thời gian + module filter chip) + `settings/presentation/**` (đọc GET hiện giá trị; PUT các key server nhận — đọc route khi implement) + shell 2 case + tests.
- [ ] commit `feat(admin): audit log and settings screens`

### Task 5: Verify + smoke + PR
- [ ] analyze + suite + format → PR → CI xanh → merge → smoke emulator (Coupon thêm/xoá "TEST6"; Bộ lọc thêm attribute test → xoá; Thành viên sửa minPoints rồi revert; Audit list; Cài đặt PUT 1 giá trị rồi revert) — mọi data test dọn sạch.

---
name: release
description: Chuẩn bị bản phát hành production — tạo nhánh release từ dev, bump version, mở PR release vào master. Chỉ chạy khi người dùng yêu cầu release.
disable-model-invocation: true
---

# Release dev → master

`master` = code đang chạy production. Chỉ thay đổi qua PR từ `release/*` (hoặc `hotfix/*`).

1. Hỏi người dùng số version mới (SemVer `X.Y.Z`) nếu chưa có. Version hiện tại: dòng `version:` trong
   `pubspec.yaml` (dạng `X.Y.Z+N`; `N` = build number, phải tăng mỗi lần phát hành lên store).
2. Tạo nhánh: `git fetch origin && git switch -c release/X.Y.Z origin/dev`.
3. Sửa `version: X.Y.Z+<N+1>` trong `pubspec.yaml` → commit `chore(release): vX.Y.Z`.
4. `bash scripts/validate.sh` phải xanh.
5. Liệt kê thay đổi: `git log --no-merges --format='- %s' origin/master..HEAD` → đưa vào body PR,
   gom theo type (feat / fix / khác). Nêu rõ phụ thuộc phía server: tính năng nào cần bakery-web
   đã release endpoint tương ứng trước khi phát hành app.
6. `git push -u origin HEAD` rồi `gh pr create --base master --title "chore(release): vX.Y.Z"`.
7. Nhắc người dùng: merge bằng **merge commit** (không squash), sau đó tag
   `git tag vX.Y.Z <merge-sha> && git push origin vX.Y.Z`, và mở PR `master → dev` nếu master có
   commit mà dev chưa có (hotfix). Build store (`fvm flutter build appbundle` / `ipa`) làm từ tag trên `master`.

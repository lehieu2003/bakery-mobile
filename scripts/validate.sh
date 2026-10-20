#!/usr/bin/env bash
# Pre-PR gate — must pass before opening a PR into dev (CI runs the same).
#
#   scripts/validate.sh [--base <ref>]
#
# --base defaults to origin/dev (falls back to local dev). Steps: branch name,
# commit messages since base, .env bootstrap, pub get, dart format on changed
# files, flutter analyze, flutter test.
set -euo pipefail
cd "$(git rev-parse --show-toplevel)"

BASE=""
while (($#)); do
  case "$1" in
    --base) BASE="${2:?--base needs a ref}"; shift ;;
    *) echo "Unknown option: $1" >&2; exit 2 ;;
  esac
  shift
done
if [[ -z "$BASE" ]]; then
  if git rev-parse -q --verify origin/dev >/dev/null; then BASE=origin/dev; else BASE=dev; fi
fi

# Pinned SDK via fvm (.fvmrc) locally; CI installs the same version directly.
if command -v fvm >/dev/null 2>&1 && [[ -f .fvmrc ]]; then
  FLUTTER=(fvm flutter); DART=(fvm dart)
else
  FLUTTER=(flutter); DART=(dart)
fi

step() { printf '\n▶ %s\n' "$1"; }

BRANCH="${GITHUB_HEAD_REF:-$(git rev-parse --abbrev-ref HEAD)}"
if [[ -n "$(git status --porcelain)" ]]; then
  echo "⚠ Working tree có thay đổi chưa commit — gate đang kiểm tra cả chúng."
fi

step "Branch name ($BRANCH)"
bash scripts/git-conventions.sh branch "$BRANCH"

step "Commit messages ($BASE..HEAD)"
bash scripts/git-conventions.sh commits "$BASE"

step "Flutter SDK"
"${FLUTTER[@]}" --version | head -1

# .env is a declared asset (pubspec.yaml): without it the asset bundle — and
# therefore every test — fails to build.
if [[ ! -f .env ]]; then
  cp .env.example .env
  echo "Created .env from .env.example"
fi

step "Dependencies"
"${FLUTTER[@]}" pub get

# Only files changed vs base: the codebase predates the format rule, and a
# repo-wide reformat would conflict with every open branch.
step "Format (Dart files changed since $BASE)"
merge_base="$(git merge-base "$BASE" HEAD)"
changed=()
while IFS= read -r file; do
  [[ -f "$file" ]] && changed+=("$file")
done < <(git diff --name-only --diff-filter=ACMR "$merge_base" -- '*.dart')
if ((${#changed[@]})); then
  "${DART[@]}" format --output=none --set-exit-if-changed "${changed[@]}" || {
    echo "✖ Chạy: ${DART[*]} format <các file trên> rồi commit lại." >&2
    exit 1
  }
else
  echo "Không có file .dart thay đổi."
fi

step "Analyze (0 issues)"
"${FLUTTER[@]}" analyze

step "Tests"
"${FLUTTER[@]}" test

printf '\n✅ Gate passed on %s (%s)\n' "$BRANCH" "$(git rev-parse --short HEAD)"

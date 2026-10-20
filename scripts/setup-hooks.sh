#!/usr/bin/env bash
# One-time per clone: enable the repo's git hooks (.githooks/).
set -euo pipefail
cd "$(git rev-parse --show-toplevel)"
git config core.hooksPath .githooks
echo "Git hooks enabled (core.hooksPath=.githooks)."

#!/usr/bin/env bash
set -euo pipefail

# gitupdate.sh — add, commit, and push the plain-static site
# Usage:
#   ./gitupdate.sh "chore: update homepage text"

if [[ $# -lt 1 || -z "${1:-}" ]]; then
  echo "❗ Please provide a commit message."
  echo 'Usage: ./gitupdate.sh "Update content"'
  exit 1
fi
MSG="$1"

# 0) Sanity checks
if [[ ! -d .git ]]; then
  echo "❌ Not a git repo here. Run 'git init' (in your PoM folder) and add a remote."
  exit 1
fi

BRANCH="$(git rev-parse --abbrev-ref HEAD)"
REMOTE="origin"

# 1) Optional build step (works even without jq)
if [[ -f package.json ]]; then
  if command -v jq >/dev/null 2>&1 && jq -e '.scripts.build' package.json >/dev/null 2>&1; then
    echo "🔧 Running build (npm run build)…"
    npm run --silent build
  elif grep -q '"build"' package.json 2>/dev/null; then
    echo "🔧 Running build (npm run build)…"
    npm run --silent build
  else
    echo "ℹ️ No build script detected. Skipping build."
  fi
else
  echo "ℹ️ No package.json. Skipping build."
fi

# 2) Stage + commit
echo "📂 Staging changes…"
git add -A

if git diff --cached --quiet; then
  echo "ℹ️ No changes to commit."
  exit 0
fi

echo "📝 Committing…"
git commit -m "$MSG"

# 3) Ensure remote + sync
if git remote get-url "$REMOTE" >/dev/null 2>&1; then
  echo "🔄 Pulling latest (rebase) from $REMOTE/$BRANCH…"
  git pull --rebase "$REMOTE" "$BRANCH" || true

  # 4) Push (set upstream if needed on first run)
  if git rev-parse --abbrev-ref --symbolic-full-name "@{u}" >/dev/null 2>&1; then
    echo "⬆️  Pushing to $REMOTE/$BRANCH…"
    git push
  else
    echo "⬆️  First push: setting upstream to $REMOTE/$BRANCH…"
    git push -u "$REMOTE" "$BRANCH"
  fi
  echo "✅ Done — your host (Netlify/Vercel) will auto-deploy."
else
  echo "ℹ️ No '$REMOTE' remote configured yet. Skipping push."
  echo "   Add it once with:"
  echo "   git remote add origin https://github.com/mathaifenn/PoM.git"
  echo "   and re-run this script."
fi


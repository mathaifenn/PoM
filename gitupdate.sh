#!/bin/bash
set -euo pipefail

if [ $# -lt 1 ] || [ -z "${1:-}" ]; then
  echo "❗ Please provide a commit message."
  echo 'Usage: ./gitupdate.sh "Update content"'
  exit 1
fi
MSG="$1"

# Optional build step (only if a build script exists)
if [ -f package.json ] && jq -e '.scripts.build' package.json >/dev/null 2>&1; then
  echo "🔧 Running build (npm run build)..."
  npm run --silent build
else
  echo "ℹ️ No build script detected. Skipping build."
fi

echo "📂 Staging changes..."
git add -A

if git diff --cached --quiet; then
  echo "ℹ️ No changes to commit."
  exit 0
fi

echo "📝 Committing..."
git commit -m "$MSG"

if git remote get-url origin >/dev/null 2>&1; then
  echo "🚀 Pushing to origin..."
  git push
  echo "✅ Done!"
else
  echo "ℹ️ No 'origin' remote configured yet. Skipping push."
  echo "   We’ll connect GitHub in the next step."
fi

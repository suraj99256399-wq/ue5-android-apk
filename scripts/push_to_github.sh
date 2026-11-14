#!/usr/bin/env bash
#
# Push this project to a GitHub repository you own.
#
# Usage:
#   ./scripts/push_to_github.sh https://github.com/<user>/<repo>.git
#
# If the repo is empty and public you may be able to push straight away.
# GitHub no longer accepts account passwords for git; when prompted for a
# password, paste a Personal Access Token (classic) with the "repo" scope:
#   GitHub > Settings > Developer settings > Personal access tokens > Tokens (classic)
#
set -euo pipefail

REPO_URL="${1:-}"
if [ -z "$REPO_URL" ]; then
  echo "Usage: $0 https://github.com/<user>/<repo>.git" >&2
  exit 1
fi

cd "$(dirname "${BASH_SOURCE[0]}")/.."

if [ ! -d .git ]; then
  git init -b main
fi

git add -A
if ! git diff --cached --quiet; then
  git commit -m "UE5 to Android APK pipeline"
fi

# Strip any embedded credentials from the URL before using it as a remote.
CLEAN_URL="$(printf '%s' "$REPO_URL" | sed -E 's#https://[^@/]*@#https://#')"
if git remote get-url origin >/dev/null 2>&1; then
  git remote set-url origin "$CLEAN_URL"
else
  git remote add origin "$CLEAN_URL"
fi

git branch -M main

echo "==> Pushing to $CLEAN_URL"
echo "    If asked for a password, paste your Personal Access Token (repo scope)."
git push -u origin main

echo
echo "==> Done. Your project is at:"
echo "    ${CLEAN_URL%.git}"

#!/usr/bin/env bash
# Creates or updates the single pattern-review comment on a PR.
#   post-comment.sh <owner/repo> <pr-number> <markdown-file>
# Needs GH_TOKEN with pull-requests: write.
set -euo pipefail

REPO="$1"
PR="$2"
BODY="$3"
MARKER='<!-- rgmercs-pattern-review -->'

EXISTING=$(gh api "repos/$REPO/issues/$PR/comments" --paginate \
  --jq ".[] | select(.body | startswith(\"$MARKER\")) | .id" | head -n1)

if [ -n "$EXISTING" ]; then
  gh api -X PATCH "repos/$REPO/issues/comments/$EXISTING" -F body=@"$BODY" > /dev/null
  echo "updated comment $EXISTING on #$PR"
else
  gh api -X POST "repos/$REPO/issues/$PR/comments" -F body=@"$BODY" > /dev/null
  echo "created comment on #$PR"
fi

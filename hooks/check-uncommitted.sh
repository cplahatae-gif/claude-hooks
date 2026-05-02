#!/bin/bash
# Stop 훅: 미커밋 변경사항 감지 → Claude에게 알림 주입

git rev-parse --git-dir > /dev/null 2>&1 || exit 0

CHANGES=$(git status --short 2>/dev/null)
[ -z "$CHANGES" ] && exit 0

COUNT=$(echo "$CHANGES" | wc -l | tr -d ' ')
FILES=$(echo "$CHANGES" | head -5)
BRANCH=$(git branch --show-current 2>/dev/null)

CTX="## 미커밋 변경사항 ${COUNT}개 (브랜치: ${BRANCH})
${FILES}
세션 종료 전 커밋 여부를 확인하세요."

jq -n --arg ctx "$CTX" '{"hookSpecificOutput": {"additionalContext": $ctx}}'
exit 0

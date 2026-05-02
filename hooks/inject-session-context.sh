#!/bin/bash
# SessionStart 훅: 세션 시작 시 git 컨텍스트를 Claude에게 자동 주입

if ! git rev-parse --git-dir > /dev/null 2>&1; then
    exit 0
fi

BRANCH=$(git branch --show-current 2>/dev/null)
LAST_COMMIT=$(git log -1 --oneline 2>/dev/null)
MODIFIED=$(git diff --name-only 2>/dev/null | head -5 | tr '\n' ', ' | sed 's/, $//')
STAGED=$(git diff --cached --name-only 2>/dev/null | head -3 | tr '\n' ', ' | sed 's/, $//')

CTX="## 현재 작업 컨텍스트 (자동 주입)
- 브랜치: ${BRANCH:-알 수 없음}
- 마지막 커밋: ${LAST_COMMIT:-없음}"

if [ -n "$MODIFIED" ]; then
    CTX="$CTX
- 수정된 파일: $MODIFIED"
fi
if [ -n "$STAGED" ]; then
    CTX="$CTX
- 스테이징된 파일: $STAGED"
fi

jq -n --arg ctx "$CTX" '{"hookSpecificOutput": {"additionalContext": $ctx}}'
exit 0

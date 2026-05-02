#!/bin/bash
# PostCompact 훅: compact 후 핵심 규칙 + git 상태 재주입

CTX="## Compact 후 재주입 — 핵심 규칙
- main/master 브랜치 직접 push 금지 (PR 사용)
- rm -rf 등 재귀·강제 삭제 명령 직접 실행 금지
- .env, secret, key 등 민감 파일 수정 금지
- 설정 변경: ~/.claude/hooks/hook-config.json"

if git rev-parse --git-dir > /dev/null 2>&1; then
    BRANCH=$(git branch --show-current 2>/dev/null)
    LAST=$(git log -1 --oneline 2>/dev/null)
    MODIFIED=$(git diff --name-only 2>/dev/null | head -3 | tr '\n' ', ' | sed 's/, $//')
    CTX="$CTX

## Git 상태 (compact 전 기준)
- 브랜치: ${BRANCH:-알 수 없음}
- 마지막 커밋: ${LAST:-없음}${MODIFIED:+
- 수정 파일: $MODIFIED}"
fi

jq -n --arg ctx "$CTX" '{"hookSpecificOutput": {"additionalContext": $ctx}}'
exit 0

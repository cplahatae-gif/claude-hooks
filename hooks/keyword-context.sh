#!/bin/bash
# UserPromptSubmit 훅: 키워드 감지 → 관련 컨텍스트 자동 주입

INPUT=$(cat)
PROMPT=$(echo "$INPUT" | jq -r '.prompt // empty' 2>/dev/null)
[ -z "$PROMPT" ] && exit 0

CTX=""

# 배포/release 관련
if echo "$PROMPT" | grep -qiE "배포|deploy|vercel|production|prod|릴리즈|release|출시"; then
    CTX="${CTX}
## 배포 관련 주의사항
- 테스트 통과 여부 확인
- 환경변수(.env) 설정 확인
- main 브랜치는 PR로만 병합"
fi

# 옵시디언 관련
if echo "$PROMPT" | grep -qiE "옵시디언|obsidian|볼트|vault"; then
    CTX="${CTX}
## Obsidian 연동 정보
- API: https://127.0.0.1:27124 (OBSIDIAN_API_KEY 환경변수)
- curl 사용 시 -k 플래그 필수"
fi

# 훅 관련
if echo "$PROMPT" | grep -qiE "훅|hook"; then
    CTX="${CTX}
## Hook 정보
- 스크립트: ~/.claude/hooks/
- 설정: ~/.claude/hooks/hook-config.json
- GitHub: https://github.com/cplahatae-gif/claude-hooks"
fi

[ -n "$CTX" ] && jq -n --arg ctx "${CTX#$'\n'}" '{"hookSpecificOutput": {"hookEventName": "UserPromptSubmit", "additionalContext": $ctx}}'
exit 0

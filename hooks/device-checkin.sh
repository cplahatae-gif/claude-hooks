#!/bin/bash
# SessionStart 훅: 기기 체크인 → 로컬 기록 + Obsidian Setup 노트 갱신 + Claude 컨텍스트 주입

# OS 및 기기 감지
OS_RAW=$(uname -s)
case "$OS_RAW" in
  Darwin*)        DEVICE_OS="macOS" ;;
  MINGW*|MSYS*|CYGWIN*) DEVICE_OS="Windows" ;;
  Linux*)         DEVICE_OS="Linux" ;;
  *)              DEVICE_OS="Unknown ($OS_RAW)" ;;
esac

DEVICE_HOST=$(hostname)
TIMESTAMP=$(date "+%Y-%m-%d %H:%M")
HOOK_COUNT=$(ls "$HOME/.claude/hooks/"*.sh "$HOME/.claude/hooks/"*.ps1 2>/dev/null | wc -l | tr -d ' ')

# 1. 로컬 device-state.json 기록
STATE_FILE="$HOME/.claude/device-state.json"
jq -n \
  --arg os "$DEVICE_OS" \
  --arg host "$DEVICE_HOST" \
  --arg ts "$TIMESTAMP" \
  --arg hooks "$HOOK_COUNT" \
  '{os: $os, hostname: $host, last_seen: $ts, hook_count: ($hooks | tonumber)}' \
  > "$STATE_FILE" 2>/dev/null

# 2. Obsidian REST API로 Setup 노트 갱신 (실행 중일 때만)
OBSIDIAN_API_URL="https://127.0.0.1:27124"
SETUP_NOTE_PATH="90. Settings/94. Agent Settings/claude/Claude Code Setup.md"

# API Key: Windows는 PowerShell에서, Mac/Linux는 환경변수에서
if command -v powershell.exe &>/dev/null; then
    OB_KEY=$(powershell.exe -NoProfile -Command \
      "[System.Environment]::GetEnvironmentVariable('OBSIDIAN_API_KEY','User')" \
      2>/dev/null | tr -d '\r\n')
else
    OB_KEY="${OBSIDIAN_API_KEY:-}"
fi

if [ -n "$OB_KEY" ]; then
    ENCODED_PATH=$(python3 -c "import urllib.parse,sys; print(urllib.parse.quote(sys.argv[1]))" \
      "$SETUP_NOTE_PATH" 2>/dev/null || \
      echo "$SETUP_NOTE_PATH" | sed 's/ /%20/g; s/\./%2E/g')

    CURRENT=$(curl -sk "$OBSIDIAN_API_URL/vault/$ENCODED_PATH" \
      -H "Authorization: Bearer $OB_KEY" 2>/dev/null)

    if [ -n "$CURRENT" ] && echo "$CURRENT" | grep -q "접속 로그"; then
        # 기존 행 업데이트 or 새 행 추가
        if echo "$CURRENT" | grep -q "| $DEVICE_HOST |"; then
            UPDATED=$(echo "$CURRENT" | sed \
              "s/| $DEVICE_HOST | [^|]* | [^|]* |/| $DEVICE_HOST | $DEVICE_OS | $TIMESTAMP |/")
        else
            UPDATED=$(echo "$CURRENT" | sed \
              "/^| 기기 | OS | 최종 접속 |/a | $DEVICE_HOST | $DEVICE_OS | $TIMESTAMP |")
        fi

        curl -sk -X PUT "$OBSIDIAN_API_URL/vault/$ENCODED_PATH" \
          -H "Authorization: Bearer $OB_KEY" \
          -H "Content-Type: text/markdown; charset=utf-8" \
          --data-binary "$UPDATED" > /dev/null 2>&1
    fi
fi

# 3. Claude 컨텍스트에 현재 기기 정보 주입
jq -n \
  --arg host "$DEVICE_HOST" \
  --arg os "$DEVICE_OS" \
  --arg hooks "$HOOK_COUNT" \
  '{"systemMessage": "현재 기기: \($host) (\($os)) | 설치된 훅: \($hooks)개"}'

exit 0

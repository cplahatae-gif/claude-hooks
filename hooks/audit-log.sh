#!/bin/bash
# PostToolUse 훅: 모든 도구 호출을 JSONL 감사 로그로 기록 (async)

AUDIT_FILE="$HOME/.claude/audit.jsonl"
INPUT=$(cat)

ENTRY=$(echo "$INPUT" | jq -c '{
  ts: (now | todate),
  tool: .tool_name,
  input: (
    if .tool_name == "Bash" then {command: .tool_input.command}
    elif (.tool_name == "Edit" or .tool_name == "Write") then {file: .tool_input.file_path}
    else .tool_input
    end
  )
}' 2>/dev/null)

[ -n "$ENTRY" ] && echo "$ENTRY" >> "$AUDIT_FILE"
exit 0

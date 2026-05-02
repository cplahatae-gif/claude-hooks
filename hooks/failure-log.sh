#!/bin/bash
# PostToolUseFailure 훅: 도구 실패 패턴 기록 (async)

FAIL_FILE="$HOME/.claude/audit-failures.jsonl"
INPUT=$(cat)

ENTRY=$(echo "$INPUT" | jq -c '{
  ts: (now | todate),
  tool: .tool_name,
  input: .tool_input,
  error: .error
}' 2>/dev/null)

[ -n "$ENTRY" ] && echo "$ENTRY" >> "$FAIL_FILE"
exit 0

# UserPromptSubmit 훅: 작업 시작 시간 기록
[DateTimeOffset]::UtcNow.ToUnixTimeSeconds() | Set-Content -Path "$env:TEMP\claude_task_start.txt" -Encoding UTF8
exit 0

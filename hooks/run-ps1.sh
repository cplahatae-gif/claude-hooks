#!/bin/bash
# bash → PowerShell 브릿지: POSIX 경로를 Windows 경로로 변환 후 .ps1 실행
# stdin(hook JSON)은 자동으로 PowerShell에 전달됨
SCRIPT="$HOME/.claude/hooks/$1"
WIN_SCRIPT=$(cygpath -w "$SCRIPT")
powershell.exe -ExecutionPolicy Bypass -NonInteractive -File "$WIN_SCRIPT"

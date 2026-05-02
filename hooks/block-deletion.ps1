# PreToolUse 훅: 삭제 명령어 감지 및 차단 + Windows 알림

$rawInput = [Console]::In.ReadToEnd()
if (-not $rawInput) { exit 0 }

try { $hookData = $rawInput | ConvertFrom-Json } catch { exit 0 }

$command = $hookData.tool_input.command
if (-not $command) { exit 0 }

# 설정 로드
$configPath = "$env:USERPROFILE\.claude\hooks\hook-config.json"
$blockMode = "dangerous"

if (Test-Path $configPath) {
    try {
        $config = Get-Content $configPath -Raw -Encoding UTF8 | ConvertFrom-Json
        $blockMode = $config.deletion.blockMode
    } catch {}
}

# 패턴 정의
$dangerousPatterns = @(
    'rm\s+.*-[rRfF]',          # rm -rf, rm -r, rm -f (순서 무관)
    'rmdir\s+/s',               # rmdir /s
    'del\s+/[fqsS]',            # del /f /q /s
    'Remove-Item.*-Recurse',    # Remove-Item -Recurse
    'Remove-Item.*-Force',      # Remove-Item -Force
    'rd\s+/s',                  # rd /s
    'git\s+clean\s+-[fdxX]'    # git clean -fd
)

$allPatterns = @(
    '\brm\b',
    '\bdel\s',
    '\brmdir\b',
    'Remove-Item',
    '\brd\b\s'
)

$patterns = if ($blockMode -eq "all") { $allPatterns } else { $dangerousPatterns }

$matched = $false
foreach ($p in $patterns) {
    if ($command -match $p) { $matched = $true; break }
}

if ($matched) {
    try {
        Add-Type -AssemblyName System.Windows.Forms
        $notify = New-Object System.Windows.Forms.NotifyIcon
        $notify.Icon = [System.Drawing.SystemIcons]::Warning
        $notify.BalloonTipIcon = [System.Windows.Forms.ToolTipIcon]::Warning
        $notify.BalloonTipTitle = "Claude Code — 삭제 차단"
        $notify.BalloonTipText = "삭제 명령 감지: $command"
        $notify.Visible = $true
        $notify.ShowBalloonTip(15000)
        Start-Sleep -Seconds 1
        $notify.Visible = $false
        $notify.Dispose()
    } catch {}

    Write-Error "삭제 명령어가 차단되었습니다. 필요하다면 직접 터미널에서 실행해주세요.`n명령어: $command"
    exit 2
}

exit 0

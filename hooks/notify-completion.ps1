# Stop 훅: 임계값 초과 시 Windows 알림 + 자기검증 요청 주입

$configPath = "$env:USERPROFILE\.claude\hooks\hook-config.json"
$thresholdSeconds = 600

if (Test-Path $configPath) {
    try {
        $config = Get-Content $configPath -Raw -Encoding UTF8 | ConvertFrom-Json
        $thresholdSeconds = $config.notification.thresholdSeconds
    } catch {}
}

$startTimeFile = "$env:TEMP\claude_task_start.txt"
if (-not (Test-Path $startTimeFile)) { exit 0 }

try {
    $startTime = [long](Get-Content $startTimeFile -Raw -Encoding UTF8).Trim()
    $currentTime = [DateTimeOffset]::UtcNow.ToUnixTimeSeconds()
    $elapsed = $currentTime - $startTime
    Remove-Item $startTimeFile -Force -ErrorAction SilentlyContinue

    if ($elapsed -lt $thresholdSeconds) { exit 0 }

    $minutes = [math]::Round($elapsed / 60, 1)

    # Windows 트레이 알림
    Add-Type -AssemblyName System.Windows.Forms
    $notify = New-Object System.Windows.Forms.NotifyIcon
    $notify.Icon = [System.Drawing.SystemIcons]::Information
    $notify.BalloonTipIcon = [System.Windows.Forms.ToolTipIcon]::Info
    $notify.BalloonTipTitle = "Claude Code — 작업 완료"
    $notify.BalloonTipText = "${minutes}분 작업이 완료되었습니다."
    $notify.Visible = $true
    $notify.ShowBalloonTip(10000)
    Start-Sleep -Seconds 2
    $notify.Visible = $false
    $notify.Dispose()

    # 10분 이상 걸린 복잡한 작업 → 자기검증 요청 컨텍스트 주입
    $verifyMsg = "이 작업은 ${minutes}분이 소요된 장시간 작업입니다. 마무리 전에 사용자의 원래 요청 항목을 모두 이행했는지 스스로 점검하세요."
    @{ hookSpecificOutput = @{ additionalContext = $verifyMsg } } | ConvertTo-Json -Compress
} catch {}

exit 0

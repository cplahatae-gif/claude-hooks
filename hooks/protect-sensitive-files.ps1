# PreToolUse 훅: 민감 파일 수정 차단 (Edit/Write 도구)

$rawInput = [Console]::In.ReadToEnd()
if (-not $rawInput) { exit 0 }

try { $hookData = $rawInput | ConvertFrom-Json } catch { exit 0 }

$filePath = $hookData.tool_input.file_path
if (-not $filePath) { exit 0 }

$sensitivePatterns = @(
    '\.env$',
    '\.env\.',
    'secret',
    'credential',
    'apikey',
    'api_key',
    'private.?key',
    'id_rsa',
    'id_ed25519',
    '\.pem$',
    '\.p12$',
    '\.pfx$',
    'token',
    'password'
)

$normalizedPath = $filePath.ToLower() -replace '\\', '/'

foreach ($pattern in $sensitivePatterns) {
    if ($normalizedPath -match $pattern) {
        try {
            Add-Type -AssemblyName System.Windows.Forms
            $notify = New-Object System.Windows.Forms.NotifyIcon
            $notify.Icon = [System.Drawing.SystemIcons]::Warning
            $notify.BalloonTipIcon = [System.Windows.Forms.ToolTipIcon]::Warning
            $notify.BalloonTipTitle = "Claude Code — 민감 파일 차단"
            $notify.BalloonTipText = "보호된 파일 수정이 차단됨:`n$filePath"
            $notify.Visible = $true
            $notify.ShowBalloonTip(15000)
            Start-Sleep -Seconds 1
            $notify.Visible = $false
            $notify.Dispose()
        } catch {}

        Write-Error "민감 파일 보호: $filePath`nClaude는 이 파일을 수정할 수 없습니다. 필요하면 직접 편집하세요."
        exit 2
    }
}

exit 0

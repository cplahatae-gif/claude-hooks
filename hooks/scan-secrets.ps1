# PreToolUse 훅: 파일 내용에서 시크릿/자격증명 패턴 감지 (Write/Edit 도구)

$rawInput = [Console]::In.ReadToEnd()
if (-not $rawInput) { exit 0 }

try { $hookData = $rawInput | ConvertFrom-Json } catch { exit 0 }

# Write 도구는 .content, Edit 도구는 .new_string
$content = $hookData.tool_input.content
if (-not $content) { $content = $hookData.tool_input.new_string }
if (-not $content) { exit 0 }

$secrets = @(
    @{ pattern = 'AKIA[0-9A-Z]{16}';                            name = 'AWS Access Key' },
    @{ pattern = 'ASIA[0-9A-Z]{16}';                            name = 'AWS Temporary Key' },
    @{ pattern = '-----BEGIN .{0,20}PRIVATE KEY';               name = 'Private Key' },
    @{ pattern = 'ghp_[A-Za-z0-9]{36}';                         name = 'GitHub Token' },
    @{ pattern = 'xoxb-[0-9]+-[0-9]+-[A-Za-z0-9]+';            name = 'Slack Bot Token' },
    @{ pattern = 'AIza[0-9A-Za-z\-_]{35}';                      name = 'Google API Key' },
    @{ pattern = 'sk-[A-Za-z0-9]{48}';                          name = 'OpenAI API Key' },
    @{ pattern = 'sk-ant-[A-Za-z0-9\-_]{90,}';                  name = 'Anthropic API Key' }
)

foreach ($secret in $secrets) {
    if ($content -match $secret.pattern) {
        try {
            Add-Type -AssemblyName System.Windows.Forms
            $notify = New-Object System.Windows.Forms.NotifyIcon
            $notify.Icon = [System.Drawing.SystemIcons]::Error
            $notify.BalloonTipIcon = [System.Windows.Forms.ToolTipIcon]::Error
            $notify.BalloonTipTitle = "Claude Code — 시크릿 유출 차단"
            $notify.BalloonTipText = "$($secret.name) 패턴 감지! 파일 쓰기를 차단합니다."
            $notify.Visible = $true
            $notify.ShowBalloonTip(15000)
            Start-Sleep -Seconds 1
            $notify.Visible = $false
            $notify.Dispose()
        } catch {}

        Write-Error "시크릿 유출 차단: $($secret.name) 패턴이 감지되었습니다.`n코드에 자격증명을 직접 포함하지 마세요. .env 파일이나 환경변수를 사용하세요."
        exit 2
    }
}

exit 0

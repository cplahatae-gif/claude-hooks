# PreToolUse 훅: main/master 브랜치 직접 push 차단

$rawInput = [Console]::In.ReadToEnd()
if (-not $rawInput) { exit 0 }

try { $hookData = $rawInput | ConvertFrom-Json } catch { exit 0 }

$command = $hookData.tool_input.command
if (-not $command) { exit 0 }
if ($command -notmatch "git\s+push") { exit 0 }

try {
    $branch = git branch --show-current 2>$null
    if (-not $branch) { exit 0 }

    if ($branch -eq "main" -or $branch -eq "master") {
        try {
            Add-Type -AssemblyName System.Windows.Forms
            $notify = New-Object System.Windows.Forms.NotifyIcon
            $notify.Icon = [System.Drawing.SystemIcons]::Warning
            $notify.BalloonTipIcon = [System.Windows.Forms.ToolTipIcon]::Warning
            $notify.BalloonTipTitle = "Claude Code — main 직접 push 차단"
            $notify.BalloonTipText = "$branch 브랜치 직접 push 차단. PR을 통해 merge하세요."
            $notify.Visible = $true
            $notify.ShowBalloonTip(15000)
            Start-Sleep -Seconds 1
            $notify.Visible = $false
            $notify.Dispose()
        } catch {}

        Write-Error "$branch 브랜치 직접 push 차단됨.`n새 브랜치를 만들고 PR을 여세요:`n  git checkout -b feature/내-작업명`n  git push -u origin feature/내-작업명"
        exit 2
    }
} catch {}

exit 0

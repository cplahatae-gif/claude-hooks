# PostToolUse 훅: git push 감지 후 Obsidian 볼트 A에 프로젝트 노트 생성/업데이트

$rawInput = [Console]::In.ReadToEnd()
if (-not $rawInput) { exit 0 }

try { $hookData = $rawInput | ConvertFrom-Json } catch { exit 0 }

$command = $hookData.tool_input.command
if (-not $command) { exit 0 }
if ($command -notmatch "git\s+push") { exit 0 }

# 설정 로드
$configPath = "$env:USERPROFILE\.claude\hooks\hook-config.json"
$apiUrl = "https://127.0.0.1:27124"
$noteFolder = "9. 프로젝트"

if (Test-Path $configPath) {
    try {
        $config = Get-Content $configPath -Raw -Encoding UTF8 | ConvertFrom-Json
        $apiUrl = $config.obsidian.apiUrl
        $noteFolder = $config.obsidian.noteFolder
    } catch {}
}

$apiKey = $env:OBSIDIAN_API_KEY
if (-not $apiKey) { exit 0 }

# git 정보 수집
try {
    $repoRoot = git rev-parse --show-toplevel 2>$null
    if (-not $repoRoot) { exit 0 }

    $remoteUrl = git remote get-url origin 2>$null
    if ($remoteUrl) {
        $repoName = ($remoteUrl -split '/')[-1] -replace '\.git$', ''
    } else {
        $repoName = Split-Path $repoRoot -Leaf
    }

    $branch        = git branch --show-current 2>$null
    $lastCommitMsg = git log -1 --format="%s" 2>$null
    $lastAuthor    = git log -1 --format="%an" 2>$null
    $commitCount   = git rev-list --count HEAD 2>$null
    $pushTime      = Get-Date -Format "yyyy-MM-dd HH:mm"

    # SSH → HTTPS 변환
    $githubUrl = $remoteUrl -replace 'git@github\.com:', 'https://github.com/' -replace '\.git$', ''
} catch { exit 0 }

$noteContent = @"
---
tags:
  - project
  - git
last_pushed: $pushTime
branch: $branch
---

# $repoName

## 최근 Push
- **시간**: $pushTime
- **브랜치**: $branch
- **커밋**: $lastCommitMsg
- **작성자**: $lastAuthor
- **누적 커밋 수**: $commitCount

## 링크
- [GitHub]($githubUrl)
- 로컬 경로: ``$repoRoot``
"@

$notePath = "$noteFolder/$repoName.md"
$encodedPath = [Uri]::EscapeDataString($notePath)

try {
    $body = [System.Text.Encoding]::UTF8.GetBytes($noteContent)
    $headers = @{
        "Authorization" = "Bearer $apiKey"
        "Content-Type"  = "text/markdown; charset=utf-8"
    }
    Invoke-RestMethod -Uri "$apiUrl/vault/$encodedPath" -Method Put -Headers $headers -Body $body -SkipCertificateCheck -ErrorAction Stop
} catch {
    Write-Error "Obsidian 노트 등록 실패: $_"
}

exit 0

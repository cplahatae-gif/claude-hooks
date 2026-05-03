# PostToolUse 훅: git push 감지 → CMDS 프로젝트 노트(70. Outputs/74. Projects/)에 push 이력 추가
# 별도 노트 생성 안 함. /obsidian-project-sync 스킬이 만든 노트에만 기록.

$rawInput = [Console]::In.ReadToEnd()
if (-not $rawInput) { exit 0 }

try { $hookData = $rawInput | ConvertFrom-Json } catch { exit 0 }

$command = $hookData.tool_input.command
if (-not $command) { exit 0 }
if ($command -notmatch "git\s+push") { exit 0 }

# 설정 로드
$configPath = "$env:USERPROFILE\.claude\hooks\hook-config.json"
$apiUrl = "https://127.0.0.1:27124"
if (Test-Path $configPath) {
    try {
        $cfg = Get-Content $configPath -Raw -Encoding UTF8 | ConvertFrom-Json
        if ($cfg.obsidian.apiUrl) { $apiUrl = $cfg.obsidian.apiUrl }
    } catch {}
}

$apiKey = $env:OBSIDIAN_API_KEY
if (-not $apiKey) { exit 0 }

# git 정보 수집
try {
    $repoRoot  = git rev-parse --show-toplevel 2>$null
    if (-not $repoRoot) { exit 0 }

    $remoteUrl = git remote get-url origin 2>$null
    $repoName  = if ($remoteUrl) { ($remoteUrl -split '/')[-1] -replace '\.git$', '' } else { Split-Path $repoRoot -Leaf }
    $branch    = git branch --show-current 2>$null
    $commitMsg = git log -1 --format="%s" 2>$null
    $pushDate  = Get-Date -Format "yyyy-MM-dd"
} catch { exit 0 }

$authHeader = @{ "Authorization" = "Bearer $apiKey" }

try {
    # CMDS 프로젝트 노트 검색 (74. Projects 하위)
    $encoded = [Uri]::EscapeDataString($repoName)
    $results = Invoke-RestMethod -Uri "$apiUrl/search/simple/?query=$encoded" `
        -Method Post -Headers $authHeader -SkipCertificateCheck -ErrorAction Stop

    $note = $results | Where-Object { $_.filename -like "*74*Projects*" } | Select-Object -First 1
    if (-not $note) { exit 0 }  # 노트 없으면 조용히 종료 (/obsidian-project-sync로 먼저 생성 필요)

    $notePath    = $note.filename
    $encodedPath = [Uri]::EscapeDataString($notePath)

    # 기존 노트 읽기
    $content = Invoke-RestMethod -Uri "$apiUrl/vault/$encodedPath" `
        -Method Get -Headers $authHeader -SkipCertificateCheck -ErrorAction Stop

    # 진행 상황 섹션 바로 아래에 push 항목 삽입
    $pushEntry = "### $pushDate — push ($branch)`n- $commitMsg`n"

    if ($content -match "(?m)^## 진행 상황") {
        $content = [regex]::Replace($content, "(?m)(^## 진행 상황[ \t]*\r?\n)", "`$1`n$pushEntry")
    } else {
        $content += "`n## 진행 상황`n`n$pushEntry"
    }

    # 업데이트
    $putHeaders = @{
        "Authorization" = "Bearer $apiKey"
        "Content-Type"  = "text/markdown; charset=utf-8"
    }
    $bytes = [System.Text.Encoding]::UTF8.GetBytes($content)
    Invoke-RestMethod -Uri "$apiUrl/vault/$encodedPath" -Method Put `
        -Headers $putHeaders -Body $bytes -SkipCertificateCheck -ErrorAction Stop

} catch { exit 0 }

exit 0

---
name: setup-device
description: Checks which Claude Code hooks, skills, and plugins are installed on the current device vs. the reference list, and provides installation instructions for missing items. Use when setting up a new machine or verifying existing setup.
triggers:
  - /setup-device
  - 기기 세팅
  - 세팅 확인
  - 설치 확인
  - 뭐 설치됐어
---

# setup-device 스킬

신규 기기 세팅 점검 및 설치 가이드를 제공합니다.

## 실행 단계

### 1단계: 현재 기기 파악

시스템 프롬프트의 `Platform:` 값으로 OS를 판별합니다 (bash 없이 직접 판단).
- `win32` → Windows (run-ps1.sh 브릿지 필요)
- `darwin` → macOS (.sh 스크립트만 필요)

그리고 Bash 도구로 호스트명과 실제 설치 현황을 확인합니다:

```bash
hostname
uname -s
ls ~/.claude/hooks/
ls ~/.claude/skills/ | head -30
cat ~/.claude/settings.json | grep -A 200 '"hooks"'
cat ~/.claude/device-state.json 2>/dev/null || echo "device-state.json 없음"
```

### 2단계: 기대 목록과 비교

**훅 기대 목록 (16개 파일)**:

| 파일 | 타입 | 필요 OS |
|------|------|---------|
| hook-config.json | config | 모두 |
| run-ps1.sh | util | Windows |
| track-start.ps1 | hook | Windows (.sh 버전 필요: Mac) |
| notify-completion.ps1 | hook | Windows (.sh 버전 필요: Mac) |
| inject-session-context.sh | hook | 모두 |
| keyword-context.sh | hook | 모두 |
| device-checkin.sh | hook | 모두 |
| check-uncommitted.sh | hook | 모두 |
| reinject-after-compact.sh | hook | 모두 |
| audit-log.sh | hook | 모두 |
| failure-log.sh | hook | 모두 |
| git-to-obsidian.ps1 | hook | Windows (.sh 버전 필요: Mac) |
| block-deletion.ps1 | hook | Windows (.sh 버전 필요: Mac) |
| block-main-push.ps1 | hook | Windows (.sh 버전 필요: Mac) |
| protect-sensitive-files.ps1 | hook | Windows (.sh 버전 필요: Mac) |
| scan-secrets.ps1 | hook | Windows (.sh 버전 필요: Mac) |

**핵심 스킬 기대 목록 (사용자 직접 작성)**:
git-commit, lecture-summary, obsidian-project-sync, deploy-check,
weekly-case, meeting-minutes, write-post, xlsx-ko-en-translator,
hwp, hwpx, youtube-watcher, plugin-recommender, project-plugins,
setup-device, baoyu-youtube-transcript

**플러그인**:
- bkit (enabledPlugins에 true)
- codex@openai-codex (enabledPlugins에 true)

**rules**:
- raindrop.md

### 3단계: 보고서 출력

아래 형식으로 출력합니다:

```
## 기기 점검 결과: {hostname} ({OS}) — {날짜}

### 훅 [{실제}/{기대}]
✅ audit-log.sh
✅ block-deletion.ps1
❌ device-checkin.sh          ← 설치 필요
⚠️ notify-completion.sh (Mac) ← Windows용 .ps1만 있음, Mac용 .sh 필요

### 스킬 [{실제}/{기대}]
✅ git-commit
❌ setup-device               ← 설치 필요
...

### 플러그인
✅ bkit
✅ codex@openai-codex

### settings.json 훅 등록
✅ SessionStart → inject-session-context.sh, device-checkin.sh
✅ Stop → notify-completion.ps1, check-uncommitted.sh
...
```

### 4단계: 설치 명령어 제공

누락 항목이 있으면 아래 GitHub 레포 기반으로 설치 명령어를 출력합니다:

**GitHub 레포**: https://github.com/cplahatae-gif/claude-hooks

```bash
# Windows (Git Bash)
git clone https://github.com/cplahatae-gif/claude-hooks /tmp/claude-hooks
cp /tmp/claude-hooks/hooks/device-checkin.sh ~/.claude/hooks/
cp /tmp/claude-hooks/skills/setup-device/SKILL.md ~/.claude/skills/setup-device/SKILL.md

# Mac
git clone https://github.com/cplahatae-gif/claude-hooks /tmp/claude-hooks
cp /tmp/claude-hooks/hooks/*.sh ~/.claude/hooks/
# ⚠️ Mac에서는 .ps1 대신 .sh 버전이 필요한 훅이 있음 → Mac용 스크립트 작성 필요
```

Mac용 .sh 훅이 없는 경우, 구현이 필요한 목록을 출력하고 작성을 도와줍니다.

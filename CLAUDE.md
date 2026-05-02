# User-level Claude Configuration

## 외부 서비스 연동 정보 (rules/)

자격증명 등 별도 관리 정보는 `rules/` 하위 파일에 분리. 작업 요청 시 관련 파일을 Read 도구로 import해서 참조한다.

- **Raindrop.io**: @rules/raindrop.md — 북마크 MCP/REST API 자격증명 및 사용법

## Obsidian Local REST API 연동

볼트 작업 요청 시 해당 볼트 컨텍스트(경로)를 사용한다. API URL/Key는 동일하지만 Obsidian에서 해당 볼트가 열려있어야 동작한다.

### ⚠️ 작업 시작 전 필수 절차

볼트(A 또는 B)에서 노트 작성/조회/정리 등 **어떤 작업이든 요청하면**, 첫 도구 호출 전에 **반드시** 해당 볼트 루트의 `CLAUDE.md`를 Read 도구로 먼저 읽는다.

- **볼트 A CLAUDE.md**: `E:/.shortcut-targets-by-id/1A0SIVshe4TvCKXlR-jr-FdeHp3oYIIPJ/구글 동기화/옵시디언/1. 옵시디언 볼트/Gpters Study 21기 옵시디언 온보딩_v2/CLAUDE.md`
- **볼트 B CLAUDE.md**: `E:/.shortcut-targets-by-id/1A0SIVshe4TvCKXlR-jr-FdeHp3oYIIPJ/구글 동기화/옵시디언/1. 옵시디언 볼트/99. 삼표 옵시디언 볼트/CLAUDE.md`

**예외:** "연결 확인", "데일리 노트 열어줘"처럼 REST API 호출만으로 끝나는 단순 조작, 또는 같은 대화에서 이미 읽은 경우는 생략.

### 볼트 A (일상볼트): Gpters Study 21기 옵시디언 온보딩_v2

- **Base URL**: `https://127.0.0.1:27124`
- **API Key**: 환경변수 `$env:OBSIDIAN_API_KEY` 참조 (Windows User 환경변수에 등록됨)
- **Vault 경로**: `E:/.shortcut-targets-by-id/1A0SIVshe4TvCKXlR-jr-FdeHp3oYIIPJ/구글 동기화/옵시디언/1. 옵시디언 볼트/Gpters Study 21기 옵시디언 온보딩_v2`

### 볼트 B (회사볼트): 삼표 옵시디언 볼트

- **Base URL**: `https://127.0.0.1:27124`
- **API Key**: 환경변수 `$env:OBSIDIAN_API_KEY` 참조
- **Vault 경로**: `E:/.shortcut-targets-by-id/1A0SIVshe4TvCKXlR-jr-FdeHp3oYIIPJ/구글 동기화/옵시디언/1. 옵시디언 볼트/99. 삼표 옵시디언 볼트`

### REST API 핵심 명령

- 검색: `POST /search/simple/?query={검색어}`
- 열기: `POST /open/{path}`
- 읽기/쓰기: `GET` / `PUT /vault/{path}`
- 데일리: `GET /periodic/daily/`
- curl 사용 시 `-k` 플래그 필수 (자체서명 인증서)

### 사용 규칙

- "볼트 A", "일상볼트" → 볼트 A 컨텍스트
- "볼트 B", "회사볼트", "삼표볼트" → 볼트 B 컨텍스트
- 연결 실패 시 Obsidian에서 해당 볼트 전환 여부 확인 안내
- 볼트 추가 시 이 파일에 볼트 C 등으로 섹션 추가

> 볼트 A에서 강의노트 작업 시 볼트 A CLAUDE.md의 "GPTers 21기 강의노트 파이프라인" 섹션 참조

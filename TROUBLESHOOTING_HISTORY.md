# OpenMemory Troubleshooting & Resolution Log

This document summarizes the issues encountered, root causes, attempted solutions, and final remediation actions during recent debugging of the OpenMemory API + MCP server and its Railway deployment.

## Legend
- ✅ Resolved / mitigated
- ⚠️ Pending improvement / follow-up
- ❌ Unsuccessful attempt / discarded

## 1. Mem0 Client Initialization & Provider Configuration
### 1.1 Import Error: `cannot import name 'genai' from 'google'`
**Symptom:** During `Memory.from_config`, logs showed:
```
Warning: Failed to initialize memory client: cannot import name 'genai' from 'google'
```
**Root Cause:** The Google GenAI SDK dependency was not installed (initially only `mem0ai` + OpenAI packages). Later confusion arose between old `google-generativeai` vs newer `google-genai` / `google.genai` import path used internally.
**Actions:**
- Added `google-generativeai` to `requirements.txt` (✅ partial — import path later changed in mem0 updates).
- Updated to latest `mem0ai>=0.1.115` (✅).
- Switched to extras `mem0ai[google]` (✅) then explicitly added `google-genai` package (✅) for safety.
**Status:** ✅ Google provider dependencies installed.

### 1.2 Unsupported Provider Name
**Symptom:**
```
Unsupported LLM provider: google_ai
```
**Root Cause:** Incorrect provider key (`google_ai`) not recognized by mem0. Accepted values: `openai`, `google` (and later sometimes `gemini` confusion).
**Actions:** Updated config provider to `google` (✅). Then experimented with `gemini` (❌ caused further mismatch with mem0 expectations). Reverted to `google` (✅).
**Status:** ✅ Provider now set to a supported value.

### 1.3 Model Output Parsing Error
**Symptom:**
```
Error in new_retrieved_facts: string indices must be integers, not 'str'
```
**Root Cause:** The LLM returned a plain string where mem0 expected a structured object (likely JSON-like). Prompting / parsing mismatch.
**Actions:**
- Attempted to introduce non-existent `json_mode` config flag (❌ invalid config key).
- Plan shifted toward customizing `custom_fact_extraction_prompt` (not yet fully implemented in the log) (⚠️ follow-up possible).
**Status:** ⚠️ Could still refine prompt to enforce structured output. Library update might have addressed parsing internally.

### 1.4 Invalid JSON in `config.json`
**Symptom:** Malformed entry: `""json_mode": true"` causing JSON parse failure.
**Root Cause:** Typo during manual edit.
**Action:** Rewrote `config.json` cleanly (✅).
**Status:** ✅ Fixed.

## 2. Runtime Observability Improvements
### 2.1 Silent Failures During `add_memories`
**Action:** Added logging around `memory_client.add` in `mcp_server.py` to confirm call boundaries (✅). Helped surface downstream parsing error.
**Status:** ✅ Logging retained.

## 3. Deployment (Railway) Issues
### 3.1 `make up` Not Found
**Symptom:** Railway build attempted `make up` or similar target; error: `No rule to make target 'up'`.
**Root Cause:** Railway environment executed inside container/image without docker-compose or full root Makefile context (and even if present, docker-compose not appropriate inside managed container).
**Action:** Replaced start command with direct `uvicorn` invocation (✅) then later with wrapper script (✅).
**Status:** ✅.

### 3.2 `$PORT` Not Expanded
**Symptom:**
```
Error: Invalid value for '--port': '$PORT' is not a valid integer.
```
**Root Cause:** Uvicorn called directly without shell expansion for environment variable interpolation.
**Action:** Wrapped start command: `sh -c 'uvicorn ... --port ${PORT:-8000}'` (✅). Later replaced by script `run_api.sh` (✅ still shell-expands).
**Status:** ✅.

### 3.3 Import Failure (Uvicorn Cannot Import `api.main`)
**Symptom:** Stack trace at `import_from_string`.
**Root Cause:** Inconsistent working directory & missing `api/__init__.py` when referencing `api.main`.
**Actions:**
- Added `api/__init__.py` (✅).
- Introduced `run_api.sh` to `cd api` before launch (✅).
**Status:** ✅.

### 3.4 Alembic `script_location` Error
**Symptom:**
```
FAILED: No 'script_location' key found in configuration.
```
**Root Cause:** Alembic invoked from repo root with `-c api/alembic.ini` where `script_location = alembic` resolved incorrectly (expected working dir: `api/`).
**Actions:**
- Removed preDeploy Alembic invocation to unblock deploy (✅).
- Documented future options (adjust `script_location`, change working dir, or alter command) (✅ guidance).
**Status:** ✅ (migrations skipped; Base.metadata auto-creates tables).

### 3.5 Healthcheck Failures (`/` 404)
**Symptom:** Railway healthcheck repeated 503 / Not Ready.
**Root Cause:** No root route; healthcheckPath initially `/`.
**Actions:** Added `/` and `/healthz` endpoints; updated `healthcheckPath` to `/healthz` (✅).
**Status:** ✅.

## 4. Configuration & Environment
### 4.1 Secrets in Repository
**Symptom:** Real API keys committed in `api/.env`.
**Risk:** Credential leakage.
**Actions (recommended):** Rotate keys, add stricter `.gitignore`, rely on Railway environment variables (⚠️ follow-up action outside code base).
**Status:** ⚠️ Pending rotation if not already done.

### 4.2 Vector Store Host (`mem0_store`)
**Note:** That host exists only under docker-compose network. For Railway (single container) either external Qdrant must be configured or fallback store used.
**Action:** (Advisory only) (⚠️ confirm adaptation for production).

## 5. Files Added / Modified (Key)
- `api/config.json` (provider + model adjustments; corrections for JSON validity)
- `api/app/mcp_server.py` (logging around `memory_client.add`)
- `api/main.py` (root + health endpoints, startup logs)
- `railway.toml` (build/start command iterations, healthcheck path)
- `run_api.sh` (centralized startup script)
- `api/__init__.py` (package marker)
- `Makefile` (added `chmod-run` target)
- `requirements.txt` (updated `mem0ai` version; provider extras / google packages)

## 6. Remaining / Suggested Follow-Ups
| Area | Recommendation | Priority |
|------|----------------|----------|
| Secrets | Rotate exposed API keys & remove from repo | High |
| Migrations | Reintroduce Alembic once stable (Option A: adjust script_location path) | Medium |
| Vector Store | Configure external Qdrant or adjust config for Railway environment | Medium |
| Prompt Robustness | Add explicit structured `custom_fact_extraction_prompt` for Gemini to avoid parsing errors | Medium |
| Testing | Add unit test covering `memory_client.add` with mocked Gemini response | Medium |
| Logging | Structured logging (JSON) for easier platform analysis | Low |
| Health | Add DB + vector store deeper checks in `/healthz` | Low |

## 7. Sample Re-Enabled Migration Command (Future)
If you later want migrations on deploy (Option A):
```toml
[deploy]
preDeployCommand = ["bash -lc 'cd api && alembic upgrade head'"]
startCommand = "sh run_api.sh"
```
Or adjust `api/alembic.ini`:
```
[alembic]
script_location = api/alembic
```
Then call:
```
alembic upgrade head
```

## 8. Structured Prompt Suggestion (Gemini)
Add to DB config or `custom_fact_extraction_prompt`:
```
Extract factual memory units from the user input.
Return ONLY valid JSON:
{
  "facts": [ {"fact": "string", "category": "string"} ]
}
If none, return {"facts": []}.
```

## 9. Quick Deployment Expectations (Current State)
- Build: Installs deps via `cd api && pip install -r requirements.txt`.
- Start: `run_api.sh` ensures correct working dir & launches uvicorn.
- Health: `/healthz` returns `{"ok": true, "db": <bool>}`.
- Tables: Created by `Base.metadata.create_all` on startup.

## 10. Timeline (High-Level)
1. Initial provider switch → import failures.
2. Added Google dependencies → provider name errors.
3. Config corrections → parsing/type error surfaced.
4. Added logging for clarity.
5. Began Railway deployment → Makefile / compose mismatch.
6. Fixed start command & PORT expansion.
7. Encountered Alembic path issues → removed migrations.
8. Added health endpoints → resolved healthcheck failures.
9. Wrapped startup in script for stability.

---
**Current Status:** Service should now start cleanly on Railway with health endpoint responding, mem0 client initialization contingent on correct external services (Qdrant / LLM API keys). Some enhancements and security cleanup remain.

## 11. New Issue: `run_api.sh` Not Found on Deployment
**Symptom:** Latest Railway deploy failed with: `sh: 0: cannot open run_api.sh: No such file`.
**Root Cause:** Runtime working directory inside the Railway/Nixpacks container was not the repository root (likely `api/`), so the relative path `run_api.sh` (which lives at repo root) was not resolvable. The `startCommand` in `railway.toml` assumed the script was in the current directory.
**Resolution:** Replaced `startCommand = "sh run_api.sh"` with a direct uvicorn invocation that first `cd api`:
```
startCommand = "sh -c 'cd api && uvicorn main:app --host 0.0.0.0 --port ${PORT:-8000}'"
```
This removes the extra indirection and avoids path ambiguity. The previous convenience logic (re-installing requirements) is unnecessary at runtime because dependencies are already installed during the build step.
**Status:** ✅ Fixed (pending next deploy confirmation).

**Follow-Up (Optional):** If you still want a wrapper script, move it inside `api/` or call it via an absolute path; otherwise the simplified command is preferable.

Feel free to extend this log with future incidents.

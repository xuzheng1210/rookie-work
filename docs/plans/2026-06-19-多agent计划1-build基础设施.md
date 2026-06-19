# 多agent·计划1：build 基础设施 Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 建立"单一真相源 → 生成各 agent 包"的 build 基础设施：一个 `build/build.sh` 把仓库根的权威内容拷进 `dist/codex/`、`dist/hermes/` 的共享部分，配一个防漂移测试；并把 CC 钩子的项目目录变量改成 Codex 兼容（CC 不回归）。

**Architecture:** 仓库根的 `SKILL.md`/`SESSION-PREAMBLE.md`/`references/` 是唯一权威内容。`build/build.sh`（bash、确定性、每次清空重生成）把这些拷到 `dist/<agent>/` 的标准位置（技能放 `skills/rookie-work/` 子目录、preamble 放包根）。`dist/` 提交入库，用 `dist/README.md` 整体标"勿手改"。`tests/test-build.sh` 校验生成物与权威源逐字一致且确定性可重现（防漂移）。各 agent 专属的清单/钩子留给计划 2、3 扩展本脚本。

**Tech Stack:** bash、`diff`、`git`。本计划不依赖 Codex/Hermes 真机（纯本仓库构建+测试）。

---

## 前提与约束

- 依赖原 rookie-work 仓库现状（根有 `SKILL.md`/`SESSION-PREAMBLE.md`/`references/`/`hooks/`/`tests/`）。
- **不破坏 CC v1.0.0**：仓库根 CC 插件与 `.claude-plugin/marketplace.json` `source:"./"` 不动；本计划只新增 `build/`、`dist/`、`tests/test-build.sh`，并对 `hooks/session-start` 做一处向后兼容改动。
- 生成物**确定性**：不含时间戳/随机；`build.sh` 每次 `rm -rf` 后重生成，保证重跑 `git diff dist/` 干净。

## 文件结构（本计划产出）

```
build/build.sh                 # 新增：装配 dist/ 共享内容
dist/codex/skills/rookie-work/{SKILL.md, references/}   # 生成
dist/codex/SESSION-PREAMBLE.md                          # 生成
dist/hermes/skills/rookie-work/{SKILL.md, references/}  # 生成
dist/hermes/SESSION-PREAMBLE.md                         # 生成
dist/README.md                 # 生成：整 dist/ 的"勿手改"标记
hooks/session-start            # 改：项目目录变量 → Codex 兼容
tests/test-build.sh            # 新增：防漂移 + 结构校验
```

---

### Task 1: `hooks/session-start` 项目目录变量改 Codex 兼容（CC 不回归）

**Files:**
- Modify: `hooks/session-start`

- [ ] **Step 1: 改一行**

在 `~/projects/rookie-work/hooks/session-start` 中，把这一行：
```bash
PROJECT_DIR="${CLAUDE_PROJECT_DIR:-$PWD}"
```
改为：
```bash
PROJECT_DIR="${CODEX_PROJECT_DIR:-${CLAUDE_PROJECT_DIR:-$PWD}}"
```
（CC 下 `CODEX_PROJECT_DIR` 未设 → 落到 `CLAUDE_PROJECT_DIR`，行为不变；Codex 复用同脚本时优先用 `CODEX_PROJECT_DIR`。其余行不动。）

- [ ] **Step 2: 跑 CC 钩子测试，确认不回归**

Run: `bash ~/projects/rookie-work/tests/test-session-start.sh`
Expected: 末行 `PASS=7 FAIL=0`，退出码 0（测试设的是 `CLAUDE_PROJECT_DIR`，`CODEX_PROJECT_DIR` 未设，行为与改前一致）。

- [ ] **Step 3: 提交**

```bash
git -C ~/projects/rookie-work add hooks/session-start
git -C ~/projects/rookie-work commit -m "feat: session-start 项目目录变量兼容 Codex(\${CODEX_PROJECT_DIR} 优先,CC 无回归)"
```

---

### Task 2: 防漂移测试 `tests/test-build.sh`（先写，必失败）

**Files:**
- Create: `tests/test-build.sh`

- [ ] **Step 1: 写测试**

写入 `~/projects/rookie-work/tests/test-build.sh`，内容：

```bash
#!/usr/bin/env bash
# Tests for build/build.sh: shared content is placed per-agent, matches the
# canonical sources byte-for-byte, and regeneration is deterministic (anti-drift).
set -uo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
PASS=0; FAIL=0
ok(){ echo "PASS: $1"; PASS=$((PASS+1)); }
bad(){ echo "FAIL: $1"; FAIL=$((FAIL+1)); }

if [ ! -x "${ROOT}/build/build.sh" ] && [ ! -f "${ROOT}/build/build.sh" ]; then
  echo "FAIL: build/build.sh missing"; echo "PASS=0 FAIL=1"; exit 1
fi
bash "${ROOT}/build/build.sh" >/dev/null 2>&1 || { echo "FAIL: build.sh did not run cleanly"; echo "PASS=0 FAIL=1"; exit 1; }

for agent in codex hermes; do
  base="${ROOT}/dist/${agent}"
  if diff -q "${ROOT}/SKILL.md" "${base}/skills/rookie-work/SKILL.md" >/dev/null 2>&1; then ok "${agent}: SKILL.md == canonical"; else bad "${agent}: SKILL.md == canonical"; fi
  if diff -q "${ROOT}/SESSION-PREAMBLE.md" "${base}/SESSION-PREAMBLE.md" >/dev/null 2>&1; then ok "${agent}: SESSION-PREAMBLE.md == canonical"; else bad "${agent}: SESSION-PREAMBLE.md == canonical"; fi
  for r in changelog-format model-and-review-policy; do
    if diff -q "${ROOT}/references/${r}.md" "${base}/skills/rookie-work/references/${r}.md" >/dev/null 2>&1; then ok "${agent}: ref ${r} == canonical"; else bad "${agent}: ref ${r} == canonical"; fi
  done
done

if [ -f "${ROOT}/dist/README.md" ] && grep -q "DO NOT EDIT" "${ROOT}/dist/README.md"; then ok "dist/README.md generated-marker"; else bad "dist/README.md generated-marker"; fi

# Determinism: snapshot, rebuild, compare contents
T1="$(mktemp -d)"; cp -R "${ROOT}/dist" "${T1}/dist1"
bash "${ROOT}/build/build.sh" >/dev/null 2>&1
if diff -rq "${T1}/dist1" "${ROOT}/dist" >/dev/null 2>&1; then ok "deterministic (rebuild identical)"; else bad "deterministic (rebuild identical)"; fi
rm -rf "$T1"

echo "----"; echo "PASS=$PASS FAIL=$FAIL"
[ "$FAIL" -eq 0 ]
```

- [ ] **Step 2: 赋可执行 + 运行（应失败）**

Run:
```bash
chmod +x ~/projects/rookie-work/tests/test-build.sh
bash ~/projects/rookie-work/tests/test-build.sh
```
Expected: **FAIL** —— `build/build.sh` 尚不存在，首段判定即 `FAIL: build/build.sh missing`，末行 `PASS=0 FAIL=1`，退出码 1。

- [ ] **Step 3: 提交**

```bash
git -C ~/projects/rookie-work add tests/test-build.sh
git -C ~/projects/rookie-work commit -m "test: 加入 build 防漂移测试(当前必失败)"
```

---

### Task 3: `build/build.sh`（实现到测试全过）+ 提交 dist/

**Files:**
- Create: `build/build.sh`
- Create（生成物）: `dist/**`

- [ ] **Step 1: 写 `build/build.sh`**

写入 `~/projects/rookie-work/build/build.sh`，内容：

```bash
#!/usr/bin/env bash
# Build per-agent packages from the canonical sources at the repo root.
# Canonical (single source of truth): SKILL.md, SESSION-PREAMBLE.md, references/.
# Output: dist/codex/, dist/hermes/  (committed; DO NOT edit by hand — edit canonical + rebuild).
# Deterministic: clean + regenerate, no timestamps.
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
DIST="${ROOT}/dist"
SKILL="${ROOT}/SKILL.md"
PREAMBLE="${ROOT}/SESSION-PREAMBLE.md"
REFS="${ROOT}/references"

# Shared content placed identically for every agent. Agent-specific manifests /
# hooks are added by later build steps (plans 2 & 3).
rm -rf "${DIST}/codex" "${DIST}/hermes"
for agent in codex hermes; do
  mkdir -p "${DIST}/${agent}/skills/rookie-work"
  cp "${SKILL}" "${DIST}/${agent}/skills/rookie-work/SKILL.md"
  cp -R "${REFS}" "${DIST}/${agent}/skills/rookie-work/references"
  cp "${PREAMBLE}" "${DIST}/${agent}/SESSION-PREAMBLE.md"
done

# Generated-marker for the whole dist/ (SKILL.md frontmatter & JSON can't carry comments).
mkdir -p "${DIST}"
cat > "${DIST}/README.md" <<'EOF'
# GENERATED — DO NOT EDIT

Everything under `dist/` is generated by `build/build.sh` from the canonical
sources at the repo root (`SKILL.md`, `SESSION-PREAMBLE.md`, `references/`).
To change behavior, edit those canonical files and re-run `build/build.sh`.
EOF

echo "build: regenerated dist/codex and dist/hermes (shared content)"
```

- [ ] **Step 2: 赋可执行 + 跑测试（应全过）**

Run:
```bash
chmod +x ~/projects/rookie-work/build/build.sh
bash ~/projects/rookie-work/tests/test-build.sh
```
Expected: **PASS** —— 末行 `PASS=10 FAIL=0`（2 agent ×（SKILL+PREAMBLE+2 refs）=8，+ dist/README 标记 + 确定性 = 10），退出码 0。

- [ ] **Step 3: 提交 build.sh 与生成的 dist/**

```bash
git -C ~/projects/rookie-work add build/build.sh dist/
git -C ~/projects/rookie-work commit -m "feat: build/build.sh 生成各 agent 共享内容 + dist/(防漂移测试全过)"
```

---

## 完成判据（Plan 1 Done）

- `hooks/session-start` 项目目录变量已兼容 Codex；`tests/test-session-start.sh` 仍 `PASS=7 FAIL=0`（CC 无回归）。
- `build/build.sh` 可执行、确定性；`tests/test-build.sh` `PASS=10 FAIL=0`。
- `dist/codex/`、`dist/hermes/` 含与权威源逐字一致的共享内容（SKILL.md/SESSION-PREAMBLE.md/references），`dist/README.md` 标"勿手改"，均已提交。
- CC 仓库根与发布路径未受影响。
- **地基就位**：计划 2、3 只需向 `build.sh` 增加各自 agent 的清单/钩子装配，并扩展 `tests/test-build.sh` 校验。

## 自审（写完即查，对照 spec）

- **spec 覆盖**：落地 §2「CC 根=真相源 + build 生成 + dist/ 布局 + 防漂移闸」与 §3 共享内容三家同；§3 提到的 `session-start` Codex 兼容改动在 Task 1 完成；各 agent 专属清单/钩子（§3/§4）按计划留给计划 2、3。
- **占位扫描**：无 TBD/TODO；生成物"勿手改"以 `dist/README.md` 实现（已说明为何不用首行注释）。
- **类型/命名一致**：`dist/<agent>/skills/rookie-work/` 路径在 build.sh 与 test-build.sh 两处一致；`PASS=10` 与测试断言数（8+1+1）一致；`DO NOT EDIT` 标记串两处一致。
- **确定性/防漂移**：build.sh `rm -rf` 后重生成、无时间戳；测试含"重建逐字相同"断言，保证 `git diff dist/` 可干净。
- **不回归 CC**：Task 1 改动经 `test-session-start.sh` 验证；仅新增 `build/`、`dist/`、`tests/test-build.sh`。

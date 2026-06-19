# 多agent·计划3：Hermes 包 Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 为 Hermes 装配 rookie-work 包——一个 `pre_llm_call` shell 钩子（首回合注入 preamble + 标记开关）、技能（计划 1 已放）、config 片段与 INSTALL 文档；配钩子单测与防漂移断言；再真机验证。

**Architecture:** Hermes 注入靠 `pre_llm_call` shell 钩子（每回合触发，用 stdin payload 的 `extra.is_first_turn` 收敛到只开场），stdout 输出 `{"context":…}`，同一套标记文件关闭法。技能 `SKILL.md` 已由计划 1 放进 `dist/hermes/skills/rookie-work/`；本计划新增钩子脚本（`build/templates/hermes/` 为源、build 拷进 `dist/hermes/agent-hooks/`，与其要读的 `SESSION-PREAMBLE.md` **co-located**）+ config 片段 + INSTALL。Route A（零 Python 插件；钩子用 `python3` 仅作 JSON 解析，Hermes 运行环境必有）。

**Tech Stack:** bash、`python3`（解析 is_first_turn / 校验 JSON）、git；Task 2 需 **Hermes 真机**。

---

## 前提与约束
- 依赖**计划 1**（build 基础设施、`dist/hermes/` 共享内容）。计划 2（Codex）非前置，但同改 `build.sh`/`test-build.sh`，按线性顺序在其后。
- **风险（spec §7.2）**：`pre_llm_call` 每回合注入的体验/成本 + 钩子首次同意摩擦 → Task 2 真机验证 `is_first_turn` 收敛与同意流程。
- 钩子解析失败**保守不注入**（fail-off，避免每回合刷屏）；真机验证确认首回合确实注入。

## 文件结构（本计划产出）
```
build/templates/hermes/rookie-work-inject.sh   # 新增：pre_llm_call 钩子（源）
build/templates/hermes/config-snippet.yaml     # 新增：合并进 ~/.hermes/config.yaml 的钩子声明
build/templates/hermes/INSTALL.md              # 新增：Hermes 安装说明
build/build.sh                                 # 改：追加 Hermes 装配块
dist/hermes/agent-hooks/{rookie-work-inject.sh, SESSION-PREAMBLE.md}  # 生成（co-located）
dist/hermes/{config-snippet.yaml, INSTALL.md}  # 生成
tests/test-pre-llm-call.sh                     # 新增：钩子行为单测
tests/test-build.sh                            # 改：追加 4 条 Hermes 结构断言
README.md                                      # 改：+ Hermes 安装段
```

---

### Task 1: Hermes 钩子 + 装配 + 两个测试（本仓库，自动）

**Files:**
- Create: `tests/test-pre-llm-call.sh`, `build/templates/hermes/{rookie-work-inject.sh,config-snippet.yaml,INSTALL.md}`
- Modify: `build/build.sh`, `tests/test-build.sh`

- [ ] **Step 1: 写钩子单测 `tests/test-pre-llm-call.sh`（先写，必失败）**

写入 `~/projects/rookie-work/tests/test-pre-llm-call.sh`：

```bash
#!/usr/bin/env bash
# Tests the Hermes pre_llm_call hook source: first-turn injection, non-first no-op, off-switch.
set -uo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
SRC="${ROOT}/build/templates/hermes/rookie-work-inject.sh"
PASS=0; FAIL=0
ok(){ echo "PASS: $1"; PASS=$((PASS+1)); }
bad(){ echo "FAIL: $1"; FAIL=$((FAIL+1)); }

if [ ! -f "$SRC" ]; then echo "FAIL: hook source missing"; echo "PASS=0 FAIL=1"; exit 1; fi
TMP="$(mktemp -d)"; trap 'rm -rf "$TMP"' EXIT
mkdir -p "$TMP/ah" "$TMP/home" "$TMP/proj"
cp "$SRC" "$TMP/ah/rookie-work-inject.sh"; chmod +x "$TMP/ah/rookie-work-inject.sh"
cp "${ROOT}/SESSION-PREAMBLE.md" "$TMP/ah/SESSION-PREAMBLE.md"   # co-located, as build does
run(){ ( cd "$TMP/proj" && HOME="$TMP/home" bash "$TMP/ah/rookie-work-inject.sh" <<<"$1" ); }
FIRST='{"extra":{"is_first_turn":true}}'
NOTFIRST='{"extra":{"is_first_turn":false}}'

OUT="$(run "$FIRST")"
printf '%s' "$OUT" | python3 -m json.tool >/dev/null 2>&1 && ok "first: valid JSON" || bad "first: valid JSON"
printf '%s' "$OUT" | grep -q '"context"' && ok "first: has context" || bad "first: has context"
printf '%s' "$OUT" | grep -q "Explain before you act" && ok "first: injects preamble" || bad "first: injects preamble"

OUT="$(run "$NOTFIRST")"
printf '%s' "$OUT" | grep -q "Explain before you act" && bad "non-first: no injection" || ok "non-first: no injection"

touch "$TMP/home/.rookie-work-off"; OUT="$(run "$FIRST")"
printf '%s' "$OUT" | grep -q "Explain before you act" && bad "global off: suppressed" || ok "global off: suppressed"
rm -f "$TMP/home/.rookie-work-off"

touch "$TMP/proj/.rookie-work-off"; OUT="$(run "$FIRST")"
printf '%s' "$OUT" | grep -q "Explain before you act" && bad "project off: suppressed" || ok "project off: suppressed"

echo "----"; echo "PASS=$PASS FAIL=$FAIL"
[ "$FAIL" -eq 0 ]
```

- [ ] **Step 2: 赋可执行 + 运行（应失败）**

Run:
```bash
chmod +x ~/projects/rookie-work/tests/test-pre-llm-call.sh
bash ~/projects/rookie-work/tests/test-pre-llm-call.sh
```
Expected: **FAIL** —— 钩子源 `build/templates/hermes/rookie-work-inject.sh` 不存在，首判即 `FAIL: hook source missing`，`PASS=0 FAIL=1`。

- [ ] **Step 3: 写钩子源 `build/templates/hermes/rookie-work-inject.sh`**

写入：

```bash
#!/usr/bin/env bash
# rookie-work pre_llm_call hook for Hermes: inject the discipline preamble once,
# at the first turn of a session, unless an off-switch marker is present.
# Reads the Hermes event payload (JSON) on stdin; emits {"context": ...} or {}.
set -euo pipefail

INPUT="$(cat 2>/dev/null || true)"

# Off-switch: global or project marker -> no-op.
if [ -f "${HOME}/.rookie-work-off" ] || [ -f "${PWD}/.rookie-work-off" ]; then
  printf '{}\n'; exit 0
fi

# pre_llm_call fires every turn; only inject on the first turn (payload extra.is_first_turn).
# Fail safe: on any parse problem, treat as NOT first turn (don't inject) rather than spam.
is_first="$(printf '%s' "$INPUT" | python3 -c "import sys,json;d=json.load(sys.stdin);print('true' if d.get('extra',{}).get('is_first_turn') else 'false')" 2>/dev/null || echo false)"
if [ "$is_first" != "true" ]; then
  printf '{}\n'; exit 0
fi

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PREAMBLE="$(cat "${SCRIPT_DIR}/SESSION-PREAMBLE.md" 2>/dev/null || echo "rookie-work is active, but its preamble file is missing.")"

escape_for_json() {
  local s="$1"
  s="${s//\\/\\\\}"
  s="${s//\"/\\\"}"
  s="${s//$'\n'/\\n}"
  s="${s//$'\r'/\\r}"
  s="${s//$'\t'/\\t}"
  printf '%s' "$s"
}
printf '{\n  "context": "%s"\n}\n' "$(escape_for_json "$PREAMBLE")"
exit 0
```

- [ ] **Step 4: 跑钩子单测（应全过）**

Run: `bash ~/projects/rookie-work/tests/test-pre-llm-call.sh`
Expected: **PASS** —— `PASS=6 FAIL=0`（首回合：JSON 合法 / 有 context / 注入 preamble；非首回合不注入；全局关抑制；项目关抑制）。

- [ ] **Step 5: 写 config 片段与 INSTALL 模板**

写入 `~/projects/rookie-work/build/templates/hermes/config-snippet.yaml`：
```yaml
# Merge this into your ~/.hermes/config.yaml.
# Runs rookie-work's pre_llm_call hook (first-turn injection + off-switch).
hooks:
  pre_llm_call:
    - command: "~/.hermes/agent-hooks/rookie-work-inject.sh"
      timeout: 10
```

写入 `~/projects/rookie-work/build/templates/hermes/INSTALL.md`：
````markdown
# Install rookie-work on Hermes

1) Install the skill (auto-exposes `/rookie-work`):
   ```bash
   cp -R skills/rookie-work ~/.hermes/skills/
   # or: hermes skills tap add xuzheng1210/rookie-work
   ```
2) Install the always-on hook (script + its preamble, kept together):
   ```bash
   mkdir -p ~/.hermes/agent-hooks
   cp agent-hooks/rookie-work-inject.sh agent-hooks/SESSION-PREAMBLE.md ~/.hermes/agent-hooks/
   ```
   Then merge `config-snippet.yaml` into `~/.hermes/config.yaml`. The first run asks you to
   approve the shell hook (or set `HERMES_ACCEPT_HOOKS=1`, or `hooks_auto_accept: true`).
3) Start a new session — `/rookie-work` is available and the discipline is injected on the first turn.

## Turn it off
- Marker file: create `~/.rookie-work-off` (everywhere) or `<project>/.rookie-work-off` (one project); delete to re-enable.
- Or natively: set `skills.disabled: [rookie-work]` in `~/.hermes/config.yaml`, or remove the `hooks:` entry.
````

- [ ] **Step 6: 扩展 `tests/test-build.sh`（加 4 条 Hermes 断言，先失败）**

在 `tests/test-build.sh` 的"determinism"段之**前**插入：
```bash
# --- Hermes-specific generated files ---
hh="${ROOT}/dist/hermes/agent-hooks/rookie-work-inject.sh"
if [ -x "$hh" ]; then ok "hermes: inject.sh present+exec"; else bad "hermes: inject.sh present+exec"; fi
if diff -q "${ROOT}/SESSION-PREAMBLE.md" "${ROOT}/dist/hermes/agent-hooks/SESSION-PREAMBLE.md" >/dev/null 2>&1; then ok "hermes: co-located preamble == canonical"; else bad "hermes: co-located preamble == canonical"; fi
if [ -f "${ROOT}/dist/hermes/config-snippet.yaml" ]; then ok "hermes: config-snippet.yaml present"; else bad "hermes: config-snippet.yaml present"; fi
if [ -f "${ROOT}/dist/hermes/INSTALL.md" ]; then ok "hermes: INSTALL.md present"; else bad "hermes: INSTALL.md present"; fi
```
Run `bash ~/projects/rookie-work/tests/test-build.sh` → Expected **FAIL**：`PASS=15 FAIL=4`（build.sh 尚未装配 Hermes 钩子等）。
（若计划 2 尚未执行、无 Codex 的 5 条断言，则基线为 10，此处显示 `PASS=10 FAIL=4`——以实际已执行计划为准。本计划假设计划 2 已执行，基线 15。）

- [ ] **Step 7: 向 `build/build.sh` 追加 Hermes 装配块**

在 `build/build.sh` 里、生成 `dist/README.md` 之**前**（Codex 块之后）插入：
```bash
# --- Hermes package: pre_llm_call hook + co-located preamble + config snippet + INSTALL ---
mkdir -p "${DIST}/hermes/agent-hooks"
cp "${ROOT}/build/templates/hermes/rookie-work-inject.sh" "${DIST}/hermes/agent-hooks/rookie-work-inject.sh"
chmod +x "${DIST}/hermes/agent-hooks/rookie-work-inject.sh"
cp "${PREAMBLE}" "${DIST}/hermes/agent-hooks/SESSION-PREAMBLE.md"
cp "${ROOT}/build/templates/hermes/config-snippet.yaml" "${DIST}/hermes/config-snippet.yaml"
cp "${ROOT}/build/templates/hermes/INSTALL.md" "${DIST}/hermes/INSTALL.md"
```

- [ ] **Step 8: 跑两个测试（应全过）**

Run:
```bash
bash ~/projects/rookie-work/tests/test-build.sh
bash ~/projects/rookie-work/tests/test-pre-llm-call.sh
```
Expected: `test-build.sh` → `PASS=19 FAIL=0`（15 + Hermes 4）；`test-pre-llm-call.sh` → `PASS=6 FAIL=0`。

- [ ] **Step 9: 提交**

```bash
git -C ~/projects/rookie-work add build/templates/hermes/ build/build.sh tests/test-pre-llm-call.sh tests/test-build.sh dist/
git -C ~/projects/rookie-work commit -m "feat: build 增加 Hermes 包(pre_llm_call 钩子+config+INSTALL;首回合注入+标记开关,单测全过)"
```

---

### Task 2: 真机验证 Hermes（需 Hermes 真机；验证 §7.2 风险）

**Files:** 无（真机安装 + 观察）

> 目标：①技能 `/rookie-work` 可用 ②**首回合自动注入纪律、后续回合不重复**（`is_first_turn` 收敛）③首次同意流程可接受 ④标记开关。**没装 Hermes 就停在此处，标记"待你装 Hermes 后继续"。**

- [ ] **Step 1: 安装**

按 `dist/hermes/INSTALL.md`：拷 `dist/hermes/skills/rookie-work` 到 `~/.hermes/skills/`；拷 `dist/hermes/agent-hooks/*` 到 `~/.hermes/agent-hooks/`；把 `dist/hermes/config-snippet.yaml` 合并进 `~/.hermes/config.yaml`。记录首次钩子同意的实际体验（是否弹同意、`HERMES_ACCEPT_HOOKS`/`hooks_auto_accept` 是否需要）。

- [ ] **Step 2: 验技能**

新会话看 `/rookie-work` 是否自动暴露（Hermes 按 name slug 生成）。

- [ ] **Step 3: 验首回合注入 + 收敛（关键风险）**

新会话第一句问：「先说你是否处于某套工作护栏、叫什么、规则是什么。」→ 应复述 rookie-work 纪律。
再多发几轮普通消息，观察：纪律**只在首回合注入一次**、后续回合没有重复刷屏（`is_first_turn` 收敛生效）。记录体验/成本是否可接受。

- [ ] **Step 4: 验标记开关**

`touch ~/.rookie-work-off` → 新会话首回合应不再注入；`rm` 后恢复。也可顺带验原生 `skills.disabled:[rookie-work]`。

- [ ] **Step 5: 记录结论**（同意体验、收敛是否够、是否要在 INSTALL 补 `hooks_auto_accept` 指引）。**无文件改动不提交**；若需补 INSTALL 文案，改 `build/templates/hermes/INSTALL.md` → 重跑 `build.sh` → 提交。

---

### Task 3: README Hermes 段

**Files:**
- Modify: `README.md`

- [ ] **Step 1: 加 Hermes 段**

在 README 的 Codex 段之后加：
```markdown
## Install on Hermes

See `dist/hermes/INSTALL.md` for the full steps. In short: copy the skill into
`~/.hermes/skills/` (or `hermes skills tap add xuzheng1210/rookie-work`), copy the hook
into `~/.hermes/agent-hooks/`, and merge `dist/hermes/config-snippet.yaml` into
`~/.hermes/config.yaml` (first run asks you to approve the hook). New session →
`/rookie-work` is available and the discipline is injected on the first turn.

Turn it off the same way (`~/.rookie-work-off` / per-project marker), or natively via
`skills.disabled: [rookie-work]` in `~/.hermes/config.yaml`.
```

- [ ] **Step 2: 校验**

Run: `grep -n "Install on Hermes" ~/projects/rookie-work/README.md`
Expected：命中一行。

- [ ] **Step 3: 提交**

```bash
git -C ~/projects/rookie-work add README.md
git -C ~/projects/rookie-work commit -m "docs: README 增加 Hermes 安装段"
```

---

## 完成判据（Plan 3 Done）
- `build/templates/hermes/` 三件齐；`build.sh` 生成 `dist/hermes/`（钩子+co-located preamble+config+INSTALL）。
- `tests/test-pre-llm-call.sh` `PASS=6 FAIL=0`；`tests/test-build.sh` `PASS=19 FAIL=0`（含 Hermes 4 条）。
- 真机 Hermes：`/rookie-work` 可用；**首回合注入、后续不重复**；首次同意流程已实测；标记开关 + 原生 `skills.disabled` 可关。
- README 有 Hermes 段；CC/Codex 不受影响（防漂移闸绿）。

## 自审（写完即查，对照 spec）
- **spec 覆盖**：§3 Hermes 钩子变体（`pre_llm_call`/`{"context"}`/`is_first_turn`）、§4.2 Hermes 包（技能+钩子+config+INSTALL）、§5 Hermes 自托管安装、§6 标记开关+原生 `skills.disabled`、§7.2 风险（Task 2 验证收敛+同意）、§8 测试（新增 `test-pre-llm-call.sh` + 防漂移扩 4 条）。
- **占位扫描**：无 TBD；INSTALL/README 文案完整；Step 6 注明基线随"计划 2 是否已执行"而定（10 或 15），是诚实的依赖说明非留白。
- **类型/命名一致**：`dist/hermes/agent-hooks/{rookie-work-inject.sh,SESSION-PREAMBLE.md}`、`config-snippet.yaml`、`INSTALL.md` 在模板/build.sh/test-build/INSTALL 各处一致；钩子读 `${SCRIPT_DIR}/SESSION-PREAMBLE.md`（co-located）与 build 拷贝位置一致；标记 `~/.rookie-work-off`/`${PWD}/.rookie-work-off` 与 CC/Codex 同；测试断言句「Explain before you act」与权威 preamble 逐字一致；`PASS=19`=15+4、`PASS=6`。
- **fail-off 安全**：解析失败默认不注入；真机 Task 2 确认首回合确实注入。
- **顺序依赖**：依赖计划 1（基础设施）、计划 2（test-build 基线 15）；Task 1 自动、Task 2 需 Hermes 真机。

# 多agent·计划2：Codex 包 Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 用 `build/build.sh` 把 Codex 包装配齐全（`.codex-plugin/plugin.json` + 复用 CC 钩子），并在真机 Codex 上验证"技能可用 + 钩子注入 + 标记开关"，确认安装路后写 README Codex 段。

**Architecture:** Codex 与 CC 契约同构：技能 = `SKILL.md`（已由计划 1 放进 `dist/codex/skills/rookie-work/`），钩子 = 复用 CC 的 `session-start`（Codex 提供 `CLAUDE_PLUGIN_ROOT` 别名 + 同款 `additionalContext` 契约）。计划 1 已铺好共享内容；本计划向 `build.sh` 增加 Codex 专属装配（清单 + 钩子拷贝），扩展防漂移测试，再真机验证。**Codex 包内容与"钩子自带激活 vs 用户级安装"无关**，故先构建后验证。

**Tech Stack:** bash、`python3`（读版本/校验 JSON）、`sed`（版本注入）、git；Task 2/3 需 **Codex 真机**。

---

## 前提与约束
- 依赖**计划 1**（build 基础设施、`dist/` 共享内容、`session-start` 已 Codex 兼容）。
- 不破坏 CC。版本**单一来源**：Codex 清单的 `version` 由 `build.sh` 从 `.claude-plugin/plugin.json` 读出注入，不手维护第二处。
- **风险（spec §7.1）**：Codex 插件自带 `hooks/hooks.json` 是否安装即自动激活未确认 → Task 2 真机验证；若否，退路 = 用户级 `~/.codex/hooks.json`（已确认支持），仍保住强制注入。

## 文件结构（本计划产出）
```
build/templates/codex/plugin.json     # 新增：Codex 清单模板（__VERSION__ 占位）
build/build.sh                        # 改：追加 Codex 装配块
dist/codex/.codex-plugin/plugin.json  # 生成
dist/codex/hooks/{hooks.json,session-start,run-hook.cmd}  # 生成（复用 CC 钩子）
tests/test-build.sh                   # 改：追加 5 条 Codex 断言
README.md                             # 改：+ Codex 安装段
```

---

### Task 1: build.sh 增加 Codex 装配 + 清单模板 + 测试（本仓库，自动）

**Files:**
- Create: `build/templates/codex/plugin.json`
- Modify: `build/build.sh`
- Modify: `tests/test-build.sh`

- [ ] **Step 1: 扩展 `tests/test-build.sh`（先加断言，必失败）**

在 `tests/test-build.sh` 的"determinism"段**之前**（即各 agent 共享断言之后）插入：

```bash
# --- Codex-specific generated files ---
cm="${ROOT}/dist/codex/.codex-plugin/plugin.json"
if python3 -c "import json,sys;m=json.load(open('${cm}'));sys.exit(0 if m.get('name')=='rookie-work' and m.get('skills')=='./skills/' else 1)" 2>/dev/null; then ok "codex: plugin.json valid (name+skills)"; else bad "codex: plugin.json valid (name+skills)"; fi
ccv="$(python3 -c "import json;print(json.load(open('${ROOT}/.claude-plugin/plugin.json'))['version'])" 2>/dev/null)"
cxv="$(python3 -c "import json;print(json.load(open('${cm}'))['version'])" 2>/dev/null)"
if [ -n "$cxv" ] && [ "$ccv" = "$cxv" ]; then ok "codex: version matches CC ($ccv)"; else bad "codex: version matches CC (cc=$ccv codex=$cxv)"; fi
for f in hooks/hooks.json hooks/session-start hooks/run-hook.cmd; do
  if [ -f "${ROOT}/dist/codex/${f}" ]; then ok "codex: ${f} present"; else bad "codex: ${f} present"; fi
done
```

- [ ] **Step 2: 运行，确认新断言失败**

Run: `bash ~/projects/rookie-work/tests/test-build.sh`
Expected: **FAIL** —— 共享断言仍过、5 条新 Codex 断言失败（`dist/codex/.codex-plugin/` 与 `hooks/` 尚未生成），末行 `PASS=10 FAIL=5`。

- [ ] **Step 3: 写 Codex 清单模板**

写入 `~/projects/rookie-work/build/templates/codex/plugin.json`：

```json
{
  "name": "rookie-work",
  "version": "__VERSION__",
  "description": "A beginner-safe workflow guardrail: the agent explains in plain language what it will do and gets your OK before changing anything, scales ceremony to task size, and never makes silent decisions.",
  "skills": "./skills/",
  "author": { "name": "xuzheng1210" },
  "homepage": "https://github.com/xuzheng1210/rookie-work",
  "repository": "https://github.com/xuzheng1210/rookie-work",
  "license": "MIT",
  "keywords": ["beginner", "workflow", "guardrails", "safety", "collaboration"],
  "interface": { "displayName": "Rookie Work", "category": "Coding" }
}
```

- [ ] **Step 4: 向 `build/build.sh` 追加 Codex 装配块**

在 `build/build.sh` 里、生成 `dist/README.md` 的 `cat > ...` 之**前**，插入：

```bash
# --- Codex package: manifest (version injected from CC's manifest) + reuse CC hooks ---
VER="$(python3 -c "import json;print(json.load(open('${ROOT}/.claude-plugin/plugin.json'))['version'])")"
mkdir -p "${DIST}/codex/.codex-plugin" "${DIST}/codex/hooks"
sed "s/__VERSION__/${VER}/" "${ROOT}/build/templates/codex/plugin.json" > "${DIST}/codex/.codex-plugin/plugin.json"
cp "${ROOT}/hooks/hooks.json" "${ROOT}/hooks/session-start" "${ROOT}/hooks/run-hook.cmd" "${DIST}/codex/hooks/"
```

- [ ] **Step 5: 跑测试（应全过）**

Run: `bash ~/projects/rookie-work/tests/test-build.sh`
Expected: **PASS** —— 末行 `PASS=15 FAIL=0`（计划 1 的 10 + Codex 的 5）。

- [ ] **Step 6: 提交**

```bash
git -C ~/projects/rookie-work add build/templates/codex/plugin.json build/build.sh tests/test-build.sh dist/
git -C ~/projects/rookie-work commit -m "feat: build 增加 Codex 包装配(.codex-plugin + 复用钩子;版本单源注入)"
```

---

### Task 2: 真机验证 Codex（需 Codex 真机；确认关键风险与安装路）

**Files:** 无（真机安装 + 观察）

> 目标：装上 `dist/codex` 后确认 ①技能可用 ②**钩子是否在新会话注入 preamble**（spec §7.1 风险）③标记文件开关。**装不上 Codex 就停在此处**，把后续标记为"待你装 Codex 后继续"。

- [ ] **Step 1: 装上 Codex 包（试自托管/插件目录两种）**

先按 Codex 现行文档把 `~/projects/rookie-work/dist/codex` 作为插件安装（`/plugins` 自托管 marketplace，或 Codex 文档给的本地插件目录方式）。
若一时找不到"装插件目录"的入口，**退一步先验技能**：把 `dist/codex/skills/rookie-work/` 拷进 `~/.codex/skills/`，确认技能能被发现（这步只验技能、不验钩子）。
记录：用的哪条安装方式、是否报错。

- [ ] **Step 2: 验技能可用**

新开 Codex 会话，看 `/skills` 或输入 `$rookie-work`。
Expected：出现/可调用 `rookie-work`。

- [ ] **Step 3: 验钩子是否自动注入（关键风险）**

新开 Codex 会话，先别给任务，问：「在我提任何要求前，先说你现在是否处于某套工作护栏之下、叫什么、规则是什么。」
- **若**它复述出 rookie-work 的承诺/三原则/三档 → **自带钩子激活成立**，记"bundled-hook OK"。
- **若**没有 → 自带 `hooks/hooks.json` 未自动激活。执行**回退**：把 `dist/codex/hooks/`（`run-hook.cmd session-start`）这条 SessionStart 写进**用户级** `~/.codex/hooks.json`（Codex 已确认支持），重开会话再问。记"需用户级 hooks 回退"。

- [ ] **Step 4: 验标记开关**

```bash
touch ~/.rookie-work-off    # 重开会话再问 → 应"已关闭"，不注入纪律
rm ~/.rookie-work-off       # 重开 → 恢复
```
Expected：标记在时不注入、删后恢复。

- [ ] **Step 5: 记录结论**

把 Step 1/3 的实测结论（安装路 + 自带钩子是否激活 + 是否需用户级回退）写下来，供 Task 3 的 README 用。**无文件改动则不提交。**

---

### Task 3: README Codex 段（按 Task 2 实测的安装路写）

**Files:**
- Modify: `README.md`

- [ ] **Step 1: 在 README 加 Codex 段**

在 README 的 CC `## Install` 段之后，加一节。**按 Task 2 的结论二选一**：

**若 Task 2 = bundled-hook OK：**
```markdown
## Install on Codex

```text
# install the plugin (self-hosted) per Codex's /plugins, pointing at:
#   https://github.com/xuzheng1210/rookie-work  (dist/codex)
```
After install, start a new Codex session — rookie-work activates automatically (it's on by default). Invoke explicitly with `$rookie-work` or via `/skills`.
```

**若 Task 2 = 需用户级 hooks 回退：**
```markdown
## Install on Codex

1. Put the skill where Codex finds it:
   ```bash
   cp -R dist/codex/skills/rookie-work ~/.codex/skills/
   ```
2. Enable always-on injection by adding rookie-work's SessionStart hook to your `~/.codex/hooks.json` (see `dist/codex/hooks/hooks.json` for the exact entry; it runs `dist/codex/hooks/run-hook.cmd session-start`).

Start a new session; invoke explicitly with `$rookie-work` or via `/skills`.
```

（"Turn it off"对 Codex 同样适用：`~/.rookie-work-off` / `<project>/.rookie-work-off`。在该节末尾点一句即可。）

- [ ] **Step 2: 校验 README 含 Codex 段**

Run: `grep -n "Install on Codex" ~/projects/rookie-work/README.md`
Expected：命中一行。

- [ ] **Step 3: 提交**

```bash
git -C ~/projects/rookie-work add README.md
git -C ~/projects/rookie-work commit -m "docs: README 增加 Codex 安装段(按真机验证结论)"
```

---

## 完成判据（Plan 2 Done）
- `build.sh` 生成 `dist/codex/`（`.codex-plugin/plugin.json` 版本与 CC 一致 + 复用 CC 钩子）；`tests/test-build.sh` `PASS=15 FAIL=0`。
- 真机 Codex 上：技能 `$rookie-work` 可用；**新会话自动注入纪律**（自带钩子激活，或用户级 hooks 回退，二者择一已验证）；标记文件可开关。
- README 有 Codex 安装段，写的是**实测确认**的安装路。
- CC 不受影响（共享内容仍逐字一致，防漂移闸绿）。

## 自审（写完即查，对照 spec）
- **spec 覆盖**：§4.1 Codex 包（清单 + skills/<name>/ + 复用钩子）、§5 Codex 自托管安装、§6 标记开关、§7.1 风险（Task 2 验证 + 用户级回退）、§8 测试（防漂移扩 5 条 + 复用 CC 钩子语义）。
- **占位扫描**：无 TBD；Task 3 给"二选一"完整文案（按 Task 2 结论选），非留白；真机命令"按 Codex 现行文档"是因安装 UX 属 spec §7 待实测项，已注明在 Task 2 坐实。
- **类型/命名一致**：`dist/codex/.codex-plugin/plugin.json`、`skills:"./skills/"`、`__VERSION__` 占位、`hooks/{hooks.json,session-start,run-hook.cmd}` 在模板/build.sh/test 三处一致；版本单源自 `.claude-plugin/plugin.json`；`PASS=15` = 10+5。
- **不回归**：仅追加 Codex 块与断言，未动共享内容生成与 CC 文件；防漂移闸保证 dist/ 可重现。
- **顺序依赖**：依赖计划 1；Task 1 自动、Task 2/3 需 Codex 真机（无 Codex 则 plan 写好待装）。

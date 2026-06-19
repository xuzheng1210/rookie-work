# 计划3：rookie-work 技能本体（完整方法）Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 产出 rookie-work 的**完整方法**——`SKILL.md`（三档分流 + Tier 1 轻量流 + Tier 2 完整 8 步 + 交底铁律 + 变更记录 + 开关）+ 两份按需加载的参考文件。这是计划 2 预导语所指引「load the `rookie-work` skill」的落点。

**Architecture:** **单技能插件形态**——`SKILL.md` 放**仓库根**，frontmatter `name: rookie-work`（无 `skills/` 子目录、无 `skills` 清单字段）→ 命令解析为干净的 `/rookie-work`。`description` 驱动「遇到真任务自动加载」。细节机制（变更日志格式、模型/评审策略）放 `references/`，由 `SKILL.md` 按需链接，保持主文件聚焦。

**Tech Stack:** Claude Code 技能系统（SKILL.md frontmatter：`name` / `description`；单技能插件）、Markdown、bash + `awk`/`grep`（结构化测试）。

---

## 前提与依赖

- **依赖计划 1**（可安装骨架）与**计划 2**（预导语注入、关闭标记 `~/.rookie-work-off` 与 `<project>/.rookie-work-off`）。
- **逐字对齐计划 2**：预导语里「load the `rookie-work` skill」→ 本计划 `name: rookie-work`；本计划「开关」节操作的标记文件与计划 2 钩子检查的**同名同路径**。
- **诚实说明（验证边界）**：技能正文是**给 agent 的指令性散文**，可自动化的只有**结构**（frontmatter 合法、`name` 正确、`description` ≤ 1536、关键小节齐全、参考文件在）；**行为**（Tier 0 直接做 / Tier 1 交底 / Tier 2 走全程）只能靠**人工冒烟观察**，Task 4 给清单，不假装能单测。

## 文件结构（本计划产出）

```
SKILL.md                                  # 完整方法（单技能插件，置于仓库根）
references/
  changelog-format.md                     # 变更日志 + Tier2 计划note 的确切格式
  model-and-review-policy.md              # 子代理模型策略 + 可选评审 的呈现方式
tests/
  test-skill.sh                           # 结构化测试（存在/frontmatter/小节/参考件）
```

## 关键事实（来自官方文档核准）

- 单技能插件：`SKILL.md` 在插件根 + 无 `skills/` 子目录 + 无 `skills` 清单字段 → 命令名取 frontmatter `name`（**必须显式写 `name`**，否则回退成会变动的安装目录名）。CC v2.1.142+。
- `description`（+ 可选 `when_to_use`）在技能列表里**截断于 1536 字符**——关键用途写在最前。
- 默认 `disable-model-invocation=false`（可被模型自动加载）、`user-invocable=true`（`/rookie-work` 可手动调用）——本技能两者都要，故 frontmatter 不设这两项即可。

---

### Task 1: 结构化测试 `tests/test-skill.sh`（先写，必失败）

**Files:**
- Create: `tests/test-skill.sh`

- [ ] **Step 1: 写测试脚本**

写入 `~/projects/rookie-work/tests/test-skill.sh`，内容：

```bash
#!/usr/bin/env bash
# Structural tests for the rookie-work SKILL.md (single-skill plugin at repo root).
set -uo pipefail
REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
SKILL="${REPO_ROOT}/SKILL.md"
PASS=0; FAIL=0
ok(){ echo "PASS: $1"; PASS=$((PASS+1)); }
bad(){ echo "FAIL: $1"; FAIL=$((FAIL+1)); }

if [ -f "$SKILL" ]; then ok "SKILL.md exists at plugin root"; else bad "SKILL.md exists at plugin root"; echo "PASS=$PASS FAIL=$FAIL"; exit 1; fi
if [ "$(head -1 "$SKILL")" = "---" ]; then ok "starts with YAML frontmatter"; else bad "starts with YAML frontmatter"; fi

# Extract frontmatter (between the first two '---' lines)
FM="$(awk 'NR==1&&/^---/{f=1;next} /^---/{if(f)exit} f{print}' "$SKILL")"

if printf '%s\n' "$FM" | grep -Eq '^name:[[:space:]]*rookie-work[[:space:]]*$'; then ok "frontmatter name is rookie-work"; else bad "frontmatter name is rookie-work"; fi

DESC="$(printf '%s\n' "$FM" | sed -n 's/^description:[[:space:]]*//p')"
if [ -n "$DESC" ]; then ok "frontmatter has description"; else bad "frontmatter has description"; fi
LEN=${#DESC}
if [ "$LEN" -gt 0 ] && [ "$LEN" -le 1536 ]; then ok "description length ${LEN} within 1536"; else bad "description length ${LEN} within 1536"; fi

# Required body sections (dash-free substrings, to avoid em-dash matching issues)
for m in "Which tier is this task" "the light flow" "the full method" "Disclose before you modify" "Record every change" "Turning rookie-work off and on"; do
  if grep -qF "$m" "$SKILL"; then ok "section present: $m"; else bad "section present: $m"; fi
done

# Reference files exist
for ref in "references/changelog-format.md" "references/model-and-review-policy.md"; do
  if [ -f "${REPO_ROOT}/${ref}" ]; then ok "ref exists: $ref"; else bad "ref exists: $ref"; fi
done

echo "----"; echo "PASS=$PASS FAIL=$FAIL"
[ "$FAIL" -eq 0 ]
```

- [ ] **Step 2: 赋可执行 + 运行（应失败）**

Run:
```bash
chmod +x ~/projects/rookie-work/tests/test-skill.sh
bash ~/projects/rookie-work/tests/test-skill.sh
```
Expected: **FAIL** —— `SKILL.md` 不存在，首断言即失败、退出码 1。

- [ ] **Step 3: 提交**

```bash
git -C ~/projects/rookie-work add tests/test-skill.sh
git -C ~/projects/rookie-work commit -m "test: 加入 SKILL.md 结构化测试(当前必失败)"
```

---

### Task 2: 参考文件 `references/`

**Files:**
- Create: `references/changelog-format.md`
- Create: `references/model-and-review-policy.md`

- [ ] **Step 1: 写 `references/changelog-format.md`**

写入 `~/projects/rookie-work/references/changelog-format.md`，内容：

````markdown
# Change log & plan-note format

Where: `docs/rookie-work/` inside the **user's** project (create it if missing).

## CHANGELOG.md — one line per change (Tier 1 and Tier 2)

Append to `docs/rookie-work/CHANGELOG.md`. If the file is new, start it with this header:

```
# Change log (rookie-work)

| When | Tier | What changed | Why | Size / scope |
|------|------|--------------|-----|--------------|
```

Then one row per change, newest at the bottom. Use today's date. Example:

```
| 2026-06-19 | 1 | Renamed the login button to "Sign in" | User wanted clearer wording | 1 file, 1 line |
| 2026-06-19 | 2 | Added CSV export to the report page | Requested feature | 4 files; see note below |
```

Keep "What changed" and "Why" in plain language the user can read.

## Tier 2 plan note

For a Tier 2 change, also save a short note at
`docs/rookie-work/notes/<date>-<short-title>.md`, in plain language:

- What we built and why
- The approach we agreed on (and the options we considered)
- How it was verified

Link it from the change-log row (e.g. `see notes/2026-06-19-csv-export.md`).
````

- [ ] **Step 2: 写 `references/model-and-review-policy.md`**

写入 `~/projects/rookie-work/references/model-and-review-policy.md`，内容：

```markdown
# Sub-agent model policy & optional review

## Picking a model for sub-agents

When you're about to use helper sub-agents, don't silently choose the model — it
affects cost and quality. Offer the user a simple policy and let them choose:

- **Policy A — set a default.** The user picks one model; you use it for all
  sub-agents from now on, unless they say otherwise for a specific job.
- **Policy B — ask each time.** You ask which model to use every time you spin
  up a sub-agent.

Explain the trade-off in plain words: stronger models cost more but do better on
hard work; for simple sub-tasks a lighter model is cheaper and fine. **Do not
assume a default of your own.** Tell the user they can switch policy any time,
and remind them this choice exists the first time it comes up.

## Offering an extra review

For important work, you may offer an extra review pass (a second look, possibly
by a different model). Don't run it silently — it costs time and money. Ask
first, and explain plainly:

- **What it buys:** catches mistakes a single pass can miss; a second perspective.
- **What it costs:** more time and tokens.

Then let the user decide — and let them say *how* they want it ("just check
correctness," "skip it," "review with a different model"). Their preference wins.
```

- [ ] **Step 3: 验证两文件存在且非空**

Run: `wc -l ~/projects/rookie-work/references/changelog-format.md ~/projects/rookie-work/references/model-and-review-policy.md`
Expected: 两文件均列出、行数 > 0。

- [ ] **Step 4: 提交**

```bash
git -C ~/projects/rookie-work add references/
git -C ~/projects/rookie-work commit -m "feat: 加入按需参考文件(变更日志格式 + 模型/评审策略)"
```

---

### Task 3: 技能本体 `SKILL.md`

**Files:**
- Create: `SKILL.md`（仓库根）

- [ ] **Step 1: 写 `SKILL.md`**

写入 `~/projects/rookie-work/SKILL.md`，内容（注意 `description` 为**单行**）：

````markdown
---
name: rookie-work
description: The full beginner-safe working method for any real task — anything that creates, edits, deletes, installs, or commits (a feature, fix, refactor, or config change). It sizes the task into three tiers, makes the agent explain in plain language what it will do and how (and get the user's OK) before changing anything, turns every real decision into a plain-language choice with a recommendation, designs and plans before coding, and verifies with evidence. Also use when the user wants to turn rookie-work on or off, or change how models are picked for sub-tasks.
---

# rookie-work — the full method

You are helping someone who may be new to AI agents. Do good work **and** keep them in control by being transparent at every step. Speak plainly, in the user's own language, and never assume they know jargon.

> **The promise:** never change anything of theirs before telling them — in plain language they understand — what you are about to do and how, and getting their OK.

## Step 0 — Which tier is this task?

Decide how much process this task needs, and **for anything that changes things, say out loud which tier you picked and why** (one line). The user can always overrule you ("just do it" to go lighter; "do this properly" to go fuller).

- **Tier 0 — just do it.** Read-only: a lookup, locating a file, explaining code, answering a question. Nothing changes. → No process; just do it and answer.
- **Tier 1 — light.** A small, low-risk change with one obvious way to do it (a wording tweak, one config line, an obvious typo). → Use the **light flow** below.
- **Tier 2 — full.** Anything with real choices, a wide or unclear blast radius, or that is hard to undo (a feature, a refactor, deleting things, a bulk change, anything you publish). → Use the **full method** below.

**The hard line:** the moment a task involves *writing / changing / deleting / installing / publishing / committing*, it is **at least Tier 1** — never just done silently. Do not talk yourself into "this is too simple" to skip telling the user first. If unsure between two tiers, pick the higher one or ask.

## Tier 1 — the light flow

1. **Say what you'll do and how**, in plain language: "I'm going to X, by doing Y." Mention anything they should know (a side effect, an assumption).
2. **Check the direction** — is this what they want? Anything to add?
3. **Do it**, then **report** what you did.
4. **Stop at the edge.** If it turns out bigger than one obvious small change, stop and switch to Tier 2 instead of pressing on.
5. **Record it** (see "Record every change").

## Tier 2 — the full method (8 steps)

**1. Understand the project, then brief it back.** Read what you need (files, docs, recent history, and `docs/rookie-work/CHANGELOG.md` if it exists). Then **tell the user, in a few plain sentences, what this project is and the parts that matter for this task — and ask them to confirm you understood it right.** Don't start designing until they say yes.

**2. Restate the task and surface the decisions.** Say back what you think they want. Find the points where there's a real choice — and **don't decide silently.** For each, present the options in plain language with pros and cons and **your recommendation and why**, and let them pick.

**3. Design before you write code.** Offer 2–3 ways to do it with trade-offs and a recommendation. Agree on one **before** touching any code. No code until the design is settled.

**4. If you'll use sub-agents, settle the model first.** Helper agents cost money and vary in quality — don't silently pick. Offer a simple policy (set a default model, or be asked each time). See `references/model-and-review-policy.md`.

**5. Turn the design into a small plan, and show it.** Break the agreed design into small, plain-language steps. Let the user look it over before you build.

**6. Build it — and stop before going off-plan.** Follow the plan. If you find you need something **beyond what was agreed** (extra changes, a different approach, a rename, a "quick improvement"), **stop and ask first.** Doing exactly what was asked — no silent extras — is the rule.

**7. Offer a review (optional).** For important work, ask whether they'd like an extra review pass. Explain plainly what it buys and costs, and let them decide. See `references/model-and-review-policy.md`.

**8. Verify, then call it done.** "Done" means you **showed it working** — ran it, tested it, pointed at the evidence — not just claimed it. Write down anything left over or deferred so it isn't lost.

## Disclose before you modify (the iron rule)

This runs through both Tier 1 and Tier 2: **before any real change, the user hears — in plain language — what you'll do and how, and confirms.** The only exception is Tier 0 (pure read-only). If you catch yourself about to edit, create, or delete without having said so, stop and say so first.

## Record every change

So the user (and future agents) can trace what happened:

- **Tier 0:** nothing to record.
- **Tier 1 and Tier 2:** add one line to `docs/rookie-work/CHANGELOG.md` — what changed, why, when, how big, which tier.
- **Tier 2 also:** save a short plain-language plan note and link it from the change-log line.
- The first time you create this log, tell the user you're keeping it and where.

Exact format: `references/changelog-format.md`. Create `docs/rookie-work/` if missing.

## Turning rookie-work off and on

- **Just this session:** if the user says "turn off rookie-work" or "raw mode," stand down for the rest of the session — work normally without these steps. If they say "turn it back on," resume.
- **Persistently (across sessions):** rookie-work is controlled by a marker file. Off everywhere: create `~/.rookie-work-off`. Off for this project only: create `<project>/.rookie-work-off`. Back on: delete that file. When the user asks for a persistent change, do it for them — it's a Tier 1 change, so tell them what you're doing first.

## Always speak the user's language

Whatever language the user writes in, answer in it. These instructions are in English for portability; your replies are not.
````

- [ ] **Step 2: 运行结构化测试（应全过）**

Run: `bash ~/projects/rookie-work/tests/test-skill.sh`
Expected: **PASS** —— 末行 `PASS=13 FAIL=0`（1 存在 + 1 frontmatter 起始 + 1 name + 1 desc 有 + 1 desc 长度 + 6 小节 + 2 参考件 = 13），退出码 0。

- [ ] **Step 3: 提交**

```bash
git -C ~/projects/rookie-work add SKILL.md
git -C ~/projects/rookie-work commit -m "feat: 加入 rookie-work 技能本体 SKILL.md(完整方法,测试全过)"
```

---

### Task 4: 集成校验 + 行为冒烟清单

**Files:** 无（校验 + 人工冒烟）

- [ ] **Step 1: 官方校验器复校整插件**

Run: `cd ~/projects/rookie-work && claude plugin validate . --strict`
Expected: 通过、无 error（此时插件含技能 + 钩子 + 市场，齐全）。无该命令则跳过。

- [ ] **Step 2: 确认单技能命令名解析为 `/rookie-work`**

说明：这一步需真安装后在 `/` 菜单观察（留到计划 4 真机安装时一并做，或本地已装则现做）。
- 期望：`/` 菜单出现 **`/rookie-work`**（单技能插件，命令名取自 frontmatter `name`）。
- **回退**：若它解析成 `/rookie-work:rookie-work` 或不出现，改用子目录形态——把 `SKILL.md` 移到 `skills/rookie-work/SKILL.md`，命令变 `/rookie-work:rookie-work`（功能不变；默认常开走钩子、不依赖命令名）。把该调整记入计划 4 的发布前清单。

- [ ] **Step 3: 行为冒烟清单（人工，在装了插件的真会话里观察）**

逐条核对 agent 行为是否符合预期；不符则回到 `SKILL.md` / `SESSION-PREAMBLE.md` 调措辞：

| 场景输入 | 期望行为 |
|---|---|
| 「我的 IP 是多少」「找到 X 文件夹」 | **Tier 0**：直接做并答，无仪式 |
| 「把 Z 文件里的 X 改成 Y」（一行小改） | **Tier 1**：先用大白话说「要做什么+怎么做」→ 确认方向 → 改 → 报告 → 追加一行 CHANGELOG |
| 「给报告页加个导出功能」 | **Tier 2**：吃透项目→复述并确认→摆决策选择题→给方案→出计划，**达成一致前不写码** |
| 任意改动前 | 从不**先改后说**；必先交底 |
| 建 `~/.rookie-work-off` 后开新会话 | 预导语不再注入（计划 2 测试已自动覆盖此项） |
| 会话中说「关掉 rookie-work」 | agent 当场停用本套流程，按普通模式干活 |
| 说「以后子代理都用最强模型」 | agent 据「模型策略」记住默认、不再每次问 |

- [ ] **Step 4: 提交（如 Step 2 触发回退或有措辞修订才有改动）**

```bash
# 仅当本任务产生文件改动时
git -C ~/projects/rookie-work add -A
git -C ~/projects/rookie-work commit -m "chore: 计划3 集成校验后的调整"
```

---

## 完成判据（Plan 3 Done）

- 仓库根存在 `SKILL.md`（frontmatter `name: rookie-work`、`description` ≤ 1536、六个关键小节齐全）。
- 存在 `references/changelog-format.md`、`references/model-and-review-policy.md`。
- `tests/test-skill.sh` 全过（`PASS=13 FAIL=0`）。
- `claude plugin validate . --strict` 通过（若可用）。
- 行为冒烟清单逐条符合（人工确认）；命令名解析为 `/rookie-work`（或按回退记入计划 4）。
- 全部改动已分提交（main 分支）。
- **效果：计划 2 预导语指引的「完整方法」已就位；真任务触发时 agent 按三档 + 8 步 + 交底铁律工作，并把改动记入用户项目的变更日志。**

## 自审（写完即查，对照 spec）

- **spec 覆盖**：§2 承诺/三原则、§6 三档+硬线+防自我开脱、§7 完整 8 步（含 step1 简报确认、step4 模型、step7 评审）、§8 Tier1 轻量流、§9 交底铁律、§10 变更记录（Tier0 不记/Tier1·2 记/Tier2 加 note/闭环读日志）、§11 模型策略、§12 评审策略、§5「口头当场关」与持久标记的 agent 侧操作、§13 跟随用户语言——逐项有落点。
- **占位扫描**：无 TBD/TODO；`<project>`/`<date>`/`<short-title>` 是指令模板里的具名占位符（告诉 agent 填什么），非计划留白；Step 2 命令名解析 + 回退是明确的真机校验步骤。
- **类型/命名一致**：`name: rookie-work` ↔ 计划 2 预导语「load the `rookie-work` skill」与命令 `/rookie-work`；关闭标记 `~/.rookie-work-off`、`<project>/.rookie-work-off` 与计划 2 钩子检查路径**逐字一致**；参考件路径 `references/changelog-format.md`、`references/model-and-review-policy.md` 在 SKILL.md、测试两处一致；变更日志路径 `docs/rookie-work/CHANGELOG.md` 在 SKILL.md 与参考件一致；测试断言的六个小节子串与 SKILL.md 标题逐字匹配。
- **验证边界诚实**：结构自动化、行为人工冒烟，已在前提与 Task 4 注明，不假装行为可单测。
- **顺序依赖**：依赖计划 1（骨架）、计划 2（注入入口 + 标记约定）；为计划 4（发布 + 端到端冒烟）留下命令名校验与回退入口。

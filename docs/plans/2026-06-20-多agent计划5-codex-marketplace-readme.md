# 多agent·计划5：Codex marketplace 打包 + 双 README Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 让 Codex 用户能 `codex plugin marketplace add xuzheng1210/rookie-work` 从 GitHub 一条命令装上 rookie-work 技能（再加用户级钩子开常驻），并据真机验证结论补齐 README 的 Codex / Hermes 安装段。

**Architecture:** 仓库根加一个**静态** `.agents/plugins/marketplace.json`（Codex marketplace 清单），插件项用 `git-subdir` source 指向仓库内已生成的 `dist/codex`（不重复内容）。`codex plugin marketplace add owner/repo` 会 clone 仓库读该清单。常开纪律仍靠用户级 `~/.codex/hooks.json`（自带钩子不自动激活，已实测 §7.1）。Hermes 走 WSL 安装。流程：先在本仓库加清单+测试并推送 → 真机验证 GitHub 安装与交互注入 → 据实写双 README。

**Tech Stack:** 静态 JSON、`python3`（测试校验）、git；Task 2 需 **Codex 真机（Windows）**。

---

## 前提与约束
- 依赖计划 1–3（`dist/codex` 已生成、CC 未破坏、`.gitattributes` 已加 `4e61c68`）。
- §7.1 实测：Codex 自带 `hooks/hooks.json` **不**自动激活 → 用户级 hooks 必须。
- **风险（spec §7.4 邻近）**：`git-subdir` 同仓库 source 的 `path` 解析语义未在 GitHub 托管下实测 → Task 2 验证；退路 = `local` 相对 source + build 复制 `dist/codex` 到 `.agents/plugins/plugins/rookie-work/`（Task 2 Step 2 给完整改法）。
- **版本不重复**：marketplace.json 不带版本字段（版本在 `dist/codex/.codex-plugin/plugin.json`，由 `ref:main` 选取）→ 静态清单，无需 build 注入。
- 线性、相对路径、普通 commit；中文。

## 文件结构（本计划产出）
```
.agents/plugins/marketplace.json   # 新增(静态)：Codex marketplace 清单，git-subdir → ./dist/codex
tests/test-build.sh                # 改：+marketplace 清单校验 + .gitattributes LF 守护断言
README.md                          # 改：+「Install on Codex」段、+「Install on Hermes」段
build/build.sh                     # 仅退路时改(git-subdir 不通才需复制 dist→.agents)
```

---

### Task 1: 加 Codex marketplace 清单 + 测试（本仓库，自动）

**Files:**
- Create: `.agents/plugins/marketplace.json`
- Modify: `tests/test-build.sh`

- [ ] **Step 1: 先加断言（先失败）**

在 `tests/test-build.sh` 的 Codex-specific 断言块之后、determinism 段之前，插入：

```bash
# --- Codex marketplace manifest (static, repo-root; for `codex plugin marketplace add owner/repo`) ---
mkt="${ROOT}/.agents/plugins/marketplace.json"
if [ -f "$mkt" ]; then ok "codex: marketplace.json present"; else bad "codex: marketplace.json present"; fi
if python3 -c "import json,sys;m=json.load(open('${mkt}'));p=m['plugins'][0];s=p['source'];sys.exit(0 if m.get('name')=='rookie-work-marketplace' and p.get('name')=='rookie-work' and s.get('source')=='git-subdir' and s.get('path')=='./dist/codex' else 1)" 2>/dev/null; then ok "codex: marketplace.json valid (name+plugin+git-subdir source)"; else bad "codex: marketplace.json valid (name+plugin+git-subdir source)"; fi

# --- .gitattributes LF guard (a Windows clone must not CRLF-corrupt the hook scripts) ---
if [ -f "${ROOT}/.gitattributes" ] && grep -Eq 'eol=lf' "${ROOT}/.gitattributes"; then ok ".gitattributes enforces eol=lf"; else bad ".gitattributes enforces eol=lf"; fi
```

- [ ] **Step 2: 运行，确认新断言（部分）失败**

Run: `bash ~/projects/rookie-work/tests/test-build.sh`
Expected: **FAIL** —— `.agents/plugins/marketplace.json` 尚不存在 → 2 条 marketplace 断言失败；`.gitattributes` 守护**通过**（已存在）。末行 `PASS=20 FAIL=2`。

- [ ] **Step 3: 写 marketplace 清单**

写入 `~/projects/rookie-work/.agents/plugins/marketplace.json`：

```json
{
  "name": "rookie-work-marketplace",
  "interface": { "displayName": "Rookie Work" },
  "plugins": [
    {
      "name": "rookie-work",
      "source": {
        "source": "git-subdir",
        "url": "https://github.com/xuzheng1210/rookie-work.git",
        "path": "./dist/codex",
        "ref": "main"
      },
      "policy": { "installation": "AVAILABLE", "authentication": "ON_INSTALL" },
      "category": "Safety"
    }
  ]
}
```

- [ ] **Step 4: 跑测试（应全过）**

Run: `bash ~/projects/rookie-work/tests/test-build.sh`
Expected: **PASS** —— 末行 `PASS=22 FAIL=0`（既有 19 + 本计划 3）。

- [ ] **Step 5: 提交**

```bash
git -C ~/projects/rookie-work add .agents/plugins/marketplace.json tests/test-build.sh
git -C ~/projects/rookie-work commit -m "feat: 加 Codex marketplace 清单(git-subdir→dist/codex) + 测试(.gitattributes LF 守护)"
```

> **控制者**：Task 1 过审 + 提交后**推送**（`git push`），使 GitHub 有清单，Task 2 方能从 GitHub 验证安装。

---

### Task 2: 真机验证 GitHub marketplace 安装 + Codex 交互注入（需 Codex 真机 Windows）

**Files:** 无（真机安装 + 观察）；仅"退路"触发时才回头改清单/build。

> 目标：确认 ①`codex plugin marketplace add xuzheng1210/rookie-work` 从 GitHub clone 读清单、`codex plugin add` 装上技能 ②用户级 hooks 在真**交互**会话注入纪律（§7.1 留的活检）③记录确切安装命令 + 插件缓存路径，供 Task 3 README。**装不通也不要卡死——把现象记下来交回。**

- [ ] **Step 1: 从 GitHub 装 marketplace + 插件**

```
codex plugin marketplace add xuzheng1210/rookie-work
codex plugin add rookie-work@rookie-work-marketplace
codex plugin list
```
Expected：`rookie-work@rookie-work-marketplace (installed, enabled)`；`/skills` 或 `$rookie-work` 可见。
记录：是否成功、`codex plugin list` 输出、插件落地的缓存路径（形如 `~/.codex/plugins/cache/rookie-work-marketplace/rookie-work/<ver>/`）。
若 `authentication: ON_INSTALL` 触发了多余的认证提示 → 把清单该字段改 `"NONE"`、重推、重试，并记录。

- [ ] **Step 2:（退路）git-subdir 不通时**

若 Step 1 报 source/path 解析错（git-subdir 不被接受或 `./dist/codex` 解析不到）：改走 `local` 相对式并让 build 复制内容——
1. 清单 `source` 改 `{"source":"local","path":"./plugins/rookie-work"}`；
2. `build/build.sh` 末尾（写 `dist/README.md` 之后）加：
   ```bash
   # Codex marketplace 同仓库 local 插件：把已生成的 codex 包复制到 marketplace 期望的相对位置
   mkdir -p "${ROOT}/.agents/plugins/plugins"
   rm -rf "${ROOT}/.agents/plugins/plugins/rookie-work"
   cp -R "${DIST}/codex" "${ROOT}/.agents/plugins/plugins/rookie-work"
   ```
3. 把 Step 1 测试里的 `s.get('source')=='git-subdir' and s.get('path')=='./dist/codex'` 改为 `s.get('source')=='local' and s.get('path')=='./plugins/rookie-work'`；
4. 重跑 build + test（须仍 `PASS=22`，确定性闸覆盖新复制目录）、提交、重推、再验 Step 1。
记录最终生效的 source 形态。

- [ ] **Step 3: 验用户级 hooks 在交互会话注入（§7.1 活检）**

按 Step 1 记下的缓存路径 `<ver>` 配 `~/.codex/hooks.json`（Windows 形）：
```json
{ "hooks": { "SessionStart": [ { "matcher": "startup|resume|clear|compact", "hooks": [
  { "type": "command", "command": "cmd.exe /c \"set CLAUDE_PLUGIN_ROOT=%USERPROFILE%\\.codex\\plugins\\cache\\rookie-work-marketplace\\rookie-work\\<ver> && %USERPROFILE%\\.codex\\plugins\\cache\\rookie-work-marketplace\\rookie-work\\<ver>\\hooks\\run-hook.cmd session-start\"", "async": false } ] } ] } }
```
开一个**交互**会话（非 `exec`），问"在我提任何要求前，先说你处于什么护栏、叫什么、规则是什么"。
Expected：复述 rookie-work 三原则 + 三档（首次有钩子信任提示 → approve 一次）。
记录：是否注入、信任提示原文。

- [ ] **Step 4: 验开关**

建 `%USERPROFILE%\.rookie-work-off` → 重开会话应"已关闭"不注入；`del` 后恢复。

- [ ] **Step 5: 记录结论（供 Task 3）**

确切安装命令 + 缓存路径形态（含 `<ver>` 例子）+ source 最终形态（git-subdir / local）+ 交互注入 OK + 信任提示原文。**无文件改动则不提交**（除非走了 Step 2 退路）。

---

### Task 3: README Codex 段 + Hermes 段（据 Task 2 实测）

**Files:**
- Modify: `README.md`

- [ ] **Step 1: 在 CC `## Install` 段之后，加「Install on Codex」**

`<version>` 用 Task 2 实测的真实版本写入示例（README 同时注明何处取、何时更新）：

````markdown
## Install on Codex

Two parts — the skill (one command) and the always-on discipline (Codex does not auto-run a plugin's bundled hook, so you add one small hook entry).

**1. Install the skill**

```text
codex plugin marketplace add xuzheng1210/rookie-work
codex plugin add rookie-work@rookie-work-marketplace
```

Now `rookie-work` is available (`$rookie-work` or `/skills`).

**2. Turn on always-on discipline** (recommended)

Add a SessionStart entry to your user-level `~/.codex/hooks.json`, pointing at the installed plugin (under `~/.codex/plugins/cache/rookie-work-marketplace/rookie-work/<version>/` — find `<version>` with `codex plugin list`):

- **Windows:**
  ```json
  { "hooks": { "SessionStart": [ { "matcher": "startup|resume|clear|compact", "hooks": [
    { "type": "command", "command": "cmd.exe /c \"set CLAUDE_PLUGIN_ROOT=%USERPROFILE%\\.codex\\plugins\\cache\\rookie-work-marketplace\\rookie-work\\<version> && %USERPROFILE%\\.codex\\plugins\\cache\\rookie-work-marketplace\\rookie-work\\<version>\\hooks\\run-hook.cmd session-start\"" } ] } ] } }
  ```
- **macOS / Linux:** same idea — one SessionStart entry that sets `CLAUDE_PLUGIN_ROOT` to that plugin directory and runs `hooks/session-start` from it.

Codex asks you to trust the hook on first use — approve once. Update `<version>` if you upgrade rookie-work. (Skill-only is fine too: skip step 2 and just call `$rookie-work` when you want it.)

**Turn it off:** create `~/.rookie-work-off` (everywhere) or `<project>/.rookie-work-off` (one project); delete to turn back on.
````

- [ ] **Step 2: 在 Codex 段之后，加「Install on Hermes」**

````markdown
## Install on Hermes

Hermes runs rookie-work as a `pre_llm_call` shell hook + skill. The hook is a Unix bash script (needs `python3`), so on **Windows run Hermes under WSL** — native-Windows Hermes is on the backlog.

From a clone of this repo, in your Hermes environment (macOS / Linux / WSL):

```bash
mkdir -p ~/.hermes/skills ~/.hermes/agent-hooks
cp -R dist/hermes/skills/rookie-work ~/.hermes/skills/
cp dist/hermes/agent-hooks/rookie-work-inject.sh dist/hermes/agent-hooks/SESSION-PREAMBLE.md ~/.hermes/agent-hooks/
chmod +x ~/.hermes/agent-hooks/rookie-work-inject.sh
```

Then merge the `hooks:` block from `dist/hermes/config-snippet.yaml` into `~/.hermes/config.yaml`. Start Hermes — `/rookie-work` is available, and the discipline loads on the first turn of each session. Hermes asks `Allow this hook to run? [y/N]` the first time (approve once, or set `hooks_auto_accept: true` in `~/.hermes/config.yaml`, or pass `--accept-hooks`).

**Turn it off:** create `~/.rookie-work-off` (everywhere) or `<project>/.rookie-work-off` (one project); delete to turn back on. (Or disable the skill natively with `skills.disabled: [rookie-work]` in `~/.hermes/config.yaml`.)
````

- [ ] **Step 3: 校验 README 含两段**

Run: `grep -nE "Install on Codex|Install on Hermes" ~/projects/rookie-work/README.md`
Expected：命中两行。

- [ ] **Step 4: 提交**

```bash
git -C ~/projects/rookie-work add README.md
git -C ~/projects/rookie-work commit -m "docs: README 增加 Codex(marketplace+用户级hooks) 与 Hermes(WSL) 安装段(按真机验证)"
```

---

## 完成判据（Plan 5 Done）
- `.agents/plugins/marketplace.json` 在仓库根，`git-subdir`（或退路 `local`）指向 `dist/codex`；`tests/test-build.sh` `PASS=22 FAIL=0`。
- 真机：`codex plugin marketplace add xuzheng1210/rookie-work` + `codex plugin add` 从 GitHub 装上技能；用户级 hooks 在**交互**会话注入纪律；标记开关可用。
- README 有 Codex（marketplace + 用户级 hooks + 信任提示 + 开关）与 Hermes（WSL + `[y/N]` 同意 + 开关 + 原生 Windows=backlog）段，写**实测确认**的命令。
- CC 不受影响；`.gitattributes` LF 守护断言 green。

## 自审（写完即查，对照 spec）
- **spec 覆盖**：§4.1 Codex marketplace 清单（git-subdir→dist/codex）、§5 Codex/Hermes 实测安装路、§7.1 用户级 hooks 交互活检、§7.5 `.gitattributes` 守护、§9 原生 Windows Hermes=backlog + 钩子路径健壮性（README 给 `<version>` 更新指引 + skill-only 备选）。
- **占位扫描**：无 TBD；`<version>` 是用户按 `codex plugin list` 实填的真实参数（README 注明何处取、何时更新），非计划留白；Task 2 退路给完整 source/build 改法，非"看情况"。
- **类型/命名一致**：marketplace `name`=`rookie-work-marketplace`、plugin `name`=`rookie-work`、source `git-subdir`/`path:./dist/codex` 在清单/测试/README 三处一致；`PASS=22`=19+3。
- **不回归**：仅加 `.agents/` 静态清单 + 测试断言 + README；不动 `dist/` 生成与 CC；退路才动 `build.sh`（确定性闸覆盖）。
- **顺序依赖**：Task 1 自动 → 控制者推送 → Task 2 真机 → Task 3 据实写。

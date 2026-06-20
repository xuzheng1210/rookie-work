# rookie-work

[English](./README.md) | **简体中文**

> 一套面向新手的「工作流安全护栏」,适配 AI 编程助手——Claude Code、Codex、Hermes。
> 在动你任何东西之前,助手都会先用**你听得懂的大白话**告诉你它要做什么、怎么做,并征得你同意。

## 为什么你需要它

AI 编程助手很强——可一旦你是新手,这恰恰是问题所在:它跑得飞快、替你做了你根本没看见的决定,而且哪怕错了也说得理直气壮。如果你读不太懂代码,这些你一个都接不住。**rookie-work 把控制权交还给你**:它让助手像一位**谨慎的资深工程师**那样工作——所有事都用大白话讲清楚,绝不背着你动手。

它能解决的日常问题:

| 没有 rookie-work | 有了 rookie-work |
| --- | --- |
| 助手**默默选定**了某个方案、库或设计——等做出来你才发现跑偏了。 | 每个真实选择都用大白话摊开,带优缺点和推荐,**由你拍板**——绝不悄悄替你决定。 |
| 它**擅自改动或删除你没让它碰的东西**(「我顺手优化了下 X」),结果搞坏了别处。 | 任何改动前,它先告诉你要做什么、怎么做,等你点头;一旦发现要做的事超出原计划,它会停下来问你。 |
| **小事被过度复杂化,危险的事却被仓促带过。** | 三档分级把分寸调到刚好——查一下的事直接做,小改动快速确认,真功能走完整流程。 |
| 它宣布**「搞定!」**,其实根本没运行、没测试过。 | 「完成」意味着它**让你看到它确实跑通了**——运行了、测试了、把证据指给你看。 |
| 你有个想法,却**连话都不知道怎么起头**——你没法把它说成一份清晰的需求。 | 它会主动提议先**和你一起**把计划理出来,用大白话、一次一个决定,让你在写任何代码之前就看懂、并真正拥有你在造的东西。 |

## 它是怎么做到的

rookie-work 会把每个任务归入三档之一,让小事保持轻快、险事得到照顾:

- **第 0 档——直接做。** 只读类:查一下、找个文件、解释代码。什么都不改,所以零折腾。
- **第 1 档——轻量。** 一个低风险、且只有一种显然做法的小改动。助手说明它要做什么,你确认,它做,然后回报。
- **第 2 档——完整。** 有真实选择、影响很大、或难以撤销。助手走完整流程:摸清项目 → 和你一起厘清边界 → 设计 → 计划 → 实现 → 检查它确实能跑。

它在你安装的那一刻起就**自动开启**——纪律在每次会话开始时加载——而且它**始终用你的语言**回复。

## 安装

> **最简单的方法——直接交给你的 AI。** 把本仓库的网址 `https://github.com/xuzheng1210/rookie-work` 复制给你正在用的 Claude Code、Codex 或 Hermes,让它**帮你把这个 plugin 装上、并一步一步带你配置好**。想自己动手,就照下面的步骤来。

rookie-work 支持三个助手。**不确定自己用的是哪个?选 Claude Code——它最简单,而且不用打开任何技术性的东西。** 末尾的「关闭开关」三家通用。

### Claude Code —— 最简单,不用终端

这些命令直接敲在 **Claude Code 自己里面**——就是你和它聊天的那个输入框。Windows 和 Mac 完全一样。

1. 打开 Claude Code。
2. 输入这一行,按 **回车(Enter)**:
   ```text
   /plugin marketplace add https://github.com/xuzheng1210/rookie-work
   ```
3. 再输入这一行,按 **回车**:
   ```text
   /plugin install rookie-work@rookie-work-marketplace
   ```

就这样——rookie-work 已开启,之后每次新会话都自动生效。日后想拿最新版,输入 `/plugin marketplace update` 即可。

### Codex

用 Codex 要在**终端**里敲命令——终端就是一个你输入指令的窗口。先打开它:

- **Windows —— 打开 PowerShell:** 按 **Windows 键**,输入 `powershell`,按 **回车**。会弹出一个蓝色窗口。(老的 `cmd` 也行——命令一样。)
- **Mac —— 打开 Terminal(终端):** 按 **⌘ Command + 空格键**,输入 `Terminal`(或「终端」),按 **回车**。会弹出一个小窗口。

**第 1 步 —— 安装 rookie-work。** 在那个窗口里,输入这两行,每行敲完按 **回车**(Windows 和 Mac 相同):

```text
codex plugin marketplace add xuzheng1210/rookie-work
codex plugin add rookie-work@rookie-work-marketplace
```

现在随时输入 `$rookie-work` 就能用 rookie-work 了。**如果这样就够了,你已经装好了。** 想让它每次会话自动开启,就做第 2 步。

**第 2 步 —— 让它自动开启(可选,推荐)。** 这一步是往一个小小的设置文件里加几行。

先查你的版本号——输入下面这行,记下它打印出的号码(例如 `1.1.0`):

```text
codex plugin list
```

然后新建或打开设置文件,把对应你系统的那段粘进去,**并把里面每个 `<version>` 都换成你的号码**:

- **Windows ——** 文件位置是 `C:\Users\你的用户名\.codex\hooks.json`。打开**记事本**,把下面这段粘进去,然后「另存为」到那个 `.codex` 文件夹、命名为 `hooks.json`(另存对话框里把「保存类型」选成**所有文件**,以免存成 `hooks.json.txt`):

  ```json
  { "hooks": { "SessionStart": [ { "matcher": "startup|resume|clear|compact", "hooks": [
    { "type": "command", "command": "cmd.exe /c \"set CLAUDE_PLUGIN_ROOT=%USERPROFILE%\\.codex\\plugins\\cache\\rookie-work-marketplace\\rookie-work\\<version> && %USERPROFILE%\\.codex\\plugins\\cache\\rookie-work-marketplace\\rookie-work\\<version>\\hooks\\run-hook.cmd session-start\"", "async": false } ] } ] } }
  ```

- **Mac ——** 文件位置是 `~/.codex/hooks.json`(`.codex` 文件夹是隐藏的;在**访达 Finder** 里按 **⌘ + Shift + G**,输入 `~/.codex`,回车即可跳过去)。用**文本编辑(TextEdit)**打开 `hooks.json`,粘贴:

  ```json
  { "hooks": { "SessionStart": [ { "matcher": "startup|resume|clear|compact", "hooks": [
    { "type": "command", "command": "CLAUDE_PLUGIN_ROOT=\"$HOME/.codex/plugins/cache/rookie-work-marketplace/rookie-work/<version>\" \"$HOME/.codex/plugins/cache/rookie-work-marketplace/rookie-work/<version>/hooks/session-start\"", "async": false } ] } ] } }
  ```

> *注:上面的 Windows 那段已在真机验证;这段 Mac 用的是同一个钩子,理应以相同方式工作。若加载不出来,核对一下路径和你的 `<version>`——并欢迎提个 issue,好让我们确认它。*

首次使用时 Codex 会让你批准这个钩子——点同意即可。(以后每次升级 rookie-work,把 `<version>` 改成新号码。)

### Hermes

Hermes 是三者里最需要动手的——只有你已经在用 Hermes 才选它。先打开正确的窗口:

- **Mac**:打开 **Terminal(终端)**(⌘ Command + 空格键,输入 `Terminal`,回车)。
- **Windows**:Hermes 在 **WSL**(一个住在 Windows 里面的 Linux 系统)里运行。如果你从没装过 WSL,Hermes 多半不适合你起步——改用 Claude Code 吧。如果你已经有 WSL,打开它的窗口。

在那个窗口里,输入下面这些行(每段敲完按 **回车**)。它们会下载 rookie-work,并把文件放到 Hermes 会去找的地方:

```text
git clone https://github.com/xuzheng1210/rookie-work
cd rookie-work

mkdir -p ~/.hermes/skills ~/.hermes/agent-hooks
cp -R dist/hermes/skills/rookie-work ~/.hermes/skills/
cp dist/hermes/agent-hooks/rookie-work-inject.sh dist/hermes/agent-hooks/SESSION-PREAMBLE.md ~/.hermes/agent-hooks/
chmod +x ~/.hermes/agent-hooks/rookie-work-inject.sh
```

最后,用文本编辑器打开 `~/.hermes/config.yaml`,加入这几行(如果它已经有一行 `hooks:`,就把 `pre_llm_call:` 那部分放到它下面):

```yaml
hooks:
  pre_llm_call:
    - command: "~/.hermes/agent-hooks/rookie-work-inject.sh"
      timeout: 10
```

启动 Hermes——输入 `/rookie-work` 就能用,而且它每次会话都会自动招呼你。首次它会问 `Allow this hook to run? [y/N]`,输入 `y` 再按 **回车**。

## 关闭开关

- **最简单——直接说:** 对助手说「关掉 rookie-work」(或「给我 raw mode / 原始模式」),它本次会话就停用;说「重新打开」即恢复。让它「永久关闭 rookie-work」,它会替你新建下面那个文件(并先告诉你)。
- **手动、持久关闭:** 在你的「主目录(home)」里新建一个名为 `.rookie-work-off` 的空文件即可全局关闭,或在某个项目文件夹里新建就只关那个项目。删掉该文件即重新开启。

三家(Claude Code、Codex、Hermes)通用。

## 语言

rookie-work 用**你的语言**和你交流——你用什么语言写,它就用什么语言答。本文档提供英文与简体中文两版;方法文件本身用英文书写以便移植。

## 版本状态

**v1.1.0** —— 为第 2 档新增了「框架化 + 边界发现」前置阶段(帮助不懂开发的人,在写任何代码之前,把一个模糊的想法理成清晰、且自己真正掌握的计划)。v1.0.0 是首个公开版本。设计与实现笔记见 `docs/`。

## 许可

MIT © 2026 xuzheng1210

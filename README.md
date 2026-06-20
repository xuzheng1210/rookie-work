# rookie-work

> A beginner-safe workflow guardrail for Claude Code.
> The agent never changes anything of yours before telling you — in plain language you understand — what it's about to do and how, and getting your OK.

## What it does

rookie-work makes Claude Code work the way a careful senior engineer would, so people new to AI agents get good results without having to know what discipline to ask for:

- **Explains before it acts.** Before any real change, the agent tells you — in plain language — what it will do and how, and confirms the direction with you first.
- **No silent decisions.** Whenever there's a real choice (which approach, which model to use for a sub-task, whether to run an extra review), the agent lays out the options with pros and cons and a recommendation, and lets you pick.
- **Right-sized ceremony.** A read-only lookup just happens. A small edit gets a quick "here's what I'll do — OK?". A real feature gets a full understand → design → plan → build → verify flow. Nothing trivial gets bogged down; nothing risky gets rushed.
- **Leaves a trail.** Every change is recorded in a plain-language changelog, so you (and the agent, later) can see what happened and why.
- **Gets you started even if you can't write a spec.** If you only know the result you want, it offers to build the development framework *with* you first — in plain language, one decision at a time — so you understand and own what you're building before any code.

It is **on by default** the moment you install it.

## Install

```text
/plugin marketplace add https://github.com/xuzheng1210/rookie-work
/plugin install rookie-work@rookie-work-marketplace
```

After a new version is published, run `/plugin marketplace update` to get it.

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

## Turn it off

- **Just this session:** tell the agent "turn off rookie-work" (or "give me raw mode"); it stands down for the current session.
- **Persistently:** create an empty file `~/.rookie-work-off` to turn it off everywhere, or `<your-project>/.rookie-work-off` to turn it off for one project. Delete the file to turn it back on. (You can also just ask the agent to do this for you.)

## Language

rookie-work talks to you in **your** language — whatever you write in, it answers in.

## Status

v1.1.0 — adds a framing & boundary-finding front-stage to Tier 2 (helps users new to development turn a vague idea into a clear, owned plan before any code). v1.0.0 was the first public release. Design and implementation notes live in `docs/`.

## License

MIT © 2026 xuzheng1210

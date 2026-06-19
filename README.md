# rookie-work

> A beginner-safe workflow guardrail for Claude Code.
> The agent never changes anything of yours before telling you — in plain language you understand — what it's about to do and how, and getting your OK.

## What it does

rookie-work makes Claude Code work the way a careful senior engineer would, so people new to AI agents get good results without having to know what discipline to ask for:

- **Explains before it acts.** Before any real change, the agent tells you — in plain language — what it will do and how, and confirms the direction with you first.
- **No silent decisions.** Whenever there's a real choice (which approach, which model to use for a sub-task, whether to run an extra review), the agent lays out the options with pros and cons and a recommendation, and lets you pick.
- **Right-sized ceremony.** A read-only lookup just happens. A small edit gets a quick "here's what I'll do — OK?". A real feature gets a full understand → design → plan → build → verify flow. Nothing trivial gets bogged down; nothing risky gets rushed.
- **Leaves a trail.** Every change is recorded in a plain-language changelog, so you (and the agent, later) can see what happened and why.

It is **on by default** the moment you install it.

## Install

```text
/plugin marketplace add xuzheng1210/rookie-work
/plugin install rookie-work@rookie-work-marketplace
```

After a new version is published, run `/plugin marketplace update` to get it.

## Turn it off

Tell the agent "turn off rookie-work" (or "give me raw mode") any time, and it stands down for the current session.

*(A persistent, across-sessions off-switch ships with the activation hook — see `docs/`.)*

## Language

rookie-work talks to you in **your** language — whatever you write in, it answers in.

## Status

Early development (v0.1.0). Behavior is being built out plan-by-plan; see `docs/specs/` and `docs/plans/`.

## License

MIT © 2026 xuzheng1210

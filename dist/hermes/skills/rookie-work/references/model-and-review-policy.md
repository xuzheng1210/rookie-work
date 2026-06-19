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

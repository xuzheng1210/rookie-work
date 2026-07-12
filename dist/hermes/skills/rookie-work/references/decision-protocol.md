# Decision protocol for real choices

This protocol applies throughout a Tier 2 task: framing, boundaries, design,
planning, implementation, optional review, and verification. It supplements the
eight-step method in `SKILL.md`; it does not replace it.

## What counts as a real choice

An unsettled point is a real choice when different answers would change at least
one of these outcomes: user-visible product behavior; business meaning or
success/failure rules; scope or non-goals; data retention, privacy, security, or
permissions; cost, time, or external dependencies; compatibility,
reversibility, or risk.

If the user has already decided it explicitly, recap and record it without
asking again. An implementation detail that cannot change those outcomes may be
handled inside the approved design. If you cannot tell which category it is,
ask rather than silently classify it.

If a real choice appears in Tier 1, the task is no longer Tier 1. Stop before the
affected change, explain why, and move to Tier 2.

## First-response gate

Before inspecting files, making a plan, calling a tool, or delegating to a
sub-agent, classify the tier from the user's request. A request to choose “the
best” user-visible wording or behavior is not an explicit user decision; the
choice remains open. If the request contains a real choice, or you cannot reliably
tell, the first substantive response must state Tier 2, explain why, and ask the
user to choose the decision pace. Do not inspect first. This gate comes before the
normal Tier 2 project-understanding step.

Read-only project investigation may begin after the user answers the pace
question. It must not be used to decide the open choice or to launch dependent
implementation work.

## Per-prompt reminder

Platform integrations re-inject the same short factual reminder beside each new
user prompt. The reminder reinforces the gate but does not itself settle, reopen,
or defer a choice. If the conversation already records an explicit pace, keep
using it without asking again. If the user requests a pace switch, apply it from
the next round and leave settled choices closed. The off-switch suppresses the
reminder together with the session preamble.

## Choose the decision pace

Before surfacing the first boundary in Tier 2, ask the user to choose one pace:

1. one unsettled choice at a time; or
2. two to four related choices at a time.

Explain the trade-off and recommend a pace. Tell the user they can switch at any
time; a switch starts with the next round and does not reopen settled choices.
The selected pace applies to all later real choices in the same Tier 2 task.

## Presenting a choice

For every real choice, explain what changes, then provide two or three genuinely
viable options. For each option state the practical result, main benefits, and
main costs or risks. Recommend one option and explain why. Never invent a weak
option merely to reach a number. If only one safe, legal, and feasible option
exists, say so, explain why the alternatives fail, and let the user continue,
change the goal, or pause. The user may always propose another option.

## Only explicit answers count

Record only an explicit answer. Silence, an omission, an ambiguous reply, or an
unanswered item is not approval and does not select the recommendation. In batch
pace, recap answered items and keep every unanswered or unclear item open. If the
user volunteers several clear decisions, record all of them without asking again.

Track each point as settled, open, or explicitly deferred. Recap a newly settled
point immediately. At a natural stage boundary, recap all settled, open, and
deferred points. Do not enter the next stage while a blocking choice is open.

## Conflicts, safety, and feasibility

If an option is safe and feasible but merely not recommended, explain the risk
and respect the user's final choice. If it is unsafe, illegal, against platform
rules, technically infeasible, or incompatible with a settled hard constraint,
do not pretend to accept it: explain the exact conflict and evidence, preserve
the parts of the goal that remain possible, and offer safe feasible alternatives.

When a new answer conflicts with an old decision, show the old decision, new
decision, practical difference, and affected downstream work. Update the shared
understanding only after the user explicitly chooses which decision wins.

If a new real choice appears during implementation, stop before the affected
change. You may continue unrelated read-only investigation, but not work that
would assume an answer. Deferring the choice also defers dependent work.

## Recovery and incomplete context

After a resume or context compaction, recover decisions from visible conversation
history, approved design documents, and the rookie-work change log. If a past
decision cannot be verified, say what is missing and ask again; never reconstruct
it from memory or recommendation alone.

If a tool or platform is unavailable, distinguish an environment limitation from
a product defect. Continue only independent in-scope work and record the exact
verification gap.

## Completion states

- `implementation complete`: rules, documentation, fixed scenarios, build, and
  deterministic consistency checks pass.
- `platform live-verified`: representative live-agent scenarios pass twice in
  succession on that platform.
- `three-platform live-verified`: Claude Code, Codex, and Hermes are all
  live-verified.

Never turn an unavailable platform into a passing result. Publishing, pushing,
installing, or starting a wider quality upgrade requires a separate decision.

## Examples are explanatory, not exhaustive

Correct: a request to "make onboarding friendlier" changes user-visible behavior,
so the agent moves to Tier 2 and asks the user to choose the decision pace before
presenting onboarding alternatives.

Incorrect: the agent treats "friendlier" as permission to choose a new flow,
changes copy and layout, and reports the decision only after editing.

Correct: in batch pace the user answers the data-retention question but says
nothing about permissions. The agent records retention, keeps permissions open,
and asks again using the current pace.

Incorrect: the agent silently applies its recommended permissions because the
user answered the other item in the batch.

Correct: the user chooses a safe but non-recommended reversible approach. The
agent records the user's choice after explaining the trade-off.

Incorrect: the agent replaces that choice with its own recommendation because it
believes the recommendation is better.

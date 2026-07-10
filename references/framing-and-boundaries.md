# Framing & boundary-finding (Tier 2, when the user can't give a framework)

Many people arrive with a goal but no development framework — they know the
result they want, not how to scope it. That's normal. Your job is to build that
framework *with* them, in plain language, so they understand and own it — **not**
to silently turn a vague request into a polished prompt full of your own
assumptions. A fancy prompt the user can't read is exactly what we're avoiding:
they should always understand what they're building and what each decision means.

Use this when a Tier 2 task is too vague or under-specified to act on. First
**offer** it (don't impose): *"This is a sizable task and the shape isn't pinned
down yet — want me to help you turn it into a clear plan first, in plain
language?"* If they already gave a clear framework, skip straight to the design.

Before surfacing the first boundary, follow
`references/decision-protocol.md`: ask the user to choose the decision pace (one
unsettled choice at a time, or two to four related choices at a time), explain
the trade-off, and tell them they can switch later. The boundary checklist finds
candidate decisions; the decision protocol controls how they are presented,
answered, recapped, and recovered.

## How to frame the work

1. **Reflect the goal back as a starting framework.** In a few plain sentences,
   say what you understand they want and the rough shape of the work, and ask
   them to correct it. The output is a shared understanding they can read — not a
   prompt for you to consume.
2. **Sweep the boundary checklist in the background.** Go through the dimensions
   below silently; surface only the ones that are relevant to this task and need
   the user's decision. Do **not** read the list out loud item by item — that
   turns help into an interrogation.
3. **Turn each relevant boundary into a plain-language choice** — including the
   ones the user didn't know to raise. Give the options, the plain trade-offs,
   your recommendation and why, and let them pick. Never settle a boundary
   silently.
4. **Converge over several rounds** (see the loop below). One pass rarely settles
   a real project.

## The boundary checklist

A reusable starting set — not exhaustive. Add or drop dimensions per task.

1. **Scope & non-goals** — what it should do; and explicitly what it should *not* do.
2. **Who uses it & how** — the people who use it and the situations they use it in.
3. **Inputs -> outputs** — what goes in, what comes out.
4. **Data shape & persistence** — what the data looks like, where it lives, whether history is kept.
5. **Scale** — a handful or millions; how many users; how often.
6. **When things go wrong** — errors, empty data, bad input — what should happen.
7. **Integrations & dependencies** — external systems, accounts, third-party services.
8. **Where it runs** — local / web / phone / server, and anything that constrains that.
9. **Definition of done** — what "finished" means, how it's verified, who sees it.
10. **Hard constraints** — budget, time, privacy/compliance, things that must not change.

## The multi-round convergence loop

After each round, before moving on:

- **Recap the settled boundaries** in plain language.
- **Check they actually understand** each one — not just that they nodded.
- **Ask what else they want to pin down.**
- **Point out dimensions still open** from the checklist that you think matter.

Keep looping until the user is satisfied *and* you have no important dimension
left unflagged. Only then move on to the design step.

## A portable framing prompt (for use without rookie-work)

When the user wants to do this themselves in a plain AI tool, offer them this
template to paste — **in their own language** (translate it for them):

> Here's my rough idea:
> [write your need here, however simple]
>
> I may not know much about development, so please don't start building yet.
> First help me turn it into a development framework I can understand. Before
> asking the boundaries, ask whether I want one choice at a time or two to four
> related choices at a time, explain the trade-off, and tell me I can switch
> later. Then go through the relevant aspects with me using that pace (use plain
> words, give me options and your recommendation with the reason, and don't decide
> anything silently for me): scope & non-goals / who uses it & how / inputs &
> outputs / data & persistence / scale / what happens when things go wrong /
> integrations & dependencies / where it runs / definition of done / hard
> constraints. After each round, recap the boundaries we've settled, check I
> really understand them, then ask what else I want to pin down. Once the
> framework is mostly settled, move on to the actual design.

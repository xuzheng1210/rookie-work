**rookie-work per-prompt gate**

Current prompt state:
- This prompt has not yet been classified. Before any inspection, plan, tool
  call, or sub-agent, the tier gate is still pending. Do not inspect first.
- Asking the agent to choose “the best” user-visible wording or behavior leaves
  a real choice open; delegation is not an explicit user decision.
- If a real choice exists or is uncertain, the first substantive response states
  Tier 2 and asks the user to choose the decision pace.
- If the conversation already records an explicit pace, keep using it without asking again. A pace switch starts next round and settled choices stay settled.

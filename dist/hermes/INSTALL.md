# Install rookie-work on Hermes

1) Install the skill (auto-exposes `/rookie-work`):
   ```bash
   cp -R skills/rookie-work ~/.hermes/skills/
   # or: hermes skills tap add xuzheng1210/rookie-work
   ```
2) Install the always-on hook (script + its preamble and prompt gate, kept together):
   ```bash
   mkdir -p ~/.hermes/agent-hooks
   cp agent-hooks/rookie-work-inject.sh agent-hooks/SESSION-PREAMBLE.md agent-hooks/PROMPT-GATE.md ~/.hermes/agent-hooks/
   ```
   Then merge `config-snippet.yaml` into `~/.hermes/config.yaml`. The first run asks you to
   approve the shell hook (or set `HERMES_ACCEPT_HOOKS=1`, or `hooks_auto_accept: true`).
3) Start a new session — `/rookie-work` is available and the discipline is injected on the first turn.

## Turn it off
- Marker file: create `~/.rookie-work-off` (everywhere) or `<project>/.rookie-work-off` (one project); delete to re-enable.
- Or natively: set `skills.disabled: [rookie-work]` in `~/.hermes/config.yaml`, or remove the `hooks:` entry.

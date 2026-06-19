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

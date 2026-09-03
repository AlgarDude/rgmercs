# Pattern review

Deterministic reviewer that runs on every pull request (`.github/workflows/pattern-review.yml`).
It only looks at lines the PR adds, and every finding cites the existing helper or convention it
is challenging. It comments; it never blocks.

- `build-index.js` walks `utils/`, `modules/`, `ui/`, `lib/`, `extras/`, `init.lua`, `heartbeat.lua`
  and records every function (exported and local) with file, line, params and doc summary.
  Built from the base branch on each run, so "already exists" always means what was on `main`.
- `lint.js` diffs base..head, scans the added lines, and reports:
  - `reuse/*` - a new function shares a name (or a known alias) with an existing helper,
    or re-implements an idiom the codebase routes through a helper.
  - `pattern/*` - unguarded TLO string chains, `mq.delay` inside a render function,
    bare module-level locals.
  - `style/*`, `naming/*` - the formatter config in `rgmercs.code-workspace`
    (4-space indent, 180 columns, trailing table separator), no `goto`, no em dashes in
    strings, camelCase locals.

Run locally against your branch:

```bash
node .github/review/build-index.js --out /tmp/index.json
node .github/review/lint.js --base main --head HEAD --index /tmp/index.json
```

Add `--strict` to exit non-zero on warnings, `--format github` for annotations,
`--out-md` / `--out-json` for the comment body and machine-readable report.

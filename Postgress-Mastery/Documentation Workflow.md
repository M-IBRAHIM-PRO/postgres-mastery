# Documentation Workflow

This file stores the standing rules for generating quick-reference notes from a
daily learning folder.

## Goal

Documentation should support learning, not become the main work.

```txt
You write notes.md.
Codex turns it into compact reference docs.
You keep learning and implementing.
```

## Command

Use this prompt:

```txt
Process day-0_ notes
```

Provide the day folder path, for example:

```txt
Process day-03 notes: Postgress-Mastery/day-03
```

When the day's notes are complete, use:

```txt
day-0_ notes finalized
```

After this, Codex should update these files only if necessary:

- root `README.md`
- `hands-on/README.md`

Only update them when the finalized day changes the project overview, current
focus, schema shape, hands-on structure, setup steps, run steps, or important
links.

## Source Of Truth

- `notes.md` is the raw learning dump and source of truth.
- Do not rewrite `notes.md` unless explicitly asked.
- Generate or refine other files from `notes.md`.

## Output Rules

- Decide output files based on the day's topics.
- Always consider:
  - `day-0_ - Architecture.md` for DB/schema architecture changes.
  - `day-0_ - FAQs.md` for tricky questions, tradeoffs, and common mistakes.
- Create topic files only when useful, such as:
  - `datatypes.md`
  - `relationships.md`
  - `indexes.md`
  - `transactions.md`
  - `constraints.md`
  - `queries.md`
  - `performance.md`

## Style

- Compact engineering notes.
- Useful for quick revision.
- No textbook bloat.
- Compact does not mean important topics are missing.
- Prefer examples, rules, and memory hooks when they clarify the concept.

## Obsidian Rules

- Use Obsidian links to avoid repetition.
- One concept should have one source note.
- Other notes should link to the source note instead of repeating the same explanation.
- After generating files, scan the whole day folder and remove repetition by linking to the relevant note.

## FAQ Rules

FAQs should not repeat definitions.

FAQs should answer:

- tricky questions
- common confusion points
- tradeoffs
- mistakes beginners make
- "why this design?" questions

## Project Connection

Connect notes to real project files only when useful:

- SQL files in `hands-on/sql/queries/`
- Go files in `hands-on/`
- actual schema names and table names

Do not force implementation references when the topic is purely conceptual.

## Standard Workflow For Codex

1. Read the requested day folder.
2. Read `notes.md` first if it exists.
3. Inspect existing files in that same day folder.
4. Decide which reference files are useful.
5. Generate or refine compact notes.
6. Use Obsidian links to avoid repetition.
7. Check the whole day folder again for duplicated explanations.
8. Leave `notes.md` unchanged unless explicitly asked.

## Finalization Workflow

When the user says:

```txt
day-0_ notes finalized
```

Codex should:

1. Re-scan the finalized day folder.
2. Check whether root `README.md` needs a compact update.
3. Check whether `hands-on/README.md` needs a compact update.
4. Update those README files only if the finalized day changed something readers need to know.
5. Keep README updates short and practical.

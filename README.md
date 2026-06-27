# Personal Dashboard — Chris Bailey Photography

A single-pane-of-glass dashboard to start the day: schedule, to-dos, priority
email, goals, an AI assistant, and automated report briefs. Styled to match the
Chris Bailey Photography brand (fine-art editorial — serif wordmark, slate/navy
palette on a light-beige canvas).

## Live site

Deploys automatically to **GitHub Pages** on every push to `main`
(see `.github/workflows/deploy.yml`). URL appears in the Action's summary once
Pages is enabled.

## Structure

```
index.html   # the whole dashboard — self-contained (HTML + CSS + JS inline)
README.md
.gitignore
.github/workflows/deploy.yml   # GitHub Pages auto-deploy
```

Kept as one file on purpose while it's a single page. When it grows past that,
split into `/css`, `/js`, and per-module partials.

## Local preview

Just open `index.html` in a browser, or serve it:

```bash
python3 -m http.server 8000   # then visit http://localhost:8000
```

## What works today

- **Daily Command Center** — live clock/greeting, today's agenda, Business /
  Personal to-dos (add, check, delete), priority inbox with draft-reply
  shortcuts, Goal Focus + a gratitude note.
- **Assistant** — talk-or-type box; understands `add to-do:` /
  `add personal to-do:` commands directly, and answers/drafts via Claude when
  run inside Cowork.
- **Automated Reports** — on-demand briefs (e.g. photo-booth market pulse).
- To-dos, goals, and gratitude **persist in the browser** (localStorage).

## Roadmap — making it live

The agenda, inbox, and any financial figures currently show sample data with
"connect" prompts. To go live, wire each to a data source:

- **Calendar** — Google / Apple Calendar → real agenda
- **Email** — Gmail / Outlook → real priority inbox + AI-drafted replies
- **Finance** — brokerage / cards / Digits → stocks, balances, due dates
- **Family Hub** — kids' section, school-email parser, family photo stream
- **Assistant execution** — tie to Claude on the studio Mac mini for real task
  actions (scheduling, calendar edits)

## Notes

This dashboard is the canonical source going forward — edits land here and ship
via Pages, rather than being regenerated from scratch.

Kevin’s clean Now-5 cards (no star screenshots).

Playbook prefers `*.png`. Animator routes in `plays.html` are traced to match these pictures.
`deploy.yml` strips this folder from public GitHub Pages.

## Original crop pixels (required for undraft)

Chat attachments for `/workspace/play-crops-clean/play-*.png` are **not landing on the
agent VM** (folder stays empty; `Read` / `Task` `file_attachments` fail). Until the
original bytes are on disk, the PNGs here are **traced recreations** from
`_render_cards.py`, not Kevin’s crop pixels.

To finish: push the 7 original crops onto this branch as:

- `play-cards/23.png`, `26.png`, `38.png`, `68.png`, `02.png`, `19.png`, `06.png`
- also keep `2.png` ← `02.png` and `6.png` ← `06.png` (app loads both names)

Then re-run nothing — Playbook already prefers `*.png`. Undraft PR #40 only after
Playbook shows those original files and the animator matches 23/26/38.

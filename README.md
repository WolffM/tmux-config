# tmux-config

**Guide:** [overview](docs/guide/index.md) · [features](docs/guide/features.md) · [contributing](docs/guide/contributing.md) · [history](docs/guide/history.md) · [trivia](docs/guide/trivia.md)

A mouse-first, no-Shift-gymnastics tmux setup. Layout survives terminal
crashes and reboots; the terminal is the tab manager, not the app.

## Keymap (all after the `Ctrl-Space` prefix)

| Action | Keys |
| --- | --- |
| New tab | `t` |
| Next / prev tab | `Tab` / `Shift+Tab` |
| Go to tab 1–9 | `1`…`9` |
| Rename tab (pins the name) | `R` |
| Close pane (last one closes the tab) | `Ctrl+w` |
| Split right (beside) | `]` |
| Split down (stacked) | `[` |
| Zoom pane fullscreen | `z` |
| Detach | `d` |
| New session | `g` |
| Move this tab to another session | `M` |
| Session/tab tree | `s` |
| Previous / next session | `(` / `)` |

Copy = drag with the mouse (→ system clipboard). Paste = `Ctrl+Shift+V`.
`Shift+drag` gives the terminal's own native selection.

## Install

```sh
git clone https://github.com/WolffM/tmux-config ~/repos/tmux-config
~/repos/tmux-config/install.sh
```

See [contributing](docs/guide/contributing.md#running-it-locally) for what
`install.sh` does and how to pick up a later config change.

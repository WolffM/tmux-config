# tmux-config

A mouse-first, no-Shift-gymnastics tmux setup. Layout survives Konsole crashes
and reboots; the terminal is the tab manager, not the app.

## Highlights

- **Prefix: `Ctrl-Space`** (`Ctrl-b` kept as a backup).
- **Mouse-first** — click the top status bar to switch tabs, click a pane to
  focus, drag to select (copies straight to the system clipboard via `wl-copy`).
- **Status bar on top**, dark Tokyo-Night palette, useful window titles
  (`#I: #W`, surfaced to the terminal via `set-titles`).
- **Persistence** via [tmux-resurrect] + [tmux-continuum]: layout auto-saved
  every 5 min. Auto-restore is intentionally **off** (it races/clobbers) —
  restore is on-demand instead.

## Claude session restore

A small utility (in `bin/` + `systemd/`) that makes resurrect restore each
[Claude Code] pane back into its **exact** session — even when several sessions
share one repo — instead of dropping you at the `--resume` picker.

- **`bin/claude-tmux-session-hook`** — a resurrect `@resurrect-hook-post-save-layout`
  hook. On every save it resolves each claude pane's real session id from
  Claude's live registry (`~/.claude/sessions/<pid>.json`, reached by walking the
  pane's process subtree) and rewrites the saved restore command to
  `claude --resume <sessionId>`. Runs before resurrect's dedup, so a stable
  layout still collapses to one state file.
- **`bin/claude-tmux-boot-restore`** — headless, idempotent one-shot restore
  (create the `claude` session + restore, no attach). Safe to re-run: if the
  session already exists it does nothing.
- **`systemd/claude-tmux-restore.service`** — runs the boot restore after
  `plasma-workspace.target`, i.e. at the end of graphical login.

`install.sh` symlinks all three into place and enables the service.

[Claude Code]: https://claude.com/claude-code

## Keymap (all after the `Ctrl-Space` prefix)

| Action | Keys |
| --- | --- |
| New tab | `t` |
| Next / prev tab | `Tab` / `Shift+Tab` |
| Go to tab 1–9 | `1`…`9` |
| Close tab (no confirm) | `Ctrl+w` |
| Split right (beside) | `]` |
| Split down (stacked) | `[` |
| Zoom pane fullscreen | `z` |
| Detach | `d` |

Copy = drag with the mouse (→ system clipboard). Paste = `Ctrl+Shift+V`.
`Shift+drag` gives the terminal's own native selection.

## Install

```sh
git clone https://github.com/WolffM/tmux-config ~/repos/tmux-config
~/repos/tmux-config/install.sh
```

`install.sh` symlinks `~/.tmux.conf` to this repo and installs [TPM] plus the
resurrect/continuum plugins. On Wayland it expects `wl-clipboard` for
clipboard integration (`sudo apt install wl-clipboard`).

[TPM]: https://github.com/tmux-plugins/tpm
[tmux-resurrect]: https://github.com/tmux-plugins/tmux-resurrect
[tmux-continuum]: https://github.com/tmux-plugins/tmux-continuum

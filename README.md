# tmux-config

A mouse-first, no-Shift-gymnastics tmux setup. Layout survives Konsole crashes
and reboots; the terminal is the tab manager, not the app.

## Highlights

- **Prefix: `Ctrl-Space`** (`Ctrl-b` kept as a backup).
- **Mouse-first** — click the top status bar to switch tabs, click a pane to
  focus, drag to select (copies straight to the system clipboard via `wl-copy`).
- **Status bar on top**, dark Tokyo-Night palette, useful window titles
  (`#I: #W`, surfaced to the terminal via `set-titles`).
- **Tabs are named after their directory**, not the running command — the
  default `#{pane_current_command}` made every tab read `claude`. A leading
  `hadoku-` / `hadoku_` is stripped, so `~/repos/hadoku-trader` reads as
  `trader`. The name follows the pane's cwd, so `cd` renames the tab;
  renaming by hand (`R`) pins it for good.
- **Persistence** via [tmux-resurrect] + [tmux-continuum]: layout auto-saved
  every 5 min. Auto-restore is intentionally **off** (it races/clobbers) —
  restore is on-demand instead.
- **Several sessions, one save.** Split work into named sessions (e.g.
  `platform` and `creative`); resurrect saves and restores all of them together.
  `g` starts a session, `M` moves the current tab into another one, `s` picks
  from a tree of every session and tab, `(` / `)` cycle sessions. The current
  session's name sits at the left of the status bar.

## Claude session restore

A small utility (in `bin/` + `systemd/`) that makes resurrect restore each
[Claude Code] pane back into its **exact** session — even when several sessions
share one repo — instead of dropping you at the `--resume` picker.

- **`bin/claude-tmux-session-hook`** — a resurrect `@resurrect-hook-post-save-layout`
  hook. On every save it resolves each claude pane's real session id from
  Claude's live registry (`~/.claude/sessions/<pid>.json`, reached by walking the
  pane's process subtree) and rewrites the saved restore command to
  `claude --resume <sessionId>`. Runs before resurrect's dedup, so a stable
  layout still collapses to one state file. It only pins `--resume` when the
  transcript is actually resumable *from that pane's cwd* — renaming a repo
  moves the cwd and orphans every transcript filed under the old project key,
  so an unresolvable id degrades to a plain `claude` instead of a pane that
  dies with "No conversation found" on every restore.
- **`bin/claude-tmux-restore-core`** — the restore itself, shared by both entry
  points. Bootstraps under a throwaway session name and lets resurrect create
  every saved session from the state file, waits for the restore to settle,
  then reports what it got per session. See the header comment for why both of
  those matter. Given a session name, it also makes sure that session exists.
- **`bin/claude-tmux-boot-restore`** — headless entry point (no attach), for systemd.
- **`bin/claude-session [name]`** — interactive entry point: restore first if no
  saved session is up yet, then attach to `name` (created if missing) or, with
  no name, to the most recently used session.
- **`systemd/claude-tmux-restore.service`** — runs the boot restore after
  `plasma-workspace.target`, i.e. at the end of graphical login.

Both entry points are idempotent: if any saved session is already running they
restore nothing, so they never clobber sessions you built by hand.

`install.sh` symlinks them all into place and enables the service.

## Lost socket: `tmux-socket-recover`

If `/tmp/tmux-$UID/default` disappears (a `/tmp` sweep took it on 2026-10-20),
the server keeps running but nothing can attach. `kill -USR1 <server>` makes it
recreate the socket, **but never do that bare**: on tmux 3.5a (Debian trixie,
and 3.6b in backports) a USR1 while the socket *directory* is missing fails
`bind()`, and that error path leaves the server stuck on umask 0117 for good
(`server.c:125-135`, fixed upstream in 3.8). Every pane opened afterwards then
creates directories with no execute bit.

`tmux-socket-recover` recreates the directory (0700) first, signals only when
the socket is really gone, and then checks the server's umask, printing the
in-place `gdb` fix if it is wrong. It never kills or restarts a server.
`tmux-umask-check.timer` runs `tmux-socket-recover --check` (read-only) every
15 minutes and raises a desktop notification if any server's umask is not
`$TMUX_EXPECTED_UMASK` (default 0002).

[Claude Code]: https://claude.com/claude-code

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

Copy = drag with the mouse (→ system clipboard). Paste = `Ctrl+Shift+V`.
`Shift+drag` gives the terminal's own native selection.

**There is no kill-window.** `Ctrl+w` closes one pane, and takes the tab with it
only when it is the last pane. Everything that could drop a tab full of splits
in one keystroke is unbound — `X`, the `&` confirm-kill default, and the
Kill/Respawn entries in the window menu (`<`, and right-click on a tab in the
status bar). Right-click was the sharp one: in a mouse-first setup, Kill sat one
slip away from Swap. To close a tab, close its panes.

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

---
title: tmux-config
summary: >-
  A mouse-first tmux setup: click a tab or pane instead of memorizing chords,
  drag to copy to the system clipboard, and a saved layout — including every
  running Claude Code pane's exact conversation — comes back on demand after
  a reboot or a crash.
features:
  - name: Mouse-first keymap
    summary: 'Click the top status bar to switch tabs, click a pane to focus, drag to select and copy.'
    anchor: mouse-first-keymap
  - name: Directory-named tabs
    summary: 'Tabs are named after their working directory, not the command running in them.'
    anchor: directory-named-tabs
  - name: Session persistence
    summary: 'Layout autosaves every 5 minutes; restore is on demand, never automatic.'
    anchor: session-persistence
  - name: Claude session restore
    summary: 'A restored Claude pane reattaches to its exact prior conversation, not a picker.'
    anchor: claude-session-restore
  - name: No kill-window
    summary: 'Every one-keystroke way to destroy a whole tab of panes at once is unbound.'
    anchor: no-kill-window
  - name: Socket recovery
    summary: 'Brings a tmux server back after its socket file disappears, without a known umask leak.'
    anchor: socket-recovery
trivia:
  - 'The first commit shipped the keymap, the dark status bar and resurrect/continuum persistence all at once (`ef9f0b1`).'
  - "A restore once ate an entire saved 3-pane window: the old code killed a bootstrap window that resurrect had already reused for the real restore (`9c78ccb`)."
  - 'tmux 3.5a (and 3.6b in trixie-backports) leaves a server''s umask permanently wrong if `SIGUSR1` hits it while its socket directory is missing — found when a `/tmp` sweep deleted the directory, fixed the next day (`5aed18f`).'
  - 'Longest quiet spell in the history: 54 days, `9c78ccb` (2026-07-29) to `5f8ba07` (2026-09-21) (fact sheet, 2026-11-16).'
---

# tmux-config

A personal tmux configuration: `Ctrl-Space` prefix, mouse-first everywhere
(click to switch or focus, drag to copy), and a dark status bar at the top
instead of the default green one at the bottom. Layout survives a terminal
crash or a reboot — `tmux-resurrect` and `tmux-continuum` autosave every 5
minutes, and a small restore utility brings every saved session back,
including each Claude Code pane's exact prior conversation rather than
`claude`'s own `--resume` picker.

A second, independent utility watches for a tmux-specific bug: on some tmux
builds, recovering a lost socket the usual way (`kill -USR1`) can leave the
server's directory-creation permissions silently broken for the rest of its
life. `tmux-socket-recover` works around it.

- [Features](features.md): what each piece does and how to use it.
- [Contributing](contributing.md): installing it, the scripts, how to change it.
- [History](history.md): the first commit, the window a bad restore ate, and the account split that changed how sessions are found.
- [Trivia](trivia.md)

## Trivia

A `/tmp` sweep on 2026-10-20 deleted the running tmux server's socket
directory; the usual one-line fix for that, `kill -USR1`, turns out to hit a
tmux bug that leaves the server's umask broken forever
([history](history.md#the-socket-recovery-era)).

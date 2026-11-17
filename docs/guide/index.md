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

The status bar it draws, top of screen, dark background (`tmux.conf`'s
`status-left` and `window-status-*` styles). The window format is tmux's
own default, `#I:#W#F`, never overridden here: it appends `*` to the active
window and `-` to the window last visited before it. Captured for real from
an isolated test server, three windows opened in three public repos'
clones:

```text
 work  1:trader  2:cardtable-  3:tenhands*
```

Tab names track each pane's working directory, not the command running in
it: `trader`, `cardtable` and `tenhands` are the clone directories'
basenames with a leading `hadoku-` stripped, not the command any of their
panes happens to be running.

- [Features](features.md): what each piece does and how to use it.
- [Contributing](contributing.md): installing it, the scripts, how to change it.
- [History](history.md): the first commit, the window a bad restore ate, and the account split that changed how sessions are found.
- [Trivia](trivia.md)

## Trivia

A `/tmp` sweep on 2026-10-20 deleted the running tmux server's socket
directory; the usual one-line fix for that, `kill -USR1`, turns out to hit a
tmux bug that leaves the server's umask broken forever
([history](history.md#the-socket-recovery-era)).

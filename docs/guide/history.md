# History

13 commits from one author between 2026-07-12 and 2026-11-01 (`git log
--reverse --format='%h %ad %s' --date=format:'%Y-%m-%d %a'`). One era of
build, then a 54-day gap, then an era of hardening the restore path against
real failures as they happened.

## Origin (2026-07-12 – 2026-07-29)

The first commit (`ef9f0b1`, Sunday 2026-07-12) shipped the whole base
config at once: the `Ctrl-Space` prefix, the mouse-first bindings, the dark
status bar, and `tmux-resurrect`/`tmux-continuum` autosave. Six days later,
`6eb63fc` (2026-07-18) added the Claude session-id restore utility as two
scripts plus a systemd unit, in one commit. Four days later, the following
week, two more commits (`032e75f`, `6ba9aa0`, both 2026-07-22) renamed tabs
after their directory instead of the running command, and removed every
one-keystroke way to kill a whole tab of panes.

The era ends with its only outright bug fix. `9c78ccb` (2026-07-29) found
that the restore code killed a leftover bootstrap window every time it ran,
meaning to drop what it thought was still a blank bootstrap window. But
`tmux-resurrect` had, by then, already reused that window for the first
saved window's real content, so the kill destroyed it instead — silently
eating a 3-pane window on a 13-window restore. See
[features.md#session-persistence](features.md#session-persistence) for how
the fix (bootstrapping under a throwaway session name instead) works.

## Hardening the restore (2026-09-21 – 2026-10-25)

Nothing landed for 54 days — the longest gap in the repo's history, `9c78ccb`
(2026-07-29) to `5f8ba07` (2026-09-21) (fact sheet, 2026-11-16) — then five
fixes landed in just over a month, each written down against a specific
failure:

- `5f8ba07` (2026-09-21): a restored pane would die outright if the global
  Claude Code provider had failed over to GLM and its vault key could not be
  fetched; the restore now reverts to Anthropic first when that happens.
- `9af6b95` (2026-10-12): the session registry files had gone missing under
  every pid but one while their sessions kept running, so 129 consecutive
  autosaves recorded no session ids at all. The hook gained two fallbacks —
  a pane's open scratch-dir handle, then `--resume` on its own command line.
- `015802a` (2026-10-20): since the account split on 2026-10-18, each
  session registers under its own account's `CLAUDE_CONFIG_DIR` rather than
  the shared `~/.claude/sessions/`. The registry lookup alone found nothing;
  a measured run that day resolved 36 panes by 29 scratch-dir fallback, 7
  argv fallback, 0 by registry.
- `15bdd79` (2026-10-21): the tmux server inherited the cgroup of whatever
  started it; run from the boot-restore systemd unit, that meant restarting
  the unit killed the server and every pane in it. `new-session` now starts
  the server in a `systemd-run --user --scope` of its own.
- `c36f7db` (2026-10-25): the restore path, `claude-session` and the boot
  service had all assumed one session named `claude`; this rewrote them to
  restore, wait on, and report every saved session, and let `claude-session`
  take an optional session name.

The same day, `4444939` moved "new session" off `Shift+N` onto `prefix + g`,
since the config otherwise avoids Shift chords. The most recent commit,
`cc96a28` (2026-11-01), made restored Claude panes launch with
`--dangerously-skip-permissions`.

## The socket-recovery era

A separate failure path, unrelated to session restore: on 2026-10-20 a
`/tmp` sweep deleted the directory holding the running tmux server's socket.
The obvious one-line fix, `kill -USR1` to make the server recreate it, has a
trap on tmux 3.5a and 3.6b. Signalling while the socket *directory* is
missing fails inside `bind()`, and the server never restores the umask it
had set around that call, so every pane it creates afterward has no execute
bit on new directories. `5aed18f`, the next day (2026-10-21), added
`tmux-socket-recover`: it recreates the directory first, signals only when
the socket is genuinely gone, and then checks and reports the server's
umask. See [features.md#socket-recovery](features.md#socket-recovery).

## Trivia

`README.md` has been touched in 8 of the repo's 13 commits — more than any
other file, including the scripts and the config it documents (fact sheet,
2026-11-16).

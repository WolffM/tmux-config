# Trivia

- The first commit (`ef9f0b1`, Sunday 2026-07-12) shipped the prefix, the
  mouse bindings, the status bar and `tmux-resurrect`/`tmux-continuum`
  persistence all in one go — nothing in this repo predates it.
- A restore bug once silently ate an entire saved 3-pane window: the old
  restore code killed a leftover bootstrap window that `tmux-resurrect` had,
  by then, already reused for the real content (`9c78ccb`, 2026-07-29).
- tmux 3.5a (and 3.6b in Debian trixie-backports) has a bug where signalling
  a server to recreate its socket, while the socket's *directory* is also
  missing, leaves that server's umask permanently wrong — found a day after
  a `/tmp` sweep deleted the directory outright (`5aed18f`, 2026-10-21).
- The longest gap in the repo's history is 54 days with no commits at all:
  `9c78ccb` (2026-07-29) to `5f8ba07` (2026-09-21) (fact sheet, 2026-11-16).
- `README.md` has been touched in 8 of the repo's 13 commits — more than any
  script or the tmux config file itself (fact sheet, 2026-11-16).
- A restored Claude Code pane could die outright if the active AI provider
  had failed over to GLM and its vault-backed key could not be fetched; a
  guard added 2026-09-21 reverts the default to Anthropic first in that case
  (`5f8ba07`).
- "New session" was first bound to `Shift+N`; it moved to `prefix + g` the
  same day another commit landed, specifically to keep the config free of
  Shift-key chords (`4444939`, 2026-10-25).

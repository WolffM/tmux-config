# Features

## Mouse-first keymap

Click the top status bar to switch tabs, click any pane to focus it, and drag
across text to select it — the selection copies straight to the system
clipboard via `wl-copy` (`tmux.conf`: `set -g mouse on`, `set-clipboard on`,
and the `copy-mode`/`copy-mode-vi` `MouseDragEnd1Pane` bindings). The prefix
is `Ctrl-Space` (`Ctrl-b` still works as a fallback). After the prefix: `t`
opens a new tab, `Tab`/`Shift+Tab` moves between tabs, `]`/`[` split right or
down, `z` zooms a pane full-screen, `d` detaches.

It does not change tmux's own copy-mode keys beyond the mouse bindings above
— `Shift+drag` still gives the terminal's native selection instead.

## Directory-named tabs

A tab's name tracks the working directory of the pane in it, not the command
running there — tmux's default (`#{pane_current_command}`) made every tab
read `claude` or `bash` regardless of what repo it was in
(`tmux.conf`: `automatic-rename-format`). A leading `hadoku-` or `hadoku_` is
stripped, so a pane in `~/repos/hadoku-trader` shows `trader`. `cd` renames
the tab live; renaming it by hand with `R` (prefix + `R`) pins the name and
turns auto-rename off for that one tab.

It only affects the window's displayed name — it does not change the actual
command or directory.

## Multiple sessions

Work can be split across several named sessions (for example one for
platform work and one for creative work) instead of one big session full
of tabs. `prefix + g` prompts for a name and starts a new session; `prefix
+ M` moves the current tab into another named session; `prefix + s` opens
tmux's own tree of every session and tab to jump to; `prefix + (` / `prefix
+ )` cycle to the previous or next session. The current session's name sits
at the left of the status bar (`tmux.conf`'s `status-left`), so it is
always visible which one is active.

It is not a separate save: [session persistence](#session-persistence)
autosaves and restores every session together, not just the one in front.

## Session persistence

`tmux-continuum` autosaves the full layout (including each pane's command
line and visible contents, for `claude` panes specifically —
`@resurrect-capture-pane-contents`, `@resurrect-processes`) every 5 minutes.
Automatic restore is deliberately off: a session-created hook used to race
and could re-apply a bad saved layout on its own. Restore is always on
demand instead, through `claude-session [name]` (attach, restoring first if
nothing is running yet) or the headless `claude-tmux-boot-restore`, which a
systemd user service runs once at the end of graphical login
(`systemd/claude-tmux-restore.service`).

A restore that already finds any saved session running is a no-op — it never
overwrites a layout you built by hand, saved or not.

## Claude session restore

A `tmux-resurrect` post-save hook (`bin/claude-tmux-session-hook`,
`@resurrect-hook-post-save-layout`) rewrites every Claude Code pane's saved
restore command. A bare `claude --resume` (which drops you at the session
picker) becomes `claude --resume <sessionId>` for the exact conversation
that pane was running, even when several sessions share one repository. It
resolves each pane's session id by walking its process tree against
Claude's own live session registry, falling back to the pane's open
scratch-dir file handle or its process command line if the registry entry
is missing.

It only pins `--resume <id>` when that transcript is still resumable *from
that pane's current directory*. Renaming a repo moves its transcript's
project key, so an unresolvable id degrades to a plain
`claude --dangerously-skip-permissions` instead of a pane that fails every
restore with "No conversation found."

## No kill-window

Every single keystroke that can destroy an entire tab's worth of panes at
once is unbound: `X` (kill-window), the `&` confirm-kill default, and the
Kill and Respawn entries in the window menu. That menu is reachable both
from `prefix + <` and from right-clicking a tab in the status bar
(`tmux.conf`: `unbind X`, `unbind &`, and the two custom `display-menu`
bindings that rebuild the window menu without those two entries). `Ctrl+w`
closes one pane at a time, and only takes the tab with it when it was the
last pane left.

There is no remaining way to close a multi-pane tab in one step — closing it
always means closing its panes one at a time.

## No priority raising

Nothing that runs inside tmux can raise its own CPU priority. The config
caps the tmux server's nice limit at a floor of 0 the moment the server
starts, and every pane and everything a pane launches inherits it. A
browser an agent session opens therefore cannot put itself above the
services running beside it, which Chrome otherwise does by default. Lowering
a process's priority still works, and programs started outside tmux (audio,
the desktop, games) keep the wider limit they need.

## Socket recovery

`bin/tmux-socket-recover` brings a tmux server's socket back after its file
(or its whole directory, e.g. a `/tmp` sweep) disappears. It works around a
tmux bug (3.5a and 3.6b, fixed upstream in 3.8) where a `SIGUSR1` sent while
the socket *directory* is missing leaves the server's umask stuck wrong for
the rest of its life; see [contributing.md](contributing.md#architecture)
for where that bug lives. It recreates the directory with mode 0700 first,
signals the server only once the socket is actually confirmed gone, and
then checks the resulting umask against `$TMUX_EXPECTED_UMASK` (default
`0002`, systemd `--user`'s own), printing an in-place `gdb` fix if it is
wrong. Run read-only with `--check`, which exits 1 on a mismatch. On hokon,
the host's cron-manager runs it every 15 minutes as
`ops:tmux-umask-check`, so a mismatch is a failed job in the execution log
rather than a desktop notification nobody on SSH would see.

It never kills, restarts, or otherwise touches a server whose socket is
already present and answering.

## Trivia

The directory-rename feature exists because of one specific annoyance: every
tab in a terminal full of Claude Code panes used to read `claude`, with no
way to tell them apart at a glance (`032e75f`).

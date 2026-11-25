# Contributing

## Running it locally

```sh
git clone https://github.com/WolffM/tmux-config ~/repos/tmux-config
~/repos/tmux-config/install.sh
```

`install.sh` is also the upgrade path — re-run it after pulling to pick up a
config or script change. It:

1. Symlinks `~/.tmux.conf` to `tmux.conf` in the clone (backing up any real
   file that was there once).
2. Clones TPM, `tmux-resurrect` and `tmux-continuum` under
   `~/.tmux/plugins/` if they are not already there.
3. Symlinks every script in `bin/` into `~/.local/bin/` and the unit files in
   `systemd/` into `~/.config/systemd/user/`, then enables
   `claude-tmux-restore.service`. It also removes the
   `tmux-umask-check` links an older install left behind.
4. Reloads a running tmux server's config in place, if one is up.

Wayland clipboard support needs `wl-clipboard` (`sudo apt install
wl-clipboard`) — without it the mouse-drag-to-copy bindings have nothing to
call.

## Architecture

There is no build and no package: every file here is either tmux's own
config format or a shell script, used directly from the clone (via symlink)
or copied into a systemd unit's `ExecStart`.

- `tmux.conf` — the keymap, status bar, mouse bindings, and the three
  `tmux-resurrect`/`tmux-continuum` plugin settings that connect it to the
  restore utility below. `set-titles`/`set-titles-string "#I: #W"` also
  pushes the active window's index and name out to the surrounding
  terminal's own window title, not just tmux's status bar.
- `bin/claude-tmux-session-hook` — runs as `tmux-resurrect`'s
  `@resurrect-hook-post-save-layout` hook, on every autosave, and runs
  BEFORE resurrect's own dedup step (`save.sh:246`) so a stable layout
  still collapses to one state file rather than one per hook run. Resolves
  each Claude Code pane's session id and rewrites its saved restore
  command; see [features.md](features.md#claude-session-restore).
- `bin/claude-tmux-restore-core` — the actual restore, shared by the two
  entry points below. Bootstraps a throwaway session first so
  `tmux-resurrect` is free to create every saved session itself, then polls
  until the pane count settles instead of a fixed sleep.
- `bin/claude-session [name]` — interactive entry point: restore once if
  nothing is running yet, then attach.
- `bin/claude-tmux-boot-restore` — the same restore, headless, for
  `systemd/claude-tmux-restore.service` (`After=plasma-workspace.target`,
  so it runs once at the end of graphical login, not at raw boot).
- `bin/tmux-socket-recover` — independent of the restore path above; see
  [features.md](features.md#socket-recovery). Its `--check` mode runs every
  15 minutes on hokon as the cron-manager's `ops:tmux-umask-check` job. The bug it works around is in
  tmux's own `server.c` (around lines 125-135 in the 3.5a/3.6b source): a
  `SIGUSR1` handler sets umask `0117` around its `bind()` call and, if that
  `bind()` fails (the socket directory is missing), returns without
  restoring it — so the server keeps umask `0117` for the rest of its
  life, and every directory a pane creates afterward has no execute bit,
  fixed upstream in 3.8.

## Tests and gates

None. This is a personal dotfiles repo with no CI configured — changes are
verified by hand, against a running tmux session.

## Deploying

There is no deploy: a change lands by pulling into `~/repos/tmux-config` and
re-running `install.sh`, which re-links everything and reloads a running
server's config.

## Trivia

The restore utility's first two bin scripts and its systemd service all
landed in one commit, `6eb63fc`, the second commit in the repo's history;
the two scripts that actually do the shared restore work,
`claude-tmux-restore-core` and `claude-session`, didn't arrive until
`9c78ccb`, eleven days later.

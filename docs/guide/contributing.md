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
   `claude-tmux-restore.service` and `tmux-umask-check.timer`.
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
  restore utility below.
- `bin/claude-tmux-session-hook` — runs as `tmux-resurrect`'s
  `@resurrect-hook-post-save-layout` hook, on every autosave. Resolves each
  Claude Code pane's session id and rewrites its saved restore command; see
  [features.md](features.md#claude-session-restore).
- `bin/claude-tmux-restore-core` — the actual restore, shared by the two
  entry points below. Bootstraps a throwaway session first so
  `tmux-resurrect` is free to create every saved session itself, then polls
  until the pane count settles instead of a fixed sleep.
- `bin/claude-session [name]` — interactive entry point: restore once if
  nothing is running yet, then attach.
- `bin/claude-tmux-boot-restore` — the same restore, headless, for
  `systemd/claude-tmux-restore.service` (runs once at the end of graphical
  login).
- `bin/tmux-socket-recover` — independent of the restore path above; see
  [features.md](features.md#socket-recovery). `systemd/tmux-umask-check.{service,timer}`
  run its `--check` mode every 15 minutes.

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

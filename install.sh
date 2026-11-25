#!/usr/bin/env bash
# Symlink ~/.tmux.conf to this repo and install TPM + plugins.
set -euo pipefail
here="$(cd "$(dirname "$0")" && pwd)"

# 1) symlink the config (back up any existing real file once)
if [ -e "$HOME/.tmux.conf" ] && [ ! -L "$HOME/.tmux.conf" ]; then
  mv "$HOME/.tmux.conf" "$HOME/.tmux.conf.bak.$(date +%s)"
fi
ln -sfn "$here/tmux.conf" "$HOME/.tmux.conf"
echo "linked ~/.tmux.conf -> $here/tmux.conf"

# 2) TPM + plugins
P="$HOME/.tmux/plugins"
mkdir -p "$P"
clone() { [ -d "$P/$1" ] || git clone -q --depth 1 "https://github.com/tmux-plugins/$1" "$P/$1"; }
clone tpm
clone tmux-resurrect
clone tmux-continuum
echo "plugins installed under $P"

# 3) session-restore utility: bin scripts + systemd user service
#    - claude-tmux-session-hook : resurrect post-save hook, rewrites each claude
#      pane to `claude --resume <sessionId>` so restores skip the picker.
#    - claude-tmux-restore-core : the actual restore, shared by both entry points.
#    - claude-tmux-boot-restore : headless one-shot restore (systemd).
#    - claude-session [name]    : attach, restoring first if not yet up.
#    - claude-tmux-restore.service : runs the boot restore at the end of login.
mkdir -p "$HOME/.local/bin" "$HOME/.config/systemd/user"
# claude-session used to be an untracked real file in ~/.local/bin; retire it.
if [ -e "$HOME/.local/bin/claude-session" ] && [ ! -L "$HOME/.local/bin/claude-session" ]; then
  mv "$HOME/.local/bin/claude-session" "$HOME/.local/bin/claude-session.bak.$(date +%s)"
fi
ln -sfn "$here/bin/claude-tmux-session-hook"        "$HOME/.local/bin/claude-tmux-session-hook"
ln -sfn "$here/bin/claude-tmux-restore-core"        "$HOME/.local/bin/claude-tmux-restore-core"
ln -sfn "$here/bin/claude-tmux-boot-restore"        "$HOME/.local/bin/claude-tmux-boot-restore"
ln -sfn "$here/bin/claude-session"                  "$HOME/.local/bin/claude-session"
ln -sfn "$here/systemd/claude-tmux-restore.service" "$HOME/.config/systemd/user/claude-tmux-restore.service"
echo "linked session-restore utility (bin + systemd unit)"
#    - tmux-socket-recover : bring a lost socket back without tmux 3.5a's
#      umask leak; --check warns if a server has it. On hokon the check is
#      scheduled by the host's cron-manager (ops:tmux-umask-check), which
#      replaced the timer this repo used to ship.
ln -sfn "$here/bin/tmux-socket-recover"             "$HOME/.local/bin/tmux-socket-recover"
echo "linked tmux-socket-recover"
#    - memtriage : reclaim RAM from idle claude sessions by writing their scope's
#      memory.reclaim, never by killing them. On hokon `park` is started by the
#      host's cron-manager when the user manager's memory pressure rises
#      (ops:memtriage-park). It used to be an untracked file in ~/.local/bin.
if [ -e "$HOME/.local/bin/memtriage" ] && [ ! -L "$HOME/.local/bin/memtriage" ]; then
  mv "$HOME/.local/bin/memtriage" "$HOME/.local/bin/memtriage.bak.$(date +%s)"
fi
ln -sfn "$here/bin/memtriage"                       "$HOME/.local/bin/memtriage"
echo "linked memtriage"
if command -v systemctl >/dev/null; then
  # An older install linked tmux-umask-check.{service,timer}; their targets
  # are gone, so drop the dangling links and the enablement with them.
  for unit in tmux-umask-check.timer tmux-umask-check.service; do
    link="$HOME/.config/systemd/user/$unit"
    if [ -L "$link" ] && [ ! -e "$link" ]; then
      systemctl --user disable "$unit" >/dev/null 2>&1 || true
      rm -f "$link"
      echo "removed stale $unit"
    fi
  done
  systemctl --user daemon-reload
  systemctl --user enable claude-tmux-restore.service >/dev/null 2>&1 \
    && echo "enabled claude-tmux-restore.service (headless restore at login)"
fi

# 4) reload if a server is running
if command -v tmux >/dev/null && tmux info >/dev/null 2>&1; then
  tmux source-file "$HOME/.tmux.conf" && echo "reloaded running tmux"
fi
echo "done. (Wayland clipboard needs: sudo apt install wl-clipboard)"

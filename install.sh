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
#    - claude-session           : attach, restoring first if not yet up.
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
if command -v systemctl >/dev/null; then
  systemctl --user daemon-reload
  systemctl --user enable claude-tmux-restore.service >/dev/null 2>&1 \
    && echo "enabled claude-tmux-restore.service (headless restore at login)"
fi

# 4) reload if a server is running
if command -v tmux >/dev/null && tmux info >/dev/null 2>&1; then
  tmux source-file "$HOME/.tmux.conf" && echo "reloaded running tmux"
fi
echo "done. (Wayland clipboard needs: sudo apt install wl-clipboard)"

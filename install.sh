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

# 3) reload if a server is running
if command -v tmux >/dev/null && tmux info >/dev/null 2>&1; then
  tmux source-file "$HOME/.tmux.conf" && echo "reloaded running tmux"
fi
echo "done. (Wayland clipboard needs: sudo apt install wl-clipboard)"

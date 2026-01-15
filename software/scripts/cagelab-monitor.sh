#!/usr/bin/env zsh
# a script to launch the cage lab monitor tmuxp session

if [[ ! -f $HOME/.config/tmuxp/cagelab-monitor.yaml ]]; then
	echo "CageLab monitor tmuxp config not found, creating symlink..."
	ln -sfv $HOME/Code/Setup/config/cagelab-monitor.yaml $HOME/.config/tmuxp/cagelab-monitor.yaml
fi

tmuxp load $HOME/.config/tmuxp/cagelab-monitor.yaml
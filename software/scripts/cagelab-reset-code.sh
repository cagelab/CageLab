#!/usr/bin/env zsh

# force reset submodules to the latest commit on their configured remote branch
resetSubmodules() {
	git submodule sync --recursive
	git submodule update --init --recursive --remote --force
	git submodule foreach --recursive 'git clean -fdx'
}

ul=(~/Code/Psychtoolbox ~/Code/opticka ~/Code/CageLab ~/Code/Setup ~/Code/matmoteGO ~/Code/PTBSimia ~/Code/matlab-jzmq ~/Code/PacmanTask ~/.dotfiles)

for dir in $ul; do
	if [[ -d $dir && -d $dir/.git ]]; then
		echo ">>> Resetting $dir"
		pushd $dir >/dev/null
		git fetch --all --prune
		upstream=$(git rev-parse --abbrev-ref --symbolic-full-name @{u} 2>/dev/null)
		if [[ -n $upstream ]]; then
			git reset --hard $upstream
		else
			git reset --hard
		fi
		git clean -fdx
		git pull --force --all --prune
		if [[ -f .gitmodules ]]; then
			resetSubmodules
		fi
		popd >/dev/null
	else
		echo ">>> Skipping $dir (not a git repo)"
	fi
done


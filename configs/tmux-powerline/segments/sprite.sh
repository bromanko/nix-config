#!/usr/bin/env bash
# Displays sprite name if in a sprite, otherwise hidden

run_segment() {
	local sprite_name
	sprite_name=$(tmux show-options -pqv @pane_sprite 2>/dev/null)

	if [[ -n "$sprite_name" ]]; then
		echo "󱐋 ${sprite_name}"
	fi
	# Return nothing if not in a sprite (segment hidden)
}

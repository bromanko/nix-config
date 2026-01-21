#!/usr/bin/env bash
# Displays hostname only when NOT in a sprite

TMUX_POWERLINE_SEG_HOSTNAME_NOT_SPRITE_FORMAT="${TMUX_POWERLINE_SEG_HOSTNAME_NOT_SPRITE_FORMAT:-short}"

generate_segmentrc() {
	read -r -d '' rccontents <<EORC
# Use short or long format for the hostname. Can be {"short, long"}.
export TMUX_POWERLINE_SEG_HOSTNAME_NOT_SPRITE_FORMAT="${TMUX_POWERLINE_SEG_HOSTNAME_NOT_SPRITE_FORMAT}"
EORC
	echo "$rccontents"
}

run_segment() {
	local sprite_name
	sprite_name=$(tmux show-options -pqv @pane_sprite 2>/dev/null)

	# Only show hostname if NOT in a sprite
	if [[ -z "$sprite_name" ]]; then
		if [[ "${TMUX_POWERLINE_SEG_HOSTNAME_NOT_SPRITE_FORMAT}" == "short" ]]; then
			hostname -s
		else
			hostname -f
		fi
	fi
	# Return nothing if in a sprite (segment hidden)
}

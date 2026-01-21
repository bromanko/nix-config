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

is_in_sprite() {
	local pane_pid
	pane_pid=$(tmux display-message -p '#{pane_pid}')

	# Search all sprite processes and check if they're descendants of our pane
	local found
	found=$(ps -eo pid,command | grep -E 'sprite (exec|console|c|x)' | grep -v grep | awk '{print $1}' | while read pid; do
		local check_pid=$pid
		while [[ "$check_pid" -gt 1 ]]; do
			if [[ "$check_pid" == "$pane_pid" ]]; then
				echo "found"
				break
			fi
			check_pid=$(ps -o ppid= -p "$check_pid" 2>/dev/null | tr -d ' ')
		done
	done | head -1)

	[[ "$found" == "found" ]]
}

run_segment() {
	# Only show hostname if NOT in a sprite
	if ! is_in_sprite; then
		if [[ "${TMUX_POWERLINE_SEG_HOSTNAME_NOT_SPRITE_FORMAT}" == "short" ]]; then
			hostname -s
		else
			hostname -f
		fi
	fi
	# Return nothing if in a sprite (segment hidden)
}

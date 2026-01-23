#!/usr/bin/env bash
# Displays hostname only when NOT in a sprite or Lima VM

TMUX_POWERLINE_SEG_HOSTNAME_NOT_SPRITE_FORMAT="${TMUX_POWERLINE_SEG_HOSTNAME_NOT_SPRITE_FORMAT:-short}"

generate_segmentrc() {
	read -r -d '' rccontents <<EORC
# Use short or long format for the hostname. Can be {"short, long"}.
export TMUX_POWERLINE_SEG_HOSTNAME_NOT_SPRITE_FORMAT="${TMUX_POWERLINE_SEG_HOSTNAME_NOT_SPRITE_FORMAT}"
EORC
	echo "$rccontents"
}

# Check if a process matching the pattern is a descendant of the pane
is_descendant_of_pane() {
	local pattern="$1"
	local pane_pid
	pane_pid=$(tmux display-message -p '#{pane_pid}')

	local found
	found=$(ps -eo pid,command | grep -E "$pattern" | grep -v grep | awk '{print $1}' | while read pid; do
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

is_in_sprite() {
	is_descendant_of_pane 'sprite (exec|console|c|x)'
}

is_in_lima() {
	is_descendant_of_pane 'limactl shell'
}

run_segment() {
	# Only show hostname if NOT in a sprite or Lima VM
	if ! is_in_sprite && ! is_in_lima; then
		if [[ "${TMUX_POWERLINE_SEG_HOSTNAME_NOT_SPRITE_FORMAT}" == "short" ]]; then
			hostname -s
		else
			hostname -f
		fi
	fi
	# Return nothing if in a sprite or Lima VM (segment hidden)
}

#!/usr/bin/env bash
# Displays sprite name if current pane is running sprite command

get_sprite_name() {
	# Find sprite process running in current pane's process tree
	local pane_pid
	pane_pid=$(tmux display-message -p '#{pane_pid}')

	# Search all sprite processes and check if they're descendants of our pane
	local sprite_pid
	sprite_pid=$(ps -eo pid,command | grep -E 'sprite (exec|console|c|x)' | grep -v grep | awk '{print $1}' | while read pid; do
		# Check if this sprite process is a descendant of our pane
		local check_pid=$pid
		while [[ "$check_pid" -gt 1 ]]; do
			if [[ "$check_pid" == "$pane_pid" ]]; then
				echo "$pid"
				break
			fi
			check_pid=$(ps -o ppid= -p "$check_pid" 2>/dev/null | tr -d ' ')
		done
	done | head -1)

	if [[ -z "$sprite_pid" ]]; then
		return 1
	fi

	# First, try to get sprite name from command line arguments (-s or -sprite flag)
	local sprite_cmdline
	sprite_cmdline=$(ps -o command= -p "$sprite_pid" 2>/dev/null)

	if [[ -n "$sprite_cmdline" ]]; then
		local sprite_name
		# Match -s <name> or -sprite <name>
		sprite_name=$(echo "$sprite_cmdline" | grep -oE '(-s|-sprite) +[^ ]+' | head -1 | awk '{print $2}')
		if [[ -n "$sprite_name" ]]; then
			echo "$sprite_name"
			return 0
		fi
	fi

	# Fallback: get working directory and check for .sprite file
	local sprite_cwd
	sprite_cwd=$(lsof -p "$sprite_pid" 2>/dev/null | awk '/cwd/ {print $NF}')

	if [[ -n "$sprite_cwd" ]]; then
		local sprite_file="${sprite_cwd}/.sprite"
		if [[ -f "$sprite_file" ]]; then
			local sprite_name
			# Parse JSON to get sprite name (works with or without jq)
			if command -v jq &>/dev/null; then
				sprite_name=$(jq -r '.sprite // empty' "$sprite_file" 2>/dev/null)
			else
				sprite_name=$(grep -o '"sprite"[[:space:]]*:[[:space:]]*"[^"]*"' "$sprite_file" | sed 's/.*: *"\([^"]*\)".*/\1/')
			fi

			if [[ -n "$sprite_name" ]]; then
				echo "$sprite_name"
				return 0
			fi
		fi
	fi

	echo "sprite"
	return 0
}

run_segment() {
	local sprite_name
	sprite_name=$(get_sprite_name)

	if [[ -n "$sprite_name" ]]; then
		echo "󱐋 ${sprite_name}"
	fi
	# Return nothing if not in a sprite (segment hidden)
}

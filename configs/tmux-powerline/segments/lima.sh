#!/usr/bin/env bash
# Displays Lima VM name if current pane is running in a Lima VM connection
# Detects: limactl shell, limassh, or direct ssh via Lima's ssh.config

get_lima_name() {
	local pane_pid
	pane_pid=$(tmux display-message -p '#{pane_pid}')

	# Search for Lima-related processes that are descendants of our pane.
	# Matches: "limactl shell", or "ssh -F .../.lima/.../ssh.config"
	local lima_pid lima_cmdline
	read -r lima_pid lima_cmdline < <(ps -eo pid,command | grep -E 'limactl shell|ssh.*\.lima/.*ssh\.config' | grep -v grep | while IFS= read -r line; do
		local pid
		pid=$(echo "$line" | awk '{print $1}')
		# Walk up the process tree to check if it's a descendant of our pane
		local check_pid=$pid
		while [[ "$check_pid" -gt 1 ]]; do
			if [[ "$check_pid" == "$pane_pid" ]]; then
				echo "$line"
				break
			fi
			check_pid=$(ps -o ppid= -p "$check_pid" 2>/dev/null | tr -d ' ')
		done
	done | head -1)

	if [[ -z "$lima_pid" ]]; then
		return 1
	fi

	local vm_name
	if [[ "$lima_cmdline" == *"limactl shell"* ]]; then
		# limactl shell [options] <vm-name> [command...]
		vm_name=$(echo "$lima_cmdline" | \
			sed -E 's/.*limactl shell//' | \
			sed -E 's/--shell +[^ ]+//' | \
			sed -E 's/--workdir +[^ ]+//' | \
			sed -E 's/-w +[^ ]+//' | \
			awk '{for(i=1;i<=NF;i++) if($i !~ /^-/) {print $i; exit}}')
	else
		# ssh -F .../.lima/<instance>/ssh.config ...
		# Extract instance name from the config path
		vm_name=$(echo "$lima_cmdline" | grep -oE '\.lima/[^/]+/ssh\.config' | sed -E 's/\.lima\/(.+)\/ssh\.config/\1/')
	fi

	echo "${vm_name:-lima}"
	return 0
}

run_segment() {
	local vm_name
	vm_name=$(get_lima_name)

	if [[ -n "$vm_name" ]]; then
		echo " ${vm_name}"
	fi
	# Return nothing if not in a Lima VM (segment hidden)
}

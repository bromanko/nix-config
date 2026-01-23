#!/usr/bin/env bash
# Displays Lima VM name if current pane is running in a limactl shell

get_lima_name() {
	# Find limactl shell process running in current pane's process tree
	local pane_pid
	pane_pid=$(tmux display-message -p '#{pane_pid}')

	# Search all limactl shell processes and check if they're descendants of our pane
	local lima_pid
	lima_pid=$(ps -eo pid,command | grep 'limactl shell' | grep -v grep | awk '{print $1}' | while read pid; do
		# Check if this limactl process is a descendant of our pane
		local check_pid=$pid
		while [[ "$check_pid" -gt 1 ]]; do
			if [[ "$check_pid" == "$pane_pid" ]]; then
				echo "$pid"
				break
			fi
			check_pid=$(ps -o ppid= -p "$check_pid" 2>/dev/null | tr -d ' ')
		done
	done | head -1)

	if [[ -z "$lima_pid" ]]; then
		return 1
	fi

	# Get VM name from command line arguments
	local lima_cmdline
	lima_cmdline=$(ps -o command= -p "$lima_pid" 2>/dev/null)

	if [[ -n "$lima_cmdline" ]]; then
		local vm_name
		# Extract the VM name - format: limactl shell [options] <vm-name> [command...]
		# Remove "limactl shell" prefix, then remove flag arguments (--shell X, --workdir X, etc.)
		# The VM name is the first remaining non-flag argument
		vm_name=$(echo "$lima_cmdline" | \
			sed -E 's/.*limactl shell//' | \
			sed -E 's/--shell +[^ ]+//' | \
			sed -E 's/--workdir +[^ ]+//' | \
			sed -E 's/-w +[^ ]+//' | \
			awk '{for(i=1;i<=NF;i++) if($i !~ /^-/) {print $i; exit}}')
		if [[ -n "$vm_name" ]]; then
			echo "$vm_name"
			return 0
		fi
	fi

	echo "lima"
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

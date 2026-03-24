#!/usr/bin/env bash
# tmux-dashboard: Interactive session picker with VCS + agent status overview
#
# Shows all tmux sessions with:
#   - VCS (jj/git) working copy dirty status
#   - Agent (pi/claude) state indicators from window names
#   - Window count
#
# Preview pane shows detailed info for the selected session.
# Selecting a session switches the tmux client to it.
#
# VCS checks run asynchronously — the picker appears instantly and VCS
# status is filled in via fzf reload once the (parallel) checks finish.

set -euo pipefail

# ── Tunables ─────────────────────────────────────────────────────────────────
# Per-repo timeout (seconds) for VCS commands.  Keeps the picker responsive
# even when a repo is enormous (e.g. a large monorepo).
VCS_TIMEOUT=3

# ── Colors ───────────────────────────────────────────────────────────────────
GREEN='\033[32m'
YELLOW='\033[33m'
MAGENTA='\033[35m'
CYAN='\033[36m'
DIM='\033[2m'
BOLD='\033[1m'
RESET='\033[0m'

# ── Batch tmux data ─────────────────────────────────────────────────────────
# Fetch all session and window metadata in exactly two tmux calls, then build
# associative arrays so the list generators never fork per-session.

declare -A SESSION_WINCOUNT SESSION_PATH SESSION_AGENTS

load_tmux_data() {
  # 1. Sessions: name, window count, working directory
  while IFS='|' read -r name count path; do
    SESSION_WINCOUNT["$name"]="$count"
    SESSION_PATH["$name"]="$path"
  done < <(tmux list-sessions -F '#{session_name}|#{session_windows}|#{session_path}' 2>/dev/null)

  # 2. Windows: build per-session agent summary from window names
  local cur_session="" cur_summary=""
  while IFS='|' read -r sname wname; do
    if [[ "$sname" != "$cur_session" ]]; then
      [[ -n "$cur_session" ]] && SESSION_AGENTS["$cur_session"]="$cur_summary"
      cur_session="$sname"
      cur_summary=""
    fi
    if [[ "$wname" == *"✻"* ]]; then
      cur_summary+="${MAGENTA}✻${RESET} "
    elif [[ "$wname" == *'$'* ]]; then
      cur_summary+="${CYAN}\$${RESET} "
    elif [[ "$wname" == *"✎"* ]]; then
      cur_summary+="${YELLOW}✎${RESET} "
    elif [[ "$wname" == *"…"* ]]; then
      cur_summary+="${DIM}…${RESET} "
    elif [[ "$wname" == *"⌫"* ]]; then
      cur_summary+="${DIM}⌫${RESET} "
    elif [[ "$wname" == *"○"* ]]; then
      cur_summary+="${DIM}○${RESET} "
    elif [[ "$wname" == *"✓"* ]]; then
      cur_summary+="${GREEN}✓${RESET} "
    fi
  done < <(tmux list-windows -a -F '#{session_name}|#{window_name}' 2>/dev/null)
  [[ -n "$cur_session" ]] && SESSION_AGENTS["$cur_session"]="$cur_summary"
}

# ── Format a session line ───────────────────────────────────────────────────

format_session_line() {
  local session="$1" vcs="$2"
  local padded_name
  padded_name=$(printf '%-15s' "$session")

  echo -e "${session}\t${BOLD}${padded_name}${RESET}  ${vcs}  ${DIM}󰖯 ${SESSION_WINCOUNT[$session]:-0}${RESET}  ${SESSION_AGENTS[$session]:-}"
}

# ── VCS status detection ────────────────────────────────────────────────────

get_vcs_status() {
  local path="$1"

  if [[ -d "$path/.jj" ]]; then
    local full_status rc=0
    full_status=$(cd "$path" && timeout "$VCS_TIMEOUT" jj status --no-pager 2>/dev/null) || rc=$?

    if [[ "$rc" -eq 124 ]]; then
      echo -e "${DIM}jj ⏳${RESET}"
    else
      local status_line
      status_line=$(head -1 <<< "$full_status")
      if [[ "$status_line" == *"no changes"* ]]; then
        echo -e "${GREEN}jj ✓${RESET}"
      else
        echo -e "${YELLOW}jj ●${RESET}"
      fi
    fi
  elif [[ -d "$path/.git" ]]; then
    local porcelain rc=0
    porcelain=$(cd "$path" && timeout "$VCS_TIMEOUT" git status --porcelain 2>/dev/null) || rc=$?

    if [[ "$rc" -eq 124 ]]; then
      echo -e "${DIM}git ⏳${RESET}"
    elif [[ -z "$porcelain" ]]; then
      echo -e "${GREEN}git ✓${RESET}"
    else
      echo -e "${YELLOW}git ●${RESET}"
    fi
  else
    echo -e "${DIM}—${RESET}"
  fi
}

# ── Session list: quick (no VCS) ────────────────────────────────────────────

generate_list_quick() {
  load_tmux_data

  local session
  for session in $(echo "${!SESSION_WINCOUNT[@]}" | tr ' ' '\n' | sort); do
    format_session_line "$session" "${DIM}…${RESET}"
  done
}

# ── Session list: full (parallel VCS with timeouts) ─────────────────────────

generate_list_full() {
  load_tmux_data

  local tmpdir
  tmpdir=$(mktemp -d)
  # shellcheck disable=SC2064
  trap "rm -rf '$tmpdir'" RETURN

  # Launch VCS checks in parallel — each writes its result to a temp file
  local -a sessions=()
  local session
  for session in $(echo "${!SESSION_WINCOUNT[@]}" | tr ' ' '\n' | sort); do
    sessions+=("$session")
    ( get_vcs_status "${SESSION_PATH[$session]}" > "$tmpdir/$session" ) &
  done

  # Wait for all parallel VCS checks to finish
  wait

  # Emit lines in the same order (fzf preserves cursor position on reload)
  for session in "${sessions[@]}"; do
    local vcs
    vcs=$(cat "$tmpdir/$session" 2>/dev/null) || vcs=$(echo -e "${DIM}—${RESET}")
    format_session_line "$session" "$vcs"
  done
}

# ── Preview generation (called with --preview) ─────────────────────────────

generate_preview() {
  local session="$1"
  local path
  path=$(tmux display-message -t "$session" -p '#{session_path}' 2>/dev/null)

  echo -e "${BOLD}📂 ${path}${RESET}"
  echo ""

  # VCS detail
  if [[ -d "$path/.jj" ]]; then
    echo -e "${BOLD}VCS:${RESET} jujutsu"

    local full_status rc=0
    full_status=$(cd "$path" && timeout "$VCS_TIMEOUT" jj status --no-pager 2>/dev/null) || rc=$?

    if [[ "$rc" -eq 124 ]]; then
      echo -e "  ${DIM}⏳ Status timed out (large repo?)${RESET}"
    else
      local status_line
      status_line=$(head -1 <<< "$full_status")

      if [[ "$status_line" == *"no changes"* ]]; then
        echo -e "  ${GREEN}✓ Working copy clean${RESET}"
      else
        echo -e "  ${YELLOW}● Working copy has changes:${RESET}"
        local changes
        changes=$(grep -E '^[AMDR] ' <<< "$full_status") || true
        if [[ -n "$changes" ]]; then
          head -8 <<< "$changes" | while IFS= read -r line; do
            echo -e "    ${DIM}${line}${RESET}"
          done
          local change_count
          change_count=$(wc -l <<< "$changes" | tr -d ' ')
          if [[ "$change_count" -gt 8 ]]; then
            echo -e "    ${DIM}… and $((change_count - 8)) more${RESET}"
          fi
        fi
      fi

      # Show current change description and bookmarks (skip if status
      # already timed out — log will be equally slow).
      local log_info
      log_info=$(cd "$path" && timeout "$VCS_TIMEOUT" jj log --no-pager -r '@' --no-graph \
        -T 'separate(" ", bookmarks, if(description, description.first_line()))' \
        2>/dev/null) || true
      log_info=$(head -1 <<< "$log_info")
      if [[ -n "$log_info" ]]; then
        echo -e "  ${MAGENTA}⎇ ${log_info}${RESET}"
      fi
    fi
    echo ""

  elif [[ -d "$path/.git" ]]; then
    echo -e "${BOLD}VCS:${RESET} git"

    local branch
    branch=$(cd "$path" && timeout "$VCS_TIMEOUT" git branch --show-current 2>/dev/null) || true
    if [[ -n "$branch" ]]; then
      echo -e "  ${MAGENTA}⎇ ${branch}${RESET}"
    fi

    local porcelain rc=0
    porcelain=$(cd "$path" && timeout "$VCS_TIMEOUT" git status --porcelain 2>/dev/null) || rc=$?

    if [[ "$rc" -eq 124 ]]; then
      echo -e "  ${DIM}⏳ Status timed out (large repo?)${RESET}"
    elif [[ -z "$porcelain" ]]; then
      echo -e "  ${GREEN}✓ Working tree clean${RESET}"
    else
      local change_count
      change_count=$(wc -l <<< "$porcelain" | tr -d ' ')
      echo -e "  ${YELLOW}● Working tree has changes (${change_count} files):${RESET}"
      head -8 <<< "$porcelain" | while IFS= read -r line; do
        echo -e "    ${DIM}${line}${RESET}"
      done
      if [[ "$change_count" -gt 8 ]]; then
        echo -e "    ${DIM}… and $((change_count - 8)) more${RESET}"
      fi
    fi
    echo ""
  fi

  # Windows detail
  echo -e "${BOLD}Windows:${RESET}"
  tmux list-windows -t "$session" \
    -F '#{window_index}|#{window_name}|#{window_active}|#{window_panes}' 2>/dev/null |
    while IFS='|' read -r idx name active panes; do
      local marker=""
      if [[ "$active" == "1" ]]; then
        marker=" ${CYAN}← active${RESET}"
      fi

      # Window type icon
      local type_icon=""
      case "$name" in
        pi*|*π*) type_icon="🤖" ;;
        claude*) type_icon="🤖" ;;
        jjui*) type_icon="📊" ;;
        nvim*|vim*) type_icon="📝" ;;
        make*|cargo*|npm*) type_icon="🔨" ;;
        *) type_icon="🐚" ;;
      esac

      local pane_info=""
      if [[ "$panes" -gt 1 ]]; then
        pane_info=" ${DIM}(${panes} panes)${RESET}"
      fi

      echo -e "  ${type_icon} ${BOLD}${idx}:${RESET} ${name}${pane_info}${marker}"
    done
}

# ── Main ────────────────────────────────────────────────────────────────────

main() {
  # Sub-commands used by fzf callbacks
  case "${1:-}" in
    --preview)
      generate_preview "${2:-}"
      exit 0
      ;;
    --full-list)
      generate_list_full
      exit 0
      ;;
  esac

  local self
  self=$(realpath "$0")

  local selected
  selected=$(
    generate_list_quick | fzf --ansi \
      --delimiter='\t' \
      --with-nth=2.. \
      --preview="$self --preview {1}" \
      --preview-window=right:50%:wrap \
      --header='enter: switch session  esc: cancel' \
      --no-sort \
      --cycle \
      --layout=reverse \
      --border=rounded \
      --border-label=' Sessions ' \
      --border-label-pos=2 \
      --margin=0 \
      --padding=0 \
      --color='header:italic:dim' \
      --bind "start:reload:$self --full-list" \
    || true
  )

  # Extract clean session name (first field before tab)
  local session_name
  session_name=$(cut -f1 <<< "$selected")

  if [[ -n "$session_name" ]]; then
    tmux switch-client -t "$session_name"
  fi
}

main "$@"

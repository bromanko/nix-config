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

set -euo pipefail

# ── Colors ───────────────────────────────────────────────────────────────────
GREEN='\033[32m'
YELLOW='\033[33m'
MAGENTA='\033[35m'
CYAN='\033[36m'
DIM='\033[2m'
BOLD='\033[1m'
RESET='\033[0m'

# ── VCS status detection ────────────────────────────────────────────────────

get_vcs_status() {
  local path="$1"

  if [[ -d "$path/.jj" ]]; then
    local full_status
    full_status=$(cd "$path" && jj status --no-pager 2>/dev/null) || true
    local status_line
    status_line=$(head -1 <<< "$full_status")

    if [[ "$status_line" == *"no changes"* ]]; then
      echo -e "${GREEN}jj ✓${RESET}"
    else
      echo -e "${YELLOW}jj ●${RESET}"
    fi
  elif [[ -d "$path/.git" ]]; then
    local porcelain
    porcelain=$(cd "$path" && git status --porcelain 2>/dev/null) || true
    if [[ -z "$porcelain" ]]; then
      echo -e "${GREEN}git ✓${RESET}"
    else
      echo -e "${YELLOW}git ●${RESET}"
    fi
  else
    echo -e "${DIM}—${RESET}"
  fi
}

# ── Agent status from window names ──────────────────────────────────────────
# pi's tmux-titles extension appends status icons to window names:
#   ○ idle  ✻ thinking  $ bash  ✎ editing  … reading  ⌫ compacting  ✓ done

get_agent_summary() {
  local session="$1"
  local summary=""

  while IFS= read -r wname; do
    # Only look at pi/claude windows
    case "$wname" in
      pi*|claude*|*π*)
        if [[ "$wname" == *"✻"* ]]; then
          summary+="${MAGENTA}✻${RESET} "
        elif [[ "$wname" == *'$'* ]]; then
          summary+="${CYAN}\$${RESET} "
        elif [[ "$wname" == *"✎"* ]]; then
          summary+="${YELLOW}✎${RESET} "
        elif [[ "$wname" == *"…"* ]]; then
          summary+="${DIM}…${RESET} "
        elif [[ "$wname" == *"⌫"* ]]; then
          summary+="${DIM}⌫${RESET} "
        elif [[ "$wname" == *"○"* ]]; then
          summary+="${DIM}○${RESET} "
        elif [[ "$wname" == *"✓"* ]]; then
          summary+="${GREEN}✓${RESET} "
        else
          # Agent window with no recognized icon
          summary+="${DIM}?${RESET} "
        fi
        ;;
    esac
  done < <(tmux list-windows -t "$session" -F '#{window_name}' 2>/dev/null)

  echo -e "$summary"
}

# ── Session list generation ─────────────────────────────────────────────────

generate_list() {
  for session in $(tmux list-sessions -F '#{session_name}' | sort); do
    local path
    path=$(tmux display-message -t "$session" -p '#{session_path}' 2>/dev/null)

    local vcs
    vcs=$(get_vcs_status "$path")

    local agents
    agents=$(get_agent_summary "$session")

    local win_count
    win_count=$(tmux list-windows -t "$session" 2>/dev/null | wc -l | tr -d ' ')

    # Format: session_name<TAB>display_line
    # First field (before tab) is the clean session name for extraction.
    # Use printf with %s (not format vars) and pre-composed colored strings.
    local padded_name
    padded_name=$(printf '%-15s' "$session")
    echo -e "${session}\t${BOLD}${padded_name}${RESET}  ${vcs}  ${DIM}󰖯 ${win_count}${RESET}  ${agents}"
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

    local full_status
    full_status=$(cd "$path" && jj status --no-pager 2>/dev/null) || true
    local status_line
    status_line=$(head -1 <<< "$full_status")

    if [[ "$status_line" == *"no changes"* ]]; then
      echo -e "  ${GREEN}✓ Working copy clean${RESET}"
    else
      echo -e "  ${YELLOW}● Working copy has changes:${RESET}"
      # Show only file change lines (A/M/D/R prefix)
      local changes
      changes=$(grep -E '^[AMDR] ' <<< "$full_status") || true
      if [[ -n "$changes" ]]; then
        head -8 <<< "$changes" | while IFS= read -r line; do
          echo -e "    ${DIM}${line}${RESET}"
        done
        # Show count if there are more
        local change_count
        change_count=$(wc -l <<< "$changes" | tr -d ' ')
        if [[ "$change_count" -gt 8 ]]; then
          echo -e "    ${DIM}… and $((change_count - 8)) more${RESET}"
        fi
      fi
    fi

    # Show current change description and bookmarks
    local log_info
    log_info=$(cd "$path" && jj log --no-pager -r '@' --no-graph \
      -T 'separate(" ", bookmarks, if(description, description.first_line()))' \
      2>/dev/null) || true
    log_info=$(head -1 <<< "$log_info")
    if [[ -n "$log_info" ]]; then
      echo -e "  ${MAGENTA}⎇ ${log_info}${RESET}"
    fi
    echo ""

  elif [[ -d "$path/.git" ]]; then
    echo -e "${BOLD}VCS:${RESET} git"

    local branch
    branch=$(cd "$path" && git branch --show-current 2>/dev/null) || true
    if [[ -n "$branch" ]]; then
      echo -e "  ${MAGENTA}⎇ ${branch}${RESET}"
    fi

    local porcelain
    porcelain=$(cd "$path" && git status --porcelain 2>/dev/null) || true
    if [[ -z "$porcelain" ]]; then
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
  # If called with --preview, generate preview for the given session
  if [[ "${1:-}" == "--preview" ]]; then
    generate_preview "${2:-}"
    exit 0
  fi

  local self
  self=$(realpath "$0")

  local selected
  selected=$(
    generate_list | fzf --ansi \
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

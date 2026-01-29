# shellcheck shell=bash disable=SC2034
####################################################################################################

# --> Catppuccin (Mocha)

rosewater="#f5e0dc"
flamingo="#f2cdcd"
pink="#f5c2e7"
mauve="#cba6f7"
red="#f38ba8"
maroon="#eba0ac"
peach="#fab387"
yellow="#f9e2af"
green="#a6e3a1"
teal="#94e2d5"
sky="#89dceb"
sapphire="#74c7ec"
blue="#89b4fa"
lavender="#b4befe"
text="#cdd6f4"
subtext1="#bac2de"
subtext0="#a6adc8"
overlay2="#9399b2"
overlay1="#7f849c"
overlay0="#6c7086"
surface2="#585b70"
surface1="#45475a"
surface0="#313244"
base="#1e1e2e"
mantle="#181825"
crust="#11111b"

TMUX_POWERLINE_SEPARATOR_LEFT_BOLD=""
TMUX_POWERLINE_SEPARATOR_LEFT_THIN=""
TMUX_POWERLINE_SEPARATOR_RIGHT_BOLD=""
TMUX_POWERLINE_SEPARATOR_RIGHT_THIN=""
TMUX_POWERLINE_SEPARATOR_THIN="|"

# See Color formatting section below for details on what colors can be used here.
TMUX_POWERLINE_DEFAULT_BACKGROUND_COLOR=${TMUX_POWERLINE_DEFAULT_BACKGROUND_COLOR:-$base}
TMUX_POWERLINE_DEFAULT_FOREGROUND_COLOR=${TMUX_POWERLINE_DEFAULT_FOREGROUND_COLOR:-$text}

TMUX_POWERLINE_DEFAULT_LEFTSIDE_SEPARATOR=${TMUX_POWERLINE_DEFAULT_LEFTSIDE_SEPARATOR:-$TMUX_POWERLINE_SEPARATOR_RIGHT_BOLD}
TMUX_POWERLINE_DEFAULT_RIGHTSIDE_SEPARATOR=${TMUX_POWERLINE_DEFAULT_RIGHTSIDE_SEPARATOR:-$TMUX_POWERLINE_SEPARATOR_LEFT_BOLD}

# See `man tmux` for additional formatting options for the status line.
# The `format regular` and `format inverse` functions are provided as conveinences

# shellcheck disable=SC2128
if [ -z "$TMUX_POWERLINE_WINDOW_STATUS_CURRENT" ]; then
	TMUX_POWERLINE_WINDOW_STATUS_CURRENT=(
		"#[$(format regular)]"
		"$TMUX_POWERLINE_DEFAULT_RIGHTSIDE_SEPARATOR"
		"#[$(format inverse)]"
		" #I#{?window_zoomed_flag, 󰁌,} "
		"$TMUX_POWERLINE_SEPARATOR_THIN"
		" #W "
		"#[$(format regular)]"
		"$TMUX_POWERLINE_DEFAULT_LEFTSIDE_SEPARATOR"
	)
fi

# shellcheck disable=SC2128
if [ -z "$TMUX_POWERLINE_WINDOW_STATUS_STYLE" ]; then
	TMUX_POWERLINE_WINDOW_STATUS_STYLE=(
		"$(format regular)"
	)
fi

# shellcheck disable=SC2128
if [ -z "$TMUX_POWERLINE_WINDOW_STATUS_FORMAT" ]; then
	TMUX_POWERLINE_WINDOW_STATUS_FORMAT=(
		"#[$(format regular)]"
		"  #I#{?window_last_flag, #[fg=${yellow}]←#[$(format regular)],}#{?window_activity_flag, 󱐋,}#{?window_bell_flag, 󰂟,}#{?window_zoomed_flag, 󰁌,} "
		"$TMUX_POWERLINE_SEPARATOR_THIN"
		" #W "
	)
fi

# Format: segment_name [background_color|default_bg_color] [foreground_color|default_fg_color] [non_default_separator|default_separator] [separator_background_color|no_sep_bg_color]
#                      [separator_foreground_color|no_sep_fg_color] [spacing_disable|no_spacing_disable] [separator_disable|no_separator_disable]
#
# * background_color and foreground_color. Color formatting (see `man tmux` for complete list):
#   * Named colors, e.g. black, red, green, yellow, blue, magenta, cyan, white
#   * Hexadecimal RGB string e.g. #ffffff
#   * 'default_fg_color|default_bg_color' for the default theme bg and fg color
#   * 'default' for the default tmux color.
#   * 'terminal' for the terminal's default background/foreground color
#   * The numbers 0-255 for the 256-color palette. Run `tmux-powerline/color-palette.sh` to see the colors.
# * non_default_separator - specify an alternative character for this segment's separator
#   * 'default_separator' for the theme default separator
# * separator_background_color - specify a unique background color for the separator
#   * 'no_sep_bg_color' for using the default coloring for the separator
# * separator_foreground_color - specify a unique foreground color for the separator
#   * 'no_sep_fg_color' for using the default coloring for the separator
# * spacing_disable - remove space on left, right or both sides of the segment:
#   * "no_spacing_disable" - don't disable spacing (default)
#   * "left_disable" - disable space on the left
#   * "right_disable" - disable space on the right
#   * "both_disable" - disable spaces on both sides
#
# * separator_disable - disables drawing a separator on this segment, very useful for segments
#   with dynamic background colours (eg tmux_mem_cpu_load):
#   * "no_separator_disable" - don't disable the separator (default)
#   * "separator_disable" - disables the separator
#
# Example segment with separator disabled and right space character disabled:
# "hostname 33 0 {TMUX_POWERLINE_SEPARATOR_RIGHT_BOLD} 0 0 right_disable separator_disable"
#
# Example segment with spacing characters disabled on both sides but not touching the default coloring:
# "hostname 33 0 {TMUX_POWERLINE_SEPARATOR_RIGHT_BOLD} no_sep_bg_color no_sep_fg_color both_disable"
#
# Example segment with changing the foreground color of the default separator:
# "hostname 33 0 default_separator no_sep_bg_color 120"
#
## Note that although redundant the non_default_separator, separator_background_color and
# separator_foreground_color options must still be specified so that appropriate index
# of options to support the spacing_disable and separator_disable features can be used.
# The default_* and no_* can be used to keep the default behaviour.

# shellcheck disable=SC1143,SC2128
if [ -z "$TMUX_POWERLINE_LEFT_STATUS_SEGMENTS" ]; then
	TMUX_POWERLINE_LEFT_STATUS_SEGMENTS=(
		"tmux_session_info $blue $base"
		"hostname_not_sprite $lavender $base"
		"sprite $green $base"
		"lima $peach $base"
		#"ifstat 30 255"
		#"ifstat_sys 30 255"
		#"lan_ip $sky $base"
		#"wan_ip $sky $base"
		#"vcs_branch $overlay2 $crust"
		#"air ${TMUX_POWERLINE_SEG_AIR_COLOR} $base"
		#"vcs_compare 60 255"
		#"vcs_staged 64 255"
		#"vcs_modified 9 255"
		#"vcs_others 245 0"
	)
fi

# shellcheck disable=SC1143,SC2128
if [ -z "$TMUX_POWERLINE_RIGHT_STATUS_SEGMENTS" ]; then
	TMUX_POWERLINE_RIGHT_STATUS_SEGMENTS=(
		# "earthquake 3 0"
		#"pwd $mauve $surface0"
		#"macos_notification_count 29 255"
		#"mailcount 9 255"
		#"now_playing $green $crust"
		#""cpu $rosewater $crust"
		#"load 237 167"
		#"tmux_mem_cpu_load 234 136"
		#""battery $blue $base"
		#"weather 37 255"
		#"rainbarf 0 ${TMUX_POWERLINE_DEFAULT_FOREGROUND_COLOR}"
		#"xkb_layout 125 117"
		#""date_day $teal $base"
		#""date $teal $base ${TMUX_POWERLINE_SEPARATOR_LEFT_THIN}"
		#""time $teal $base ${TMUX_POWERLINE_SEPARATOR_LEFT_THIN}"
		#"utc_time 235 136 ${TMUX_POWERLINE_SEPARATOR_LEFT_THIN}"
	)
fi

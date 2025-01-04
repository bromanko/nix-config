local wezterm = require 'wezterm'
local config = wezterm.config_builder()

-- font settings
config.font = wezterm.font('MonaspiceAr Nerd Font Mono', { weight = 'Light' })
config.font_size = 13

config.color_scheme = 'Catppuccin Mocha'

config.window_close_confirmation = 'NeverPrompt'

-- force renderer due to bug in latest version of Wezterm
-- see: https://github.com/wez/wezterm/issues/5990
config.front_end = "WebGpu"
config.webgpu_power_preference = 'HighPerformance'


return config

local wezterm = require 'wezterm'
local config = wezterm.config_builder()

-- font settings
config.font = wezterm.font('MonaspiceAr Nerd Font Mono', { weight = 'Light' })
config.font_size = 13

config.color_scheme = 'Catppuccin Mocha'

return config

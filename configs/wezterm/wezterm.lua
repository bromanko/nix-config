local function prequire(m)
  local ok, err = pcall(require, m)
  if not ok then return nil, err end
  return err
end

local wezterm = require 'wezterm'
local config = wezterm.config_builder()

-- font settings
config.font = wezterm.font('MonaspiceAr Nerd Font Mono', { weight = 'Light' })
config.font_size = 13

-- appearance
config.color_scheme = 'Catppuccin Mocha'
config.window_decorations = 'RESIZE'
config.window_frame = {
    font = wezterm.font({ family = 'SF UI Display'}),
    font_size = 15,
}
config.hide_tab_bar_if_only_one_tab = true
config.enable_scroll_bar = true


-- Load any configuration not managed by home-manager
-- This is useful for iterating on changes without having to rebuild the nix config
local overrides = prequire('overrides')
if overrides and overrides.apply_config then
  overrides.apply_config(config)
end

config.window_close_confirmation = 'NeverPrompt'

-- force renderer due to bug in latest version of Wezterm
-- see: https://github.com/wez/wezterm/issues/5990
config.front_end = "WebGpu"
config.webgpu_power_preference = 'HighPerformance'


return config

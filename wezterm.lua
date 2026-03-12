local wezterm = require 'wezterm'

return {
  default_prog = { 'C:/msys64/usr/bin/bash.exe', '--login' },
  default_cwd = 'C:/Users/Michael',
  set_environment_variables = {
    MSYSTEM = 'UCRT64',
    CHERE_INVOKING = '1',
  },
  font_size = 8,
  line_height = 1.0,
  window_padding = { left = 8, right = 8, top = 0, bottom = 0 },
  window_decorations = 'RESIZE',
  hide_tab_bar_if_only_one_tab = true,
  enable_scroll_bar = false,
}

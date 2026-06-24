local wezterm = require 'wezterm'

return {
  -- -use-full-path: inherit Windows PATH (Tailscale CLI, user tools, etc.)
  default_prog = {
    'C:/msys64/msys2_shell.cmd',
    '-defterm',
    '-here',
    '-no-start',
    '-ucrt64',
    '-use-full-path',
    '-shell',
    'bash',
  },
  default_cwd = wezterm.home_dir,
  font_size = 8,
  line_height = 1.0,
  window_padding = { left = 8, right = 8, top = 0, bottom = 0 },
  window_decorations = 'RESIZE',
  hide_tab_bar_if_only_one_tab = true,
  enable_scroll_bar = false,
}

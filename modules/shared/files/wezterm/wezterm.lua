local wezterm = require 'wezterm'
local config = wezterm.config_builder()

-- ==========================================
-- Environment Checks
-- ==========================================
local is_mac = wezterm.target_triple:find('darwin') ~= nil

-- ==========================================
-- 1. Font & Core UI
-- ==========================================
config.font = wezterm.font('Hack Nerd Font')
config.font_size = 13.0
config.window_decorations = "RESIZE" -- Removes the bulky macOS title bar
config.bold_brightens_ansi_colors = false
config.enable_scroll_bar = true

-- ==========================================
-- 2. Window Appearance (OS Specific)
-- ==========================================
if is_mac then
  config.macos_window_background_blur = 10
  config.window_background_opacity = 0.87
else
  -- Linux settings (less opacity to offset lack of blur)
  -- KDE has a blur option but it is so intense that it doesn't make sense to use
  config.window_background_opacity = 0.92
end

-- ==========================================
-- 3. Tabs & Window Frame
-- ==========================================
config.enable_tab_bar = true
config.use_fancy_tab_bar = true
config.hide_tab_bar_if_only_one_tab = false

-- Title bar background options (Frames the fancy tab bar)
-- local titlebar_bg = '#2E4224' -- Rich Moss
-- local titlebar_bg = '#6E5A2A' -- Antique Brass
-- local titlebar_bg = '#968841' -- Chalky Mustard
local titlebar_bg = '#2E4A7A' -- Steel Blue

config.window_frame = {
  active_titlebar_bg = titlebar_bg,
  inactive_titlebar_bg = titlebar_bg,
}

config.colors = {
  tab_bar = {
    -- Note: We intentionally omit the empty space 'background' color here
    -- because 'use_fancy_tab_bar = true' handles it via config.window_frame above.

    active_tab = {
      bg_color = '#C48DFF',
      fg_color = '#07042B',
    },
    inactive_tab = {
      bg_color = '#3A2653',
      fg_color = '#E3E3EA',
    },
    inactive_tab_hover = {
      bg_color = '#583B7D',
      fg_color = '#FFFFFF',
    },
  },
}

-- ==========================================
-- 4. Color Schemes
-- ==========================================
config.color_schemes = {
  ['Beanbag-iTerm2'] = {
    background = '#000000',
    foreground = '#E3E3EA',

    cursor_bg = '#FF7F7F',
    cursor_fg = '#07042B',
    cursor_border = '#FF7F7F',

    selection_bg = '#B5D5FF',
    selection_fg = '#000000',

    ansi = {
      '#000000', -- black
      '#BB0000', -- red
      '#55FF55', -- green  (Bright Neon Green)
      '#FFD75F', -- yellow
      '#5EA1FF', -- blue   (Sky Blue)
      '#BB00BB', -- magenta
      '#55FFFF', -- cyan   (Bright Neon Cyan)
      '#BBBBBB', -- white
    },
    brights = {
      '#555555', -- bright black
      '#FF5555', -- bright red
      '#55FF55', -- bright green
      '#FFFF55', -- bright yellow
      '#82AAFF', -- bright blue (Pastel Blue)
      '#FF55FF', -- bright magenta
      '#55FFFF', -- bright cyan
      '#FFFFFF', -- bright white
    },

    split = '#5EA1FF', -- Sky Blue from ansi color list above
    scrollbar_thumb = '#8A7A9B'
  },

  ['Beanbag-Mathias'] = {
    foreground = '#E3E3EA',
    background = '#07042B',

    cursor_bg = '#FF7F7F',
    cursor_fg = '#07042B',
    cursor_border = '#FF7F7F',

    selection_bg = '#7DF9FF',
    selection_fg = '#07042B',

    ansi = {
      '#000000', -- black
      '#E52222', -- red
      '#55FF55', -- green
      '#F0C040', -- yellow
      '#C48DFF', -- blue
      '#FA2573', -- magenta
      '#7DF9FF', -- cyan (Electric Ice)
      '#F2F2F2', -- white
    },
    brights = {
      '#555555', -- bright black
      '#FF5555', -- bright red
      '#55FF55', -- bright green
      '#FFFF55', -- bright yellow
      '#6CB6FF', -- bright blue (Icy Sky)
      '#FF55FF', -- bright magenta
      '#7DF9FF', -- bright cyan (Electric Ice)
      '#FFFFFF', -- bright white
    },

    split = '#6CB6FF', -- Icy Sky from brights color list above
    scrollbar_thumb = '#8A7A9B'
  },
}

-- Default Scheme
config.color_scheme = 'Beanbag-Mathias'

-- ==========================================
-- 5. Keybindings & Events
-- ==========================================
wezterm.on('set-scheme-iterm2', function(window)
  window:set_config_overrides({ color_scheme = 'Beanbag-iTerm2' })
end)

wezterm.on('set-scheme-mathias', function(window)
  window:set_config_overrides({ color_scheme = 'Beanbag-Mathias' })
end)

if is_mac then
  config.keys = {
    -- Use the same keybinds for splits as iTerm2
    { key = 'd', mods = 'CMD',       action = wezterm.action.SplitHorizontal { domain = 'CurrentPaneDomain' } },
    { key = 'd', mods = 'CMD|SHIFT', action = wezterm.action.SplitVertical   { domain = 'CurrentPaneDomain' } },
    -- scheme switching
    { key = '1', mods = 'CTRL|ALT',  action = wezterm.action.EmitEvent('set-scheme-iterm2') },
    { key = '2', mods = 'CTRL|ALT',  action = wezterm.action.EmitEvent('set-scheme-mathias') },
  }
else
  config.keys = {
    -- Linux equivalents using SUPER or CTRL|SHIFT
    { key = 'd', mods = 'SUPER',       action = wezterm.action.SplitHorizontal { domain = 'CurrentPaneDomain' } },
    { key = 'd', mods = 'SUPER|SHIFT', action = wezterm.action.SplitVertical   { domain = 'CurrentPaneDomain' } },
    { key = '1', mods = 'CTRL|ALT',    action = wezterm.action.EmitEvent('set-scheme-iterm2') },
    { key = '2', mods = 'CTRL|ALT',    action = wezterm.action.EmitEvent('set-scheme-mathias') },
  }
end

return config


local wezterm = require 'wezterm'

local launch_menu = {}
local default_prog = {}

if wezterm.target_triple == "x86_64-pc-windows-msvc" then
    table.insert(launch_menu, {
        label = 'Nushell',
        args = {'nu.exe'},
      })
    table.insert(launch_menu, {
        label = 'PowerShell',
        args = {'powershell.exe', '-NoLogo'},
    })

    default_prog = {'nu.exe'}
end

-- Title
function basename(s)
    return string.gsub(s, '(.*[/\\])(.*)', '%2')
end

wezterm.on('format-tab-title', function(tab, tabs, panes, config, hover, max_width)
    local pane = tab.active_pane

    local index = ""
    if #tabs > 1 then
        index = string.format("%d: ", tab.tab_index + 1)
    end

    local process = basename(pane.foreground_process_name)

    return {{
        Text = ' ' .. index .. process .. ' '
    }}
end)

wezterm.on('gui-startup', function(cmd)
    local tab, pane, window = wezterm.mux.spawn_window(cmd or {})
    window:gui_window():maximize()
end)

return {
    -- basic
    check_for_updates = false,
    enable_scroll_bar = true,
    launch_menu = launch_menu,
    default_prog = default_prog,
    -- Window
    native_macos_fullscreen_mode = true,
    adjust_window_size_when_changing_font_size = true,
    window_background_opacity = 0.9,
    window_padding = {
        left = 5,
        right = 5,
        top = 5,
        bottom = 5
    },
    -- Font
    font = wezterm.font_with_fallback {'Fira Code'},
    font_size = 16,
    normalize_to_nfc = false,
    -- Tab bar
    enable_tab_bar = true,
    hide_tab_bar_if_only_one_tab = false,
    show_tab_index_in_tab_bar = false,
    tab_bar_at_bottom = true,
    tab_max_width = 25,
    -- shortcuts
    keys = {
        { key = 'a', mods = 'ALT', action = wezterm.action.ShowLauncher },
    },
}
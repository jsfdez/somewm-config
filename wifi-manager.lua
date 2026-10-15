-- Wi-Fi status for a single wireless device, driven by nmcli.
-- Shows a signal-strength icon and the connected SSID in the bar; clicking opens nmtui.
--
-- Usage:
--   local wifi = require("wifi-manager").new("wlo1")
--   wibar_widget = wifi.widget
--   wifi.show()   -- open nmtui in a terminal
local awful = require("awful")
local wibox = require("wibox")
local gears = require("gears")
local beautiful = require("beautiful")

local dpi = beautiful.xresources.apply_dpi

local REFRESH_SECONDS = 30
local TERMINAL = "x-terminal-emulator"
local ICON_DIR = "/usr/share/icons/Cosmic/scalable/status/"

-- Icon per signal level, weakest to strongest
local SIGNAL_ICONS = {
    none      = "network-wireless-signal-none-symbolic.svg",
    weak      = "network-wireless-signal-weak-symbolic.svg",
    ok        = "network-wireless-signal-ok-symbolic.svg",
    good      = "network-wireless-signal-good-symbolic.svg",
    excellent = "network-wireless-signal-excellent-symbolic.svg",
}
local OFFLINE_ICON = "network-wireless-disconnected-symbolic.svg"

local wifi_manager = {}

-- nmcli -t escapes ':' and '\' with a backslash inside fields
local function split_terse(line)
    local fields, current, i = {}, {}, 1
    while i <= #line do
        local c = line:sub(i, i)
        if c == "\\" and i < #line then
            table.insert(current, line:sub(i + 1, i + 1))
            i = i + 2
        elseif c == ":" then
            table.insert(fields, table.concat(current))
            current = {}
            i = i + 1
        else
            table.insert(current, c)
            i = i + 1
        end
    end
    table.insert(fields, table.concat(current))
    return fields
end

-- Calls back with the connected SSID and its signal (0-100), or nil when not connected
local function active_network(device, callback)
    awful.spawn.easy_async({ "nmcli", "-t", "-f", "IN-USE,SSID,SIGNAL",
                             "device", "wifi", "list", "ifname", device },
        function(stdout)
            for line in stdout:gmatch("[^\n]+") do
                local f = split_terse(line)
                if f[1] == "*" then
                    callback(f[2], tonumber(f[3]) or 0)
                    return
                end
            end
            callback(nil)
        end)
end

local function level_for(signal)
    if signal >= 75 then return "excellent" end
    if signal >= 50 then return "good" end
    if signal >= 25 then return "ok" end
    if signal > 0 then return "weak" end
    return "none"
end

function wifi_manager.new(device)
    -- Icons are recolored to the theme foreground once, at creation
    local fg = beautiful.fg_normal
    local icons = {}
    for level, file in pairs(SIGNAL_ICONS) do
        icons[level] = gears.color.recolor_image(ICON_DIR .. file, fg)
    end
    icons.offline = gears.color.recolor_image(ICON_DIR .. OFFLINE_ICON, fg)

    local icon = wibox.widget.imagebox(icons.offline)
    local label = wibox.widget.textbox(" offline ")
    local widget = wibox.widget {
        icon,
        label,
        layout = wibox.layout.fixed.horizontal,
    }
    local self = { widget = widget, device = device }

    local function refresh()
        active_network(device, function(ssid, signal)
            if ssid and ssid ~= "" then
                icon:set_image(icons[level_for(signal)])
                label:set_text(" " .. ssid .. " ")
            else
                icon:set_image(icons.offline)
                label:set_text(" offline ")
            end
        end)
    end

    local function open_nmtui()
        awful.spawn({ TERMINAL, "-e", "nmtui" })
    end

    self.show = open_nmtui
    widget:buttons(gears.table.join(awful.button({}, 1, open_nmtui)))

    gears.timer {
        timeout = REFRESH_SECONDS,
        autostart = true,
        call_now = true,
        callback = refresh,
    }

    return self
end

return wifi_manager

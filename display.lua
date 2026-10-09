-- Display/monitor management
local awful = require("awful")

local display = {
    output = "eDP-1",
    width = 2880,
    height = 1800,
    scale = 1.25,
    refresh_rates = {
        { name = "60Hz", value = "60.000999Hz" },
        { name = "120Hz", value = "120.000000Hz" },
    },
    current_hz = "60.000999Hz",
}

function display.set_refresh(hz_number)
    -- Map number to full Hz value
    local hz_map = {
        [60] = "60.000999Hz",
        [120] = "120.000000Hz",
    }
    local hz = hz_map[hz_number] or hz_number or display.current_hz

    local cmd = string.format(
        "wlr-randr --output %s --mode %dx%d@%s --scale %.2f",
        display.output, display.width, display.height, hz, display.scale
    )
    awful.spawn(cmd)
    display.current_hz = hz
    naughty = require("naughty")
    naughty.notification {
        title = "Display",
        text = "Refresh rate set to: " .. hz,
        timeout = 2,
    }
end

function display.cycle_refresh()
    local next_hz
    if display.current_hz == "60.000999Hz" then
        next_hz = 120
    else
        next_hz = 60
    end
    display.set_refresh(next_hz)
end

-- Register keybinding to cycle refresh rates
local modkey = "Mod4"
awful.keyboard.append_global_keybindings({
    awful.key {
        modifiers   = { modkey, "Control" },
        key         = "f",
        on_press    = display.cycle_refresh,
        description = "cycle refresh rate (60Hz/120Hz)",
        group       = "display",
    },
})

return display

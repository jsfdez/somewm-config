-- Display/monitor management
local awful = require("awful")
local gears = require("gears")

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
    config_path = gears.filesystem.get_configuration_dir() .. "somewm_display.json",
}

function display.load_config()
    local f = io.open(display.config_path, "r")
    if f then
        local content = f:read("*a")
        f:close()
        -- Parse Lua table format
        local ok, config = pcall(function()
            return load("return " .. content)()
        end)
        if ok and config then
            if config.scale and type(config.scale) == "number" then
                display.scale = config.scale
            end
            if config.current_hz and type(config.current_hz) == "string" then
                display.current_hz = config.current_hz
            end
        else
            naughty = require("naughty")
            naughty.notification {
                title = "Display Config Error",
                text = "Failed to load display config: " .. tostring(config),
                timeout = 3,
            }
        end
    end
end

function display.save_config()
    local config = {
        scale = display.scale,
        current_hz = display.current_hz,
    }
    local f = io.open(display.config_path, "w")
    if f then
        local content = gears.string.xml_escape(string.format("{ scale = %.2f, current_hz = '%s' }", config.scale, config.current_hz))
        -- Write as Lua-readable format
        f:write(string.format("{ scale = %.2f, current_hz = '%s' }", config.scale, config.current_hz))
        f:close()
    end
end

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
    display.save_config()
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

function display.set_scale(percentage)
    -- Convert percentage (100, 125, 150, etc) to decimal (1.0, 1.25, 1.5, etc)
    local scale = percentage / 100

    local cmd = string.format(
        "wlr-randr --output %s --mode %dx%d@%s --scale %.2f",
        display.output, display.width, display.height, display.current_hz, scale
    )
    awful.spawn(cmd)
    display.scale = scale
    display.save_config()
    naughty = require("naughty")
    naughty.notification {
        title = "Display",
        text = "Scale set to: " .. percentage .. "%",
        timeout = 2,
    }
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

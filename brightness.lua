-- Brightness control widget
local awful = require("awful")
local wibox = require("wibox")
local gears = require("gears")
local naughty = require("naughty")

local brightness = {
    widget = wibox.widget.textbox(),
    current = 0,
}

function brightness.get()
    local handle = io.popen("brightnessctl get 2>/dev/null")
    local result = handle:read("*a")
    handle:close()

    if result and result ~= "" then
        local value = tonumber(result:match("(%d+)"))
        if value then
            local percentage = math.floor((value / 400) * 100)
            brightness.current = percentage
            return percentage
        end
    end
    return 0
end

function brightness.update()
    local level = brightness.get()
    brightness.widget:set_text("🔆 " .. level .. "%")
end

function brightness.increase()
    os.execute("sudo -n brightnessctl set +5%")
    gears.timer({
        timeout = 0.5,
        autostart = true,
        callback = function(timer)
            brightness.update()
            timer:stop()
        end,
    })
end

function brightness.decrease()
    os.execute("sudo -n brightnessctl set 5%-")
    gears.timer({
        timeout = 0.5,
        autostart = true,
        callback = function(timer)
            brightness.update()
            timer:stop()
        end,
    })
end

-- Update brightness display
brightness.update()

-- Setup mouse wheel bindings on the widget
brightness.widget:buttons(gears.table.join(
    awful.button({ }, 4, brightness.increase),   -- wheel up
    awful.button({ }, 5, brightness.decrease)    -- wheel down
))

-- Update periodically
gears.timer({
    timeout = 5,
    autostart = true,
    callback = brightness.update,
})

return brightness

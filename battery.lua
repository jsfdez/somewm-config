-- Battery status and power profile widget
local awful = require("awful")
local wibox = require("wibox")
local gears = require("gears")

local battery = {
    widget = wibox.widget.textbox(),
    percentage = 0,
    time_remaining = "N/A",
    profile = "unknown",
}

function battery.get_battery_info()
    local handle = io.popen('upower -i /org/freedesktop/UPower/devices/battery_BAT0 2>/dev/null')
    local result = handle:read("*a")
    handle:close()

    local percentage = result:match("percentage:%s+(%d+)")
    local hours_str = result:match("time to empty:%s+([%d,%.]+)%s+hours")

    local time_str = "N/A"
    if hours_str then
        hours_str = hours_str:gsub(",", ".")
        local hours_decimal = tonumber(hours_str)
        if hours_decimal then
            local hours = math.floor(hours_decimal)
            local minutes = math.floor((hours_decimal - hours) * 60)
            time_str = hours .. "h" .. minutes .. "m"
        end
    end

    if percentage then
        battery.percentage = tonumber(percentage)
        battery.time_remaining = time_str
        return true
    end
    return false
end

function battery.get_power_profile()
    local handle = io.popen('system76-power profile 2>/dev/null | head -1')
    local result = handle:read("*a")
    handle:close()

    if result:find("Battery") then
        battery.profile = "battery"
        return "🔋"
    elseif result:find("Performance") then
        battery.profile = "performance"
        return "🔥"
    elseif result:find("Balanced") then
        battery.profile = "balanced"
        return "⚡"
    end
    battery.profile = "unknown"
    return "❌"
end

function battery.update()
    battery.get_battery_info()
    local icon = battery.get_power_profile()
    battery.widget:set_text(icon .. " " .. battery.percentage .. "% " .. battery.time_remaining)
end

function battery.set_profile(profile_name)
    os.execute("sudo -n system76-power profile " .. profile_name .. " &")
    gears.timer({
        timeout = 0.5,
        autostart = true,
        callback = function(timer)
            battery.update()
            timer:stop()
        end,
    })
end

-- Initial update
battery.update()

-- Setup mouse buttons
battery.widget:buttons(gears.table.join(
    awful.button({ }, 1, function()
        -- Left click cycles through profiles
        if battery.profile == "battery" then
            battery.set_profile("balanced")
        elseif battery.profile == "balanced" then
            battery.set_profile("performance")
        else
            battery.set_profile("battery")
        end
    end),
    awful.button({ }, 3, function()
        -- Right click shows menu
        local menu = awful.menu({
            items = {
                { "🔋 Battery", function() battery.set_profile("battery") end },
                { "⚡ Balanced", function() battery.set_profile("balanced") end },
                { "🔥 Performance", function() battery.set_profile("performance") end },
            }
        })
        menu:show()
    end)
))

-- Update every 2 seconds
gears.timer({
    timeout = 2,
    autostart = true,
    callback = battery.update,
})

return battery

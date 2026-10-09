-- Audio control widget
local awful = require("awful")
local wibox = require("wibox")
local gears = require("gears")

local audio = {
    widget = wibox.widget.textbox(),
    current = 0,
    muted = false,
}

function audio.get()
    local handle = io.popen("wpctl get-volume @DEFAULT_AUDIO_SINK@ 2>/dev/null")
    local result = handle:read("*a")
    handle:close()

    if result and result ~= "" then
        local is_muted = result:find("%[MUTED%]") ~= nil
        local vol_decimal = tonumber(result:match("([%d%.]+)"))
        if vol_decimal then
            local percentage = math.floor(vol_decimal * 100)
            audio.current = percentage
            audio.muted = is_muted
            return percentage
        end
    end
    return 0
end

function audio.update()
    local level = audio.get()
    local icon = "🔊"
    if audio.muted then
        icon = "🔇"
    elseif level == 0 then
        icon = "🔇"
    elseif level < 30 then
        icon = "🔈"
    elseif level < 70 then
        icon = "🔉"
    end
    audio.widget:set_text(icon .. " " .. level .. "%")
end

function audio.increase()
    os.execute("wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%+ &")
    gears.timer({
        timeout = 0.5,
        autostart = true,
        callback = function(timer)
            audio.update()
            timer:stop()
        end,
    })
end

function audio.decrease()
    os.execute("wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%- &")
    gears.timer({
        timeout = 0.5,
        autostart = true,
        callback = function(timer)
            audio.update()
            timer:stop()
        end,
    })
end

function audio.toggle_mute()
    os.execute("wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle &")
    gears.timer({
        timeout = 0.5,
        autostart = true,
        callback = function(timer)
            audio.update()
            timer:stop()
        end,
    })
end

-- Update audio display
audio.update()

-- Setup mouse wheel bindings on the widget
audio.widget:buttons(gears.table.join(
    awful.button({ }, 4, audio.increase),   -- wheel up
    awful.button({ }, 5, audio.decrease)    -- wheel down
))

-- Update periodically
gears.timer({
    timeout = 2,
    autostart = true,
    callback = audio.update,
})

return audio

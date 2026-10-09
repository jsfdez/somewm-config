-- Quake-style dropdown terminal
local awful = require("awful")
local modkey = "Mod4"

local quake = {
    terminal = "cosmic-term",
    screen = nil,
    height = 0.5,
    toggled = false,
    client = nil,
}

function quake.toggle()
    local s = awful.screen.focused()
    local name = "QuakeTerminal"

    -- Check if quake already exists (by name or stored reference)
    local quake_client = quake.client
    if quake_client and not quake_client.valid then
        quake.client = nil
        quake_client = nil
    end

    -- If no stored reference, search by window name
    if not quake_client then
        for _, c in ipairs(client.get(s)) do
            if c.name:find("QuakeTerminal") or c.name:find("cosmic-term") then
                quake_client = c
                break
            end
        end
    end

    if quake_client then
        -- Toggle existing quake terminal
        if quake_client.hidden or not quake_client.visible then
            quake_client.hidden = false
            quake_client.minimized = false
            quake_client:geometry({
                x = 0,
                y = 0,
                width = s.geometry.width,
                height = math.floor(s.geometry.height * quake.height)
            })
            quake_client.ontop = true
            quake_client:raise()
            client.focus = quake_client
        else
            quake_client.hidden = true
            quake_client.minimized = true
        end
    else
        -- Create new quake terminal
        awful.spawn(quake.terminal .. " --title=" .. name, {
            floating = true,
            ontop = true,
            sticky = false,
            callback = function(c)
                quake.client = c  -- Store reference
                c:geometry({
                    x = 0,
                    y = 0,
                    width = s.geometry.width,
                    height = math.floor(s.geometry.height * quake.height)
                })
                c.hidden = false
                c.ontop = true
                c:raise()
                client.focus = c
            end
        })
    end
end

-- Register keybinding for quake terminal
awful.keyboard.append_global_keybindings({
    awful.key {
        modifiers   = { modkey },
        key         = "masculine",
        on_press    = quake.toggle,
        description = "toggle quake terminal",
        group       = "launcher",
    },
})

return quake

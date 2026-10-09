-- Quake-style dropdown terminal
local awful = require("awful")
local modkey = "Mod4"

local quake = {
    terminal = "kitty",
    screen = nil,
    height = 0.5,
    toggled = false,
    client = nil,
    visible = false,
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

    -- If no stored reference, search by window name or class
    if not quake_client then
        for _, c in ipairs(client.get(s)) do
            if (c.name and c.name:find("QuakeTerminal")) or
               (c.class and c.class:find("quake")) then
                quake_client = c
                break
            end
        end
    end

    if quake_client then
        -- Toggle existing quake terminal
        if quake.visible then
            -- Hide: move off-screen
            quake_client:geometry({
                x = -9999,
                y = -9999,
                width = 1,
                height = 1
            })
            quake.visible = false
        else
            -- Show: move to top of screen
            quake_client:geometry({
                x = 0,
                y = 0,
                width = s.geometry.width,
                height = math.floor(s.geometry.height * quake.height)
            })
            quake_client.ontop = true
            quake_client:raise()
            client.focus = quake_client
            quake.visible = true
        end
    else
        -- Create new quake terminal
        awful.spawn(quake.terminal .. " --class=quake --title=" .. name, {
            floating = true,
            ontop = true,
            sticky = false,
            callback = function(c)
                quake.client = c  -- Store reference
                quake.visible = true
                c:geometry({
                    x = 0,
                    y = 0,
                    width = s.geometry.width,
                    height = math.floor(s.geometry.height * quake.height)
                })
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

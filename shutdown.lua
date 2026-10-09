-- System shutdown/poweroff function
local awful = require("awful")

local shutdown = {}

function shutdown.system()
    awful.spawn("systemctl poweroff")
end

-- Alias for consistency with systemctl command
shutdown.poweroff = shutdown.system

return shutdown

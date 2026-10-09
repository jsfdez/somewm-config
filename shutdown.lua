-- System shutdown function
local awful = require("awful")

local shutdown = {}

function shutdown.system()
    awful.spawn("systemctl poweroff")
end

return shutdown

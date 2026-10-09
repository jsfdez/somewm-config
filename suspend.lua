-- System suspend function
local awful = require("awful")

local suspend = {}

function suspend.system()
    awful.spawn("systemctl suspend")
end

return suspend

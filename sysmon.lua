-- System monitor widgets: CPU, RAM and GPU usage
-- CPU/RAM come from /proc. GPU usage comes from DRM fdinfo (xe/i915 drivers),
-- which reports busy cycles per engine for every DRM client.
local awful = require("awful")
local wibox = require("wibox")
local gears = require("gears")

local sysmon = {}

local INTERVAL = 2 -- seconds between updates

local function make_widget()
    return wibox.widget {
        widget = wibox.widget.textbox,
        font = "monospace 9",
        text = "--",
    }
end

sysmon.cpu = { widget = make_widget() }
sysmon.ram = { widget = make_widget() }
sysmon.gpu = { widget = make_widget() }

local function read_file(path)
    local f = io.open(path, "r")
    if not f then return nil end
    local data = f:read("*a")
    f:close()
    return data
end

-- CPU ---------------------------------------------------------------------

local prev_cpu = nil

local function cpu_usage()
    local stat = read_file("/proc/stat")
    if not stat then return nil end
    local line = stat:match("cpu%s+([%d%s]+)")
    if not line then return nil end

    local values = {}
    for v in line:gmatch("%d+") do values[#values + 1] = tonumber(v) end
    -- user nice system idle iowait irq softirq steal
    local idle = (values[4] or 0) + (values[5] or 0)
    local total = 0
    for _, v in ipairs(values) do total = total + v end

    local usage = nil
    if prev_cpu then
        local dtotal = total - prev_cpu.total
        local didle = idle - prev_cpu.idle
        if dtotal > 0 then
            usage = math.floor((dtotal - didle) * 100 / dtotal + 0.5)
        end
    end
    prev_cpu = { total = total, idle = idle }
    return usage
end

-- RAM ---------------------------------------------------------------------

local function ram_usage()
    local meminfo = read_file("/proc/meminfo")
    if not meminfo then return nil end
    local total = tonumber(meminfo:match("MemTotal:%s+(%d+)"))
    local avail = tonumber(meminfo:match("MemAvailable:%s+(%d+)"))
    if not total or not avail or total == 0 then return nil end
    return math.floor((total - avail) * 100 / total + 0.5)
end

-- GPU ---------------------------------------------------------------------

local ENGINES = { "rcs", "ccs", "bcs", "vcs", "vecs" }
local prev_gpu = nil

-- Sum busy cycles per engine across unique DRM clients, plus the total
-- cycle counter per engine, from every process's fdinfo.
local function parse_gpu_counters(out)
    local clients = {}   -- client-id -> { engine -> busy }
    local totals = {}    -- engine -> total cycles
    local current = nil  -- client-id of the fdinfo block being parsed
    local seen = {}      -- client-ids already counted (one per open fd otherwise)

    -- Each grep line looks like "<path>:drm-<key>:\t<value>"
    for line in out:gmatch("[^\n]+") do
        local key, value = line:match(":(drm%-[%w%-]+):%s*(%S+)")
        if key then
            if key == "drm-client-id" then
                local id = value
                if seen[id] then
                    current = nil -- duplicate fd of an already-counted client
                else
                    seen[id] = true
                    clients[id] = {}
                    current = id
                end
            elseif current then
                local eng = key:match("^drm%-cycles%-(%w+)$")
                if eng then
                    clients[current][eng] = tonumber(value) or 0
                end
                local teng = key:match("^drm%-total%-cycles%-(%w+)$")
                if teng then
                    totals[teng] = tonumber(value) or 0
                end
            end
        end
    end

    local busy = {}
    for _, cl in pairs(clients) do
        for eng, v in pairs(cl) do
            busy[eng] = (busy[eng] or 0) + v
        end
    end
    return { busy = busy, totals = totals }
end

local function gpu_usage_from(out)
    local cur = parse_gpu_counters(out)

    local usage = nil
    if prev_gpu then
        local best = nil
        for _, eng in ipairs(ENGINES) do
            local dbusy = (cur.busy[eng] or 0) - (prev_gpu.busy[eng] or 0)
            local dtotal = (cur.totals[eng] or 0) - (prev_gpu.totals[eng] or 0)
            if dtotal > 0 and dbusy >= 0 then
                local pct = dbusy * 100 / dtotal
                if not best or pct > best then best = pct end
            end
        end
        if best then
            usage = math.min(100, math.floor(best + 0.5))
        end
    end
    prev_gpu = cur
    return usage
end

-- Update ------------------------------------------------------------------

local function fmt(label, value)
    if value == nil then
        return label .. " --"
    end
    return string.format("%s %d%%", label, value)
end

-- The fdinfo scan spawns grep over /proc, which takes ~0.15s. Running it
-- synchronously would stall the compositor loop, so it runs asynchronously
-- and at most one scan is in flight at a time.
local GPU_CMD = "grep -H -E '^drm-(client-id|cycles-|total-cycles-)' /proc/[0-9]*/fdinfo/* 2>/dev/null"
local gpu_scan_running = false

local function gpu_refresh()
    if gpu_scan_running then return end
    gpu_scan_running = true
    awful.spawn.easy_async_with_shell(GPU_CMD, function(stdout)
        gpu_scan_running = false
        sysmon.gpu.widget:set_text(fmt("GPU", gpu_usage_from(stdout or "")))
    end)
end

function sysmon.update()
    sysmon.cpu.widget:set_text(fmt("CPU", cpu_usage()))
    sysmon.ram.widget:set_text(fmt("RAM", ram_usage()))
    gpu_refresh()
end

-- Prime the CPU counter so the first reading has a delta to work with.
cpu_usage()

gears.timer({
    timeout = INTERVAL,
    autostart = true,
    callback = sysmon.update,
})

sysmon.update()

return sysmon

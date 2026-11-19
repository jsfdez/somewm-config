# somewm configuration

Lua configuration for somewm, an AwesomeWM-style Wayland compositor. `rc.lua` is the entry point; the other
modules are loaded from it with `require`.

## Layout

| File | Purpose |
| --- | --- |
| `rc.lua` | Main config: tags, layouts, wibar, menu, keybindings, rules |
| `sysmon.lua` | CPU, RAM and GPU usage widgets for the wibar |
| `audio.lua` | Volume widget and controls (`wpctl`) |
| `brightness.lua` | Brightness widget and controls (`brightnessctl`) |
| `battery.lua` | Battery widget with time remaining and power profile (`upower`) |
| `wifi-manager.lua` | Wi-Fi widget for one wireless device (`nmcli`), opens `nmtui` on click |
| `display.lua` | Monitor refresh rate and scale management; saved state in `somewm_display.json` |
| `suspend.lua` | Suspend function (`systemctl suspend`), exposed to the Lua prompt |
| `shutdown.lua` | Shutdown/poweroff function (`systemctl poweroff`) |
| `quake.lua` | Quake-style dropdown terminal (currently disabled in `rc.lua`) |
| `theme/` | Name of the active theme (`nord`) |

## Wibar

The bar is split into three groups:

- **Left:** menu launcher, tag list, prompt.
- **Center:** task list.
- **Right:** system tray, audio, brightness, Wi-Fi, battery, CPU, RAM, GPU,
  layout box, clock.

## External dependencies

Widgets shell out to these tools. Missing tools make the matching widget
show no data but do not stop the config from loading.

- `wpctl` (WirePlumber): audio
- `brightnessctl`: brightness; the keybindings call it through `sudo -n`, so
  it needs a passwordless sudo rule
- `upower`: battery
- `nmcli` and `nmtui` (NetworkManager): Wi-Fi
- `systemctl`: suspend and shutdown
- `somewm-client`: test mode (see below)

GPU usage is read from DRM fdinfo, so it needs a driver that reports
per-engine busy cycles (`xe` or `i915`). Without one, the GPU widget shows
`--`.

## Keybindings

Press `Mod4+s` in a running session to show the full list.

## Testing without restarting

somewm has a test mode that starts a nested compositor with a config, so you
can try changes without touching your real session:

```sh
somewm-client test start --config ~/.config/somewm/rc.lua
somewm-client test reload     # after editing a file
somewm-client test logs -f    # watch for errors
somewm-client test stop
```

See `man somewm-client` for `--name`, `--host x11` and `eval`.

## Installing

Clone or copy this directory to `~/.config/somewm/`. The compositor loads
`rc.lua` from there on startup.

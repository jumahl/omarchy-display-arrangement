# Display Arrangement for Omarchy

Arrange your monitors inside Omarchy's existing **Display** panel. Drag the display tiles to match your desk, then save the layout so it survives a restart.

## Install

Tested on Omarchy 4.5.0. This plugin is a customized copy of Omarchy's Display widget and may need changes for other shell versions.

```sh
omarchy plugin add https://github.com/jumahl/omarchy-display-arrangement.git --enable
```

Open **Display → Display arrangement**, drag a tile to the correct side and height, and select **Apply and save**. Each machine saves its own layout.

Select **Identify** to show each tile's number on its physical display for three seconds. Tiles show the monitor model when reported by the system, with the connector (such as `eDP-1`) underneath. An active built-in display is numbered 1; otherwise numbers follow connector order. Identifying displays does not apply or save the layout.

The plugin updates supported monitor rules in `~/.config/hypr/monitors.lua` and makes a backup before writing. It does not rearrange mirrored displays.

## Disable

```sh
omarchy plugin disable juan.monitor
```

Disabling the widget does not undo a saved monitor layout.

## License

Based on the Display widget from [Omarchy](https://github.com/omacom/omarchy). See [LICENSE](LICENSE).

# Display Arrangement for Omarchy

Arrange your monitors inside Omarchy's existing **Display** panel. Drag the display tiles to match your desk, then save the layout so it survives a restart.

## Install

Tested on Omarchy 4.5.0. This plugin is a customized copy of Omarchy's Display widget and may need changes for other shell versions.

```sh
omarchy plugin add https://github.com/jumahl/omarchy-display-arrangement.git --enable
```

Open **Display → Display arrangement**, drag a tile to the correct side and height, and select **Apply and save**. Each machine saves its own layout.

The plugin updates supported monitor rules in `~/.config/hypr/monitors.lua` and makes a backup before writing. It does not rearrange mirrored displays.

## Disable

```sh
omarchy plugin disable juan.monitor
```

Disabling the widget does not undo a saved monitor layout.

## License

Based on the Display widget from [Omarchy](https://github.com/omacom/omarchy). See [LICENSE](LICENSE).

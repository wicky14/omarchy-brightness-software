# Software Brightness

An Omarchy Quattro bar widget that provides software (gamma-based) brightness
control for displays whose firmware ignores brightness writes — most commonly
an HDMI monitor that reports DDC/CI brightness on read but silently drops every
write (the value always snaps back to 100).

Instead of touching the (non-functional) DDC/CI path, this widget dims the
output through Hyprland's gamma matrix via `hyprctl hyprsunset gamma`, so the
button, slider, and scroll wheel actually work.

> Software dimming — not physical backlight control. At low levels the picture
> gets slightly washed/cloudy; that is expected on a monitor that blocks DDC
> writes.

## Features

- Bar button with live percentage (left = panel, right = reset to 100%, scroll = ±5%).
- Popup panel with a brightness slider and a playful "mood" label.
- On-screen display (OSD) when adjusting from the wheel.
- Auto-starts `hyprsunset` if it is not already running (same pattern as the
  built-in Night Light service), and re-syncs to external changes every 5 s.
- Works alongside `omarchy.nightlight`: gamma and temperature are independent
  channels of the same `hyprsunset` process.

## Requirements

- Omarchy Quattro with the standard `omarchy-shell`, `hyprctl`, and `uwsm-app`.
- `hyprsunset` (Hyprland's CTM manager; ships with Hyprland/Omarchy).

No additional packages, network services, or root privileges are required.
Brightness is bounded to 5–100 % so the panel never dims to fully black.

## Install

```sh
omarchy plugin add https://github.com/wicky14/omarchy-brightness-software.git --enable
```

Then place the widget in your bar (right section, e.g. beside `omarchy.monitor`):

```sh
omarchy bar move omakid.brightness-software --section right
```

Refresh the shell only if it does not appear right away:

```sh
omarchy-shell shell rescanPlugins
```

## Usage

| Interaction | Action |
|---|---|
| Left click on the button | Open / close the brightness panel |
| Scroll on the button | Brightness −5 % / +5 % (with OSD) |
| Right click on the button | Reset brightness to 100 % |
| Drag the slider | Fine-grained brightness (debounced) |
| `h` / `l` in the panel | Brightness −5 % / +5 % |
| `Esc` in the panel | Close the panel |

## Configure

Move or restyle the widget with the standard bar commands:

```sh
omarchy bar move omakid.brightness-software --section right
```

The widget stores no configuration of its own; the brightness level lives in
the running `hyprsunset` process.

## Night Light coexistence

Night Light (`omarchy.nightlight`) controls `hyprctl hyprsunset temperature`
while this widget controls `hyprctl hyprsunset gamma`. The two settings are
independent, so enabling Night Light does not reset your brightness and vice
versa.

## Remove

```sh
omarchy plugin remove omakid.brightness-software --yes
```

Removal leaves the last applied brightness in place (it is managed by
`hyprsunset`, not by the plugin).

## Troubleshooting

- **`—` shown / slider does nothing** — `hyprsunset` is not running and auto-start
  failed. Check it exists (`command -v hyprsunset`) and run
  `hyprctl hyprsunset gamma` in a terminal.
- **Value snaps back to 100 %** — you are on a monitor that, like the DDC path,
  resets gamma; restart `hyprsunset` (`pkill hyprsunset`; the widget restarts it
  on the next read/write).
- **Panel opens once but not again** — restart the shell: `omarchy restart shell`.

## License

MIT — see [LICENSE](LICENSE).
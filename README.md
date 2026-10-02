# MouseSwitch

> I created this simple script for myself to automatically switch the mouse sensitivity when I go from my external mouse to my laptop's trackpad (and back), so I don't have to change it in Windows settings every time.

Automatically adjusts the pointer speed on **Windows 11** based on the device you are using: **mouse** or **trackpad**.

Move the mouse and the speed goes to 12. Touch the trackpad and it goes to 20. The switch happens instantly, with no clicks. A system tray icon shows the current mode and gives you manual control. Both speeds can be changed from the tray menu.

## Features

- **Automatic detection** of the device generating input, via the Windows Raw Input API.
- **Configurable speeds**: the defaults are **12** (mouse) and **20** (trackpad). You can change them from **Settings...** in the tray menu.
- **Automatic / Manual switch**: in Automatic mode the speed follows the device you are using. In Manual mode it stays on whatever you picked.
- **Start with Windows**: one click in the menu, no admin rights needed.
- **Tray icon** showing the current mode:
  - 🔵 blue = mouse · 🟢 green = trackpad (the number is the current speed)
  - **circle** = automatic mode · **square** = manual mode
- **Left-click** the icon to toggle mouse/trackpad manually. This also switches to Manual mode.
- **Diagnostics**: **Show last device** displays the name of the device that clicked the menu and how it was classified.
- **Persistent settings**: speeds and mode are saved in `%APPDATA%\MouseSwitch\settings.json`. The pointer speed itself is written to the registry, just like the Control Panel does.
- **Single instance**: warns you if a copy is already running.
- No dependencies. It is just PowerShell (built into Windows) plus a small C# snippet compiled at runtime.

## Tray menu (right-click)

| Item | Action |
|---|---|
| Mode: Automatic / Mode: Manual | Switch between automatic detection and manual control |
| Mouse (N) / Trackpad (N) | Apply that speed now (switches to Manual) |
| Settings... | Opens the settings dialog |
| Start with Windows | Toggles launching MouseSwitch at sign-in |
| Show last device | Shows the last detected device name and its classification |
| Exit (stop MouseSwitch) | Removes the tray icon and fully stops the script |

### Settings dialog

- **Mouse speed** and **Trackpad speed** (1–20, the same scale as the Windows "Pointer speed" slider)
- **Automatic switching** (the same Auto/Manual switch as in the menu)
- **Start with Windows**
- **Restore defaults** sets 12 / 20 / automatic. Click **Save** to apply.

## Files

| File | Description |
|---|---|
| `src/MouseSwitch.ps1` | Main script: tray icon, detection, speed switching and settings. |
| `src/MouseSwitch.vbs` | Launcher that starts the script without showing a console window. |

## Installation

1. Download `MouseSwitch.ps1` and `MouseSwitch.vbs` from the `src` folder and put both **in the same folder** (e.g. `C:\Tools\MouseSwitch`).
2. Double-click `MouseSwitch.vbs`. (Or just clone the repo and run `src\MouseSwitch.vbs`.)
3. *(Optional)* Right-click the tray icon and enable **Start with Windows**.
4. *(Optional)* To keep the icon always visible, drag it from the `^` overflow onto the taskbar, or enable it in **Settings > Personalization > Taskbar > Other system tray icons**.

> Start with Windows writes a `MouseSwitch` entry under `HKCU\Software\Microsoft\Windows\CurrentVersion\Run` that points to the `.vbs` in its current folder. If you move the files, turn the option off and back on.

## Configuration

Speeds, mode and startup are all set from the tray menu. Settings are stored in:

```
%APPDATA%\MouseSwitch\settings.json
```

Delete that file to reset to the defaults.

The only option still edited in the script is the device-name regex at the top of `src/MouseSwitch.ps1`:

```powershell
$DefaultMouseSpeed    = 12           # default mouse speed (1-20)
$DefaultTrackpadSpeed = 20           # default trackpad speed (1-20)
$MouseNameMatch = 'VID_|VID&'        # regex: device names that count as MOUSE
$SwitchHoldMs = 300                  # idle time (ms) before switching to the other device
```

## How it works

The script creates a hidden window and registers with the **Raw Input API** (`RegisterRawInputDevices`) for two input types:

- **Generic mouse** (Usage Page `0x01`, Usage `0x02`)
- **Precision touchpad** (Usage Page `0x0D`, Usage `0x05`)

Each `WM_INPUT` event carries the handle of the source device. The device name is read with `GetRawInputDeviceInfo` and classified like this:

| Situation | Classification |
|---|---|
| HID event from the precision touchpad | Trackpad |
| Movement with no associated device (synthesized by the precision touchpad) | Trackpad |
| Name matches `$MouseNameMatch` (`VID_` = USB, including wireless receivers · `VID&` = Bluetooth) | Mouse |
| Anything else (e.g. internal I2C touchpad, `HID#VEN_...`) | Trackpad |

When the device kind changes, the speed is applied with `SystemParametersInfo(SPI_SETMOUSESPEED)`. The call only happens when the kind changes, not on every movement.

To avoid flip-flopping when both devices are used at the same time, MouseSwitch only switches once the current device has been idle for `$SwitchHoldMs` (300 ms by default). While both are moving, the current speed is kept.

## Troubleshooting

- **Wrong classification**: open the menu and click **Show last device**, once using the mouse and once using the trackpad. Compare the names and adjust `$MouseNameMatch`. To match only your receiver, use its specific ID, e.g. `'VID_046D&PID_C52B'`.
- **Switching feels too slow or too eager**: lower or raise `$SwitchHoldMs` at the top of the script.
- **Trackpad still slow at 20**: precision touchpads have their own speed control in **Settings > Bluetooth & devices > Touchpad**, which stacks on top of this one.
- **"MouseSwitch is already running"**: exit the existing instance from the menu (**Exit**) before starting it again.
- **Script blocked**: the launcher already uses `-ExecutionPolicy Bypass`. If the file came from the internet, right-click it, open **Properties** and check **Unblock**.
- **Debugging**: run `powershell -NoProfile -STA -File src\MouseSwitch.ps1` from a console to see any errors.

## Requirements

- Windows 10 or 11
- Windows PowerShell 5.1 (preinstalled)

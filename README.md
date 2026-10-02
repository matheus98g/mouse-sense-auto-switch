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
- **Lightweight native app**: a single small `MouseSwitch.exe` with no dependencies, built with the C# compiler that ships with Windows (.NET Framework 4.x).

## Tray menu (right-click)

| Item | Action |
|---|---|
| Mode: Automatic / Mode: Manual | Switch between automatic detection and manual control |
| Mouse (N) / Trackpad (N) | Apply that speed now (switches to Manual) |
| Settings... | Opens the settings dialog |
| Start with Windows | Toggles launching MouseSwitch at sign-in |
| Show last device | Shows the last detected device name and its classification |
| Exit (stop MouseSwitch) | Removes the tray icon and fully stops the app |

### Settings dialog

- **Mouse speed** and **Trackpad speed** (1–20, the same scale as the Windows "Pointer speed" slider)
- **Automatic switching** (the same Auto/Manual switch as in the menu)
- **Start with Windows**
- **Restore defaults** sets 12 / 20 / automatic. Click **Save** to apply.

## Files

| File | Description |
|---|---|
| `src/MouseSwitch.cs` | The whole app: tray icon, detection, speed switching and settings. |
| `build.cmd` | Compiles `src/MouseSwitch.cs` into `bin\MouseSwitch.exe`. |
| `.github/workflows/release.yml` | Builds the exe on GitHub and attaches it to a release when a `v*` tag is pushed. |
| `.github/workflows/build.yml` | Builds every pull request and attaches the exe as a downloadable artifact for testing. |

## Installation

1. Download `MouseSwitch.exe` from the [latest release](../../releases/latest). It is built by GitHub Actions straight from the source in this repo.
2. Put it wherever you like (e.g. `C:\Tools\MouseSwitch`) and double-click it. Windows may show a SmartScreen warning because the exe is not code-signed (see [Troubleshooting](#troubleshooting)).
3. *(Optional)* Right-click the tray icon and enable **Start with Windows**.
4. *(Optional)* To keep the icon always visible, drag it from the `^` overflow onto the taskbar, or enable it in **Settings > Personalization > Taskbar > Other system tray icons**.

> Start with Windows writes a `MouseSwitch` entry under `HKCU\Software\Microsoft\Windows\CurrentVersion\Run` that points to `MouseSwitch.exe` in its current folder. If you move the exe, turn the option off and back on.

> **Upgrading from the PowerShell version**: exit the old tray icon, then start `MouseSwitch.exe`. Your settings are kept, and if Start with Windows was on, the entry is updated to point to the exe automatically. The old `.ps1`/`.vbs` files can be deleted.

### Building from source

Clone the repo and double-click `build.cmd`. It creates `bin\MouseSwitch.exe` in a second using the C# compiler included with Windows, with nothing to install.

### Publishing a release

Push a version tag. The workflow builds the exe and creates the release with it attached:

```
git tag v1.0.0
git push origin v1.0.0
```

## Configuration

Speeds, mode and startup are all set from the tray menu. Settings are stored in:

```
%APPDATA%\MouseSwitch\settings.json
```

Delete that file to reset to the defaults.

Two advanced options are not in the dialog and can be edited directly in that file (exit MouseSwitch first, then start it again). They are written the first time settings are saved; you can also add them yourself:

```json
{
    "MouseSpeed":  12,
    "TrackpadSpeed":  20,
    "Auto":  true,
    "MouseNameMatch":  "VID_|VID&",
    "SwitchHoldMs":  300
}
```

- `MouseNameMatch`: regex for device names that count as MOUSE. An invalid regex falls back to the default.
- `SwitchHoldMs`: idle time (ms) before switching to the other device.

## How it works

MouseSwitch creates a hidden window and registers with the **Raw Input API** (`RegisterRawInputDevices`) for two input types:

- **Generic mouse** (Usage Page `0x01`, Usage `0x02`)
- **Precision touchpad** (Usage Page `0x0D`, Usage `0x05`)

Each `WM_INPUT` event carries the handle of the source device. The device name is read with `GetRawInputDeviceInfo` and classified like this:

| Situation | Classification |
|---|---|
| HID event from the precision touchpad | Trackpad |
| Movement with no associated device (synthesized by the precision touchpad) | Trackpad |
| Name matches `MouseNameMatch` (`VID_` = USB, including wireless receivers · `VID&` = Bluetooth) | Mouse |
| Anything else (e.g. internal I2C touchpad, `HID#VEN_...`) | Trackpad |

When the device kind changes, the speed is applied with `SystemParametersInfo(SPI_SETMOUSESPEED)`. The call only happens when the kind changes, not on every movement.

To avoid flip-flopping when both devices are used at the same time, MouseSwitch only switches once the current device has been idle for `SwitchHoldMs` (300 ms by default). While both are moving, the current speed is kept.

## Troubleshooting

- **Wrong classification**: open the menu and click **Show last device**, once using the mouse and once using the trackpad. Compare the names and adjust `MouseNameMatch` in `settings.json`. To match only your receiver, use its specific ID, e.g. `"VID_046D&PID_C52B"`.
- **Switching feels too slow or too eager**: lower or raise `SwitchHoldMs` in `settings.json`.
- **Trackpad still slow at 20**: precision touchpads have their own speed control in **Settings > Bluetooth & devices > Touchpad**, which stacks on top of this one.
- **"MouseSwitch is already running"**: exit the existing instance from the menu (**Exit**) before starting it again.
- **"Windows protected your PC"** (SmartScreen): the exe is not code-signed. Click **More info > Run anyway**, or build it yourself with `build.cmd`. If the file came from the internet you can also right-click it, open **Properties** and check **Unblock**.
- **Errors**: unexpected errors are shown in a message box with the full details.

## Requirements

- Windows 10 or 11
- .NET Framework 4.x (preinstalled on Windows 10 and 11)

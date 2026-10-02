# 🖱️ MouseSwitch

Automatically switches your mouse sensitivity when you move between your **external mouse** and **laptop trackpad**.

No need to change Windows settings manually. Just move your mouse or touch the trackpad, and MouseSwitch adjusts the speed instantly.

🔵 **Mouse:** 12
🟢 **Trackpad:** 20

Both speeds are customizable.

## ✨ Features

* 🔄 **Automatic switching:** Detects whether you're using a mouse or trackpad.
* 🎚️ **Custom sensitivity:** Set different pointer speeds for each device.
* 🖱️ **Manual mode:** Choose your preferred device and keep its speed.
* 🚀 **Start with Windows:** Launch automatically when you sign in.
* 📌 **System tray:** Control everything from the Windows taskbar.
* 💾 **Persistent settings:** Your preferences are saved automatically.
* ⚡ **Lightweight:** A single executable with no additional dependencies.
* 🔍 **Device diagnostics:** Check which device was detected.
* 🔒 **Single instance:** Prevents multiple copies from running.

## 📸 How it works

| Device       | Default speed | Indicator |
| ------------ | ------------: | --------- |
| 🖱️ Mouse    |            12 | 🔵 Blue   |
| 🖲️ Trackpad |            20 | 🟢 Green  |

The tray icon displays the current speed. A circle indicates automatic mode, while a square indicates manual mode.

**Left-click** the tray icon to switch devices manually. Right-click to access the full menu.

## 📥 Installation

1. Download **MouseSwitch.exe** from the [latest release](../../releases/latest).
2. Place it anywhere on your computer.
3. Double-click the executable to start.
4. (Optional) Enable **Start with Windows** from the tray menu.

> ⚠️ Windows SmartScreen may display a warning because the executable is not code-signed. See [Troubleshooting](#-troubleshooting).

## ⚙️ Settings

Right-click the tray icon to access the following options:

| Option                | Description                                              |
| --------------------- | -------------------------------------------------------- |
| 🔄 Automatic / Manual | Switch between automatic and manual modes.               |
| 🖱️ Mouse             | Apply the configured mouse speed.                        |
| 🖲️ Trackpad          | Apply the configured trackpad speed.                     |
| ⚙️ Settings           | Customize speeds and preferences.                        |
| 🚀 Start with Windows | Enable or disable automatic startup.                     |
| 🔍 Show last device   | Display the last detected device and its classification. |
| ❌ Exit                | Completely close MouseSwitch.                            |

### 🎚️ Customize sensitivity

The settings dialog lets you configure:

* Mouse speed (1–20)
* Trackpad speed (1–20)
* Automatic switching
* Start with Windows
* Restore default settings (12 / 20)

## 🛠️ Build from source

MouseSwitch is written in **C#** and uses the compiler included with Windows.

No additional dependencies or build tools are required.

```bash
git clone https://github.com/matheus98g/mouse-sense-auto-switch.git
cd mouse-sense-auto-switch
```

Run `build.cmd` to compile the application.

The executable will be generated at:

```text
bin/MouseSwitch.exe

```

## 💾 Configuration

Settings are stored locally at:

```text
%APPDATA%\MouseSwitch\settings.json
```

Delete this file to restore the default settings.

Advanced options can also be edited manually:

| Option           | Default      | Description                                         |
| ---------------- | ------------ | --------------------------------------------------- |
| `MouseNameMatch` | `VID_\|VID&` | Regex used to identify mouse devices.               |
| `SwitchHoldMs`   | `300`        | Idle time in milliseconds before switching devices. |

Exit MouseSwitch before editing these settings.

## 🔧 Troubleshooting

**❓ The wrong device is detected**

Use **Show last device** in the tray menu to inspect the device name. You can adjust `MouseNameMatch` in the configuration file to customize mouse detection.

**🐢 Switching feels too slow**

Adjust `SwitchHoldMs`. Lower values make switching more responsive, while higher values help prevent unwanted switches.

**🖲️ The trackpad is still slow at speed 20**

Precision touchpads have their own speed setting in Windows. Check **Settings → Bluetooth & devices → Touchpad**.

**⚠️ MouseSwitch is already running**

Close the existing instance using **Exit** in the tray menu before launching another.

**🛡️ Windows protected your PC**

The executable is not code-signed. If you trust the source, select **More info → Run anyway**. Alternatively, build it yourself using `build.cmd`.

## 💻 Requirements

* Windows 10 or Windows 11
* .NET Framework 4.x (included with Windows)
* An external mouse and/or a laptop trackpad

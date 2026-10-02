# AGENTS.md

Guidance for coding agents working in this repository.

## Language rule

**Everything must be written in English**: code, comments, identifiers, UI strings (menus, tooltips, dialogs, message boxes), commit messages and documentation, including `README.md`. This applies even when the request is written in another language.

## Project layout

- `src/MouseSwitch.ps1`: the main script. It is a tray app written in PowerShell with an embedded C# block (`Add-Type`) for the Raw Input API and `SystemParametersInfo`.
- `src/MouseSwitch.vbs`: the launcher. It starts the script hidden, without a console window.
- User settings live in `%APPDATA%\MouseSwitch\settings.json`, never in the repo.
- Start with Windows uses the `HKCU\...\CurrentVersion\Run` value `MouseSwitch`.

## Constraints

- Target Windows PowerShell 5.1 (and the C# 5 compiler it ships with). Do not use PowerShell 7-only syntax.
- No external dependencies.
- Keep `README.md` in sync with any user-visible behavior change.

## Running for debugging

```
powershell -NoProfile -STA -File src\MouseSwitch.ps1
```

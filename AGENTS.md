# AGENTS.md

Guidance for coding agents working in this repository.

## Language rule

**Everything must be written in English**: code, comments, identifiers, UI strings (menus, tooltips, dialogs, message boxes), commit messages and documentation, including `README.md`. This applies even when the request is written in another language.

## Project layout

- `src/MouseSwitch.cs`: the whole app in one file. It is a WinForms tray app (`ApplicationContext`) that uses the Raw Input API and `SystemParametersInfo`.
- `build.cmd`: compiles it into `bin\MouseSwitch.exe` (`bin/` is git-ignored; the exe is never committed).
- `.github/workflows/release.yml`: on a pushed `v*` tag, runs `build.cmd` on `windows-latest` and attaches the exe to a GitHub release. Distribute only through releases.
- `.github/workflows/build.yml`: builds every pull request (read-only) and uploads the exe as an artifact.
- User settings live in `%APPDATA%\MouseSwitch\settings.json`, never in the repo.
- Start with Windows uses the `HKCU\...\CurrentVersion\Run` value `MouseSwitch`, pointing to the exe. Old values pointing to `MouseSwitch.vbs` are migrated at launch.

## Constraints

- Build only with the `csc.exe` from .NET Framework 4.x (C# 5). Do not use C# 6+ syntax (`$""` interpolation, `?.`, `nameof`, expression-bodied members).
- No external dependencies.
- Keep `README.md` in sync with any user-visible behavior change.

## Running for debugging

```
build.cmd
bin\MouseSwitch.exe
```

Unhandled exceptions are shown in a message box, since the winexe has no console.

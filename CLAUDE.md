# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

LYX is a Garry's Mod (GLua) addon framework for rapid addon development. It provides core systems (networking, SQL, logging, hooks), 30+ VGUI2 UI components, and an admin dashboard. This is **not** a web app — it runs entirely inside the Source Engine via Garry's Mod's Lua runtime.

- **Language:** Lua (GLua — Garry's Mod dialect)
- **Runtime:** Garry's Mod 13+ (Source Engine)
- **License:** CC BY-NC 2.0 (attribution required, non-commercial)
- **Authors:** @Justice, @CodeSteel
- **Docs:** https://xdjustice4.gitbook.io/lyx-docs/

## No Build System

There is no build step, package manager, or test runner. Lua files are loaded directly by the Garry's Mod engine at runtime. The addon is installed by placing it in `garrysmod/addons/lyx/`.

## Architecture

### File Loading & Prefix Convention

The loader (`lua/autorun/lyx_loader.lua`) uses filename prefixes to determine execution realm:

| Prefix   | Realm                          |
|----------|--------------------------------|
| `sv_`    | Server-only (`include()`)      |
| `cl_`    | Client-only (`AddCSLuaFile()` on server, `include()` on client) |
| `sh_`    | Shared (both server and client)|
| `vgui_`  | Client-only (UI components)    |

**Load order** is strictly: `thirdparty` → `sh` → `sv` → `cl` → `vgui`

All core files live under `lua/lyx_core/` in subdirectories matching these realms.

### Global Namespace

The framework registers itself as the global table `lyx`. All core APIs hang off this table (e.g., `lyx.Scale()`, `lyx:SQLCreate()`, `lyx:HookStart()`). UI namespace is `lyx.UI`.

### Core Directory Layout

```
lua/
├── autorun/
│   ├── lyx_loader.lua          # Entry point — loads everything in order
│   └── client/
│       └── tdlib.lua           # Third-party client library
└── lyx_core/
    ├── sh/                     # Shared systems (logging, hooks, net, config, validation, utils)
    ├── sv/                     # Server systems (SQL, JSON storage, ranks, admin, networking)
    ├── cl/                     # Client systems (scaling, fonts, rendering, 3D2D, messages)
    ├── vgui/                   # 30+ VGUI2 components + admin dashboard pages
    │   └── lyx_panel_pages/    # 12 admin dashboard page panels
    └── thirdparty/             # MediaLib, ImGui, 3D2D VGUI integrations
```

### Key Systems

- **Networking** (`sh_lyx_net.lua`, `sv_lyx_net.lua`, `cl_lyx_net.lua`): Secure messaging with rate limiting via `lyx:NetRateLimit()`, automatic compression for large payloads.
- **SQL** (`sv_lyx_sql.lua`): SQLite wrapper with `lyx:SQLCreate()`, `lyx:SQLInsert()`, `lyx:SQLSelect()`. Uses parameterized queries — never concatenate user input into SQL strings.
- **JSON Storage** (`sv_lyx_json.lua`): File-based persistence with atomic writes and automatic backups.
- **Hook System** (`sh_lyx_hooks.lua`): Enhanced hooks with `lyx:HookStart()`, `lyx:HookOnce()`, `lyx:HookConditional()`. Includes performance monitoring and slow-hook detection.
- **Scaling** (`cl_lyx_scale.lua`): `lyx.Scale()` converts design-time pixel values to resolution-appropriate sizes. All UI dimensions must use this.
- **Logging** (`sh_lyx_logger.lua`): Leveled logging (Info/Debug/Warn/Error) via `lyx.Logger:Log()`. In-memory log history (500 entries).
- **Config** (`sh_lyx_config.lua`, `sv_lyx_config_handler.lua`): Persistent server configuration with real-time change handlers.
- **Rank System** (`sv_lyx_rank.lua`): Permission-based rank hierarchy with validation.

### UI Components

All VGUI2 components are in `lua/lyx_core/vgui/` and follow the naming pattern `vgui_lyx_<component>.lua`. Components use the `"lyx_<component>"` panel class name in `vgui.Create()`. Most components have a `2` suffix (e.g., `lyx_frame2`, `lyx_button2`) indicating the current generation.

The admin dashboard pages are in `lyx_panel_pages/` and follow `vgui_lyx_pages_<pagename>.lua`.

### Addon Integration Pattern

External addons integrate with LYX using this pattern:

```lua
local addonName = "myaddon"
local createFunc = function()
    lyx.CreateAddon(addonName, Color(52, 152, 219))
end

if lyx and lyx.Loaded then
    createFunc()
else
    hook.Add("lyx.Loaded", addonName, createFunc)
end
```

The `lyx.Loaded` hook fires after all core systems are initialized. The loader patches `hook.Add` so that any `lyx.Loaded` handler registered after load executes immediately.

## Development Conventions

- **Security first:** Always use `lyx:NetRateLimit()` for network messages. Always use the SQL wrapper methods (never raw `sql.Query()` with string concatenation). Validate all client input server-side.
- **Responsive UI:** Always wrap pixel values in `lyx.Scale()` — never use hardcoded pixel sizes in UI code.
- **Error wrapping:** Wrap critical operations in `pcall()` to prevent one system from crashing others.
- **Logging:** Use `lyx.Logger:Log()` with appropriate severity levels rather than raw `print()`.
- **File naming:** New files must use the correct prefix (`sv_`, `cl_`, `sh_`, `vgui_`) and be placed in the corresponding subdirectory under `lyx_core/`.
- **Theme support:** UI code should reference the theme system (`materials/lyx/black/` and `materials/lyx/white/` assets).

## Materials

Theme assets live in `materials/lyx/` with `black/` and `white/` subdirectories containing UI textures.

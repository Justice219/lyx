
# 🚀 LYX Framework

<div align="center">

![LYX Version](https://img.shields.io/badge/version-2.0-blue)
![Garry's Mod](https://img.shields.io/badge/Garry's%20Mod-Lua-orange)
[![CC BY NC](https://img.shields.io/badge/License-CC%20BY%20NC-green)](https://creativecommons.org/licenses/by-nc/2.0/deed.en)
[![Documentation](https://img.shields.io/badge/docs-GitBook-brightgreen)](https://xdjustice4.gitbook.io/lyx-docs/)

**A comprehensive framework for rapid Garry's Mod addon development**

[📚 Documentation](https://xdjustice4.gitbook.io/lyx-docs/) • 
[🎮 Demo (GM3)](https://github.com/Justice219/gamemaster3) • 
[🐛 Report Bug](https://github.com/Justice219/lyx/issues) • 
[✨ Request Feature](https://github.com/Justice219/lyx/issues)

</div>

---

## 📋 Overview

LYX is a production-ready framework that provides robust systems and utilities for Garry's Mod addon development. Originally created to accelerate personal addon development, LYX has evolved into a comprehensive framework used by multiple production addons.


## ✨ Key Features

### 🎨 **Modern UI System (VGUI2)**
- 30+ pre-built components with automatic scaling
- Responsive design system with `lyx.Scale()`
- Smooth animations and transitions
- Theme support with color management
- Components: Frames, Buttons, Sliders, Checkboxes, Labels, and more

### 🔒 **Secure Networking**
- Built-in rate limiting and anti-exploit protection
- Encrypted network messages with authentication
- Automatic compression for large data
- Network monitoring and debugging tools

### 💾 **Data Management**
- **SQL Database**: Full SQLite support with query builder
- **JSON Storage**: Atomic writes with automatic backups
- **Performance**: Optimized caching and batch operations
- **Security**: Input sanitization and injection prevention

### 🎮 **Enhanced Hook System**
- Automatic error handling and recovery
- Performance monitoring with slow hook detection
- Auto-ID generation for easy management
- One-time and conditional hooks

### 🔧 **Developer Tools**
- Comprehensive logging system with levels
- Performance profiling utilities
- Debug modes for all systems
- Hot-reload support for rapid development

### 🎬 **Third-Party Integrations**
- **MediaLib**: YouTube, Twitch, and audio streaming
- **ImGui**: Immediate mode GUI for debug interfaces
- **3D2D VGUI**: World-space UI rendering

## 🚀 Quick Start

```lua
-- Create your addon in 4 lines!
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

## 👥 Authors

- **[@Justice](https://www.github.com/Justice219)** - Framework architecture and core systems
- **[@CodeSteel](https://github.com/CodeSteel)** - VGUI2 component library

## 💻 Code Examples

### Creating a UI Panel
```lua
-- Modern UI with automatic scaling
local frame = vgui.Create("lyx_frame2")
frame:SetSize(lyx.Scale(600), lyx.Scale(400))
frame:SetTitle("My Addon")
frame:Center()
frame:MakePopup()

-- Add a button
local btn = vgui.Create("lyx_button2", frame)
btn:SetText("Click Me!")
btn:SetPos(lyx.Scale(10), lyx.Scale(40))
btn:SetSize(lyx.Scale(100), lyx.Scale(30))
btn.DoClick = function()
    lyx.Notify("Button clicked!", NOTIFY_HINT)
end
```

### Secure Networking
```lua
-- Server-side
util.AddNetworkString("MyAddon_Data")

net.Receive("MyAddon_Data", function(len, ply)
    -- Automatic rate limiting and validation
    if not lyx:NetRateLimit(ply, "MyAddon_Data", 5, 10) then
        return
    end
    
    local data = net.ReadTable()
    -- Process securely...
end)

-- Client-side
net.Start("MyAddon_Data")
net.WriteTable({action = "update"})
net.SendToServer()
```

### Database Operations
```lua
-- Create table with auto-schema
lyx:SQLCreate("players", {
    steamid = "VARCHAR(20) PRIMARY KEY",
    name = "VARCHAR(100)",
    level = "INTEGER DEFAULT 1",
    xp = "INTEGER DEFAULT 0"
})

-- Insert with automatic escaping
lyx:SQLInsert("players", {
    steamid = ply:SteamID64(),
    name = ply:Nick(),
    level = 1,
    xp = 0
})

-- Query with safety
local data = lyx:SQLSelect("players", {steamid = ply:SteamID64()})
```

### Enhanced Hook System
```lua
-- Auto-ID generation for easy removal
local hookId = lyx:HookStart("Think", function()
    -- Your code here
end)

-- One-time hook
lyx:HookOnce("InitPostEntity", function()
    print("Map loaded!")
end)

-- Conditional hook
lyx:HookConditional("HUDPaint", 
    function() return GetConVar("my_hud"):GetBool() end,
    function() DrawMyHUD() end
)

-- Clean removal
lyx:HookRemove("Think", hookId)
```

## 📚 Documentation

<div align="center">

### **[📖 Read the Full Documentation](https://xdjustice4.gitbook.io/lyx-docs/)**

</div>

The comprehensive documentation includes:
- 🚀 **Getting Started** - Installation, quick start, creating your first addon
- 📘 **API Reference** - Complete function and method documentation
- 🎨 **UI Components** - All 30+ VGUI2 components with examples
- 🔒 **Networking** - Security, rate limiting, and best practices
- 💾 **Database** - SQL and JSON storage systems
- 🔧 **Advanced Topics** - Performance, security, and optimization

> Legacy wiki available [here](https://github.com/Justice219/lyx/wiki)

## 🎮 Production Examples

### GameMaster 3
A comprehensive admin system built entirely with LYX, showcasing the framework's capabilities in a production environment.

**[🔗 View Project](https://github.com/Justice219/gamemaster3)**

![GameMaster 3 Demo](https://i.imgur.com/bcsv4zw.gif)

Features demonstrated:
- Complex UI with multiple panels
- Real-time data synchronization  
- Permission management
- Secure admin commands
- Database integration

## 📦 Installation

1. **Download** the latest release from [Releases](https://github.com/Justice219/lyx/releases)
2. **Extract** to `garrysmod/addons/lyx/`
3. **Restart** your server or game
4. **Verify** installation: Check console for `[LYX] Framework loaded successfully`

## 🤝 Contributing

Contributions are welcome! Please feel free to submit a Pull Request. For major changes, please open an issue first to discuss what you would like to change.

## 📄 License

This project is licensed under [CC BY-NC 2.0](https://creativecommons.org/licenses/by-nc/2.0/deed.en)

- ✅ **Permitted**: Modification, distribution, private use
- ⚠️ **Required**: Attribution, same license
- ❌ **Forbidden**: Commercial use

> Proper attribution must be made somewhere within your modified code or deployment page.

## 🌟 Support

- **Documentation**: [GitBook](https://xdjustice4.gitbook.io/lyx-docs/)
- **Issues**: [GitHub Issues](https://github.com/Justice219/lyx/issues)
- **Discord**: [Join our community](https://discord.gg/your-discord)

---

<div align="center">
Made with ❤️ for the Garry's Mod community
</div>

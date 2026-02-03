# LYXUI Integration Documentation

## Overview

LYXUI is a comprehensive UI library integrated into the LYX framework, ported from PIXEL UI (by Thomas O'Sullivan, GPL-3.0). It provides GPU-accelerated rounded box rendering via RNDX shaders, URL-based image loading/caching, 26 VGUI2 panel components, and 3D2D world-space UI rendering.

## Architecture

### Namespace Convention

LYXUI uses a dual-namespace approach:
- **`LYXUI.*`** - Unique features (RNDX drawing, image system, formatting, colors, overrides)
- **`lyx.*`** - Shared utilities delegated to the existing LYX framework (scaling, fonts, text drawing, color manipulation)

### Load Order

LYXUI loads **after** `lyx_core` completes, so all `lyx.*` utilities are available:

```
lyx_core/thirdparty -> lyx_core/sh -> lyx_core/sv -> lyx_core/cl -> lyx_core/vgui
    -> lyxui/thirdparty -> lyxui/sh -> lyxui/cl -> lyxui/vgui
    -> hook.Run("LYXUI.FullyLoaded")
    -> hook.Run("lyx.Loaded")
```

### Directory Structure

```
lua/lyxui/
├── thirdparty/                          # Third-party libraries
│   ├── cl_rndx.lua                      # RNDX GPU shader library (by Srlion, MIT)
│   ├── cl_arc.lua                       # Arc drawing utilities
│   └── cl_lyxui_ui3d2d.lua              # 3D2D VGUI rendering system
├── sh/                                  # Shared (server + client)
│   ├── sh_lyxui_config.lua              # Namespace init, colors, config
│   └── sh_lyxui_formatting.lua          # Money/time formatting
├── cl/                                  # Client-only core
│   ├── cl_lyxui_images.lua              # URL image loading/caching system
│   ├── cl_lyxui_overrides.lua           # Derma popup override system
│   ├── cl_lyxui_rounded_box.lua         # RNDX-based rounded box drawing
│   ├── cl_lyxui_outlined_box.lua        # RNDX-based outlined box drawing
│   ├── cl_lyxui_circle.lua              # Circle drawing (image + polygon)
│   ├── cl_lyxui_drawing_images.lua      # High-level image drawing + progress spinner
│   ├── cl_lyxui_overheads.lua           # 3D overhead labels above entities
│   └── cl_lyxui_misc.lua               # Text boxes, blur effect
└── vgui/                                # VGUI2 panel components (26 total)
    ├── vgui_lyxui_button.lua            # Base button with toggle + color animation
    ├── vgui_lyxui_label.lua             # Text label with alignment/wrapping
    ├── vgui_lyxui_text_entry_internal.lua # Internal TextEntry override
    ├── vgui_lyxui_text_entry.lua        # Styled text input with outline animation
    ├── vgui_lyxui_validated_text_entry.lua # Text input with validation feedback
    ├── vgui_lyxui_text_button.lua       # Button with centered text
    ├── vgui_lyxui_image_button.lua      # Button with URL image icon
    ├── vgui_lyxui_imgur_button.lua      # Image button with Imgur ID shorthand
    ├── vgui_lyxui_scrollbar.lua         # Scrollbar + grip components
    ├── vgui_lyxui_scrollpanel.lua       # Scrollable container with momentum
    ├── vgui_lyxui_slider.lua            # Horizontal slider with draggable grip
    ├── vgui_lyxui_checkbox.lua          # Toggle checkbox with checkmark icon
    ├── vgui_lyxui_labelled_checkbox.lua # Checkbox with adjacent text label
    ├── vgui_lyxui_color_picker.lua      # HSL triangle picker with hue wheel
    ├── vgui_lyxui_menu_option.lua       # Menu item + CVar-bound variant
    ├── vgui_lyxui_menu.lua              # Dropdown/context menu with sub-menus
    ├── vgui_lyxui_combo_box.lua         # Dropdown selection box
    ├── vgui_lyxui_frame.lua             # Draggable/resizable window frame
    ├── vgui_lyxui_category.lua          # Collapsible category container
    ├── vgui_lyxui_property_sheet.lua    # Tabbed property sheet
    ├── vgui_lyxui_sidebar.lua           # Vertical sidebar with icon items
    ├── vgui_lyxui_navbar.lua            # Horizontal nav bar with selection indicator
    ├── vgui_lyxui_avatar.lua            # Circular avatar with stencil masking
    ├── vgui_lyxui_message_popup.lua     # Simple message dialog
    ├── vgui_lyxui_query_popup.lua       # Multi-button query dialog
    └── vgui_lyxui_string_request_popup.lua # Text input dialog
```

## Namespace Mapping (PIXEL -> LYXUI/lyx)

Functions that were identical to existing LYX utilities are delegated:

| PIXEL Function | LYXUI/LYX Equivalent | Notes |
|---|---|---|
| `PIXEL.Scale()` | `lyx.Scale()` | Resolution-aware scaling |
| `PIXEL.RegisterFont()` | `lyx.RegisterFont()` | Scaled font registration |
| `PIXEL.RegisterFontUnscaled()` | `lyx.RegisterFontUnscaled()` | Unscaled font registration |
| `PIXEL.SetFont()` | `lyx.SetFont()` | Set active font |
| `PIXEL.GetTextSize()` | `lyx.GetTextSize()` | Measure text dimensions |
| `PIXEL.DrawSimpleText()` | `lyx.DrawSimpleText()` | Single-line text |
| `PIXEL.DrawText()` | `lyx.DrawText()` | Multi-line text |
| `PIXEL.DrawShadowText()` | `lyx.DrawShadowText()` | Text with shadow |
| `PIXEL.DrawDualText()` | `lyx.DrawDualText()` | Two-part text |
| `PIXEL.WrapText()` | `lyx.WrapText()` | Text wrapping |
| `PIXEL.EllipsesText()` | `lyx.EllipsesText()` | Text truncation |
| `PIXEL.CopyColor()` | `lyx.CopyColor()` | Deep copy a Color |
| `PIXEL.OffsetColor()` | `lyx.OffsetColor()` | Brighten/darken a Color |
| `PIXEL.LerpColor()` | `lyx.LerpColor()` | Interpolate between Colors |
| `PIXEL.HSLToColor()` | `lyx.HSLToColor()` | HSL to Color conversion |
| `PIXEL.GetScaledConstant()` | `lyx.GetScaledConstant()` | Named scaled values |
| `PIXEL.RegisterScaledConstant()` | `lyx.RegisterScaledConstant()` | Register scaled constants |

Functions unique to LYXUI (not in LYX):

| Function | Purpose |
|---|---|
| `LYXUI.DrawRoundedBox()` | RNDX GPU-accelerated rounded rectangle |
| `LYXUI.DrawRoundedBoxEx()` | Per-corner radius rounded rectangle |
| `LYXUI.DrawOutlinedRoundedBox()` | Outlined (stroke-only) rounded rectangle |
| `LYXUI.DrawImage()` | Draw URL-sourced image with loading spinner |
| `LYXUI.DrawImgur()` | Draw Imgur image by ID |
| `LYXUI.DrawImageRotated()` | Draw rotated URL image |
| `LYXUI.DrawCircle()` | Draw circle using best-fit image |
| `LYXUI.DrawArc()` | Draw precached arc polygon |
| `LYXUI.PrecacheArc()` | Pre-calculate arc vertices |
| `LYXUI.DrawProgressWheel()` | Animated loading spinner |
| `LYXUI.DrawBlur()` | Blurred background panel effect |
| `LYXUI.DrawRoundedTextBox()` | Text with auto-sized rounded background |
| `LYXUI.DrawEntOverhead()` | 3D overhead label above entities |
| `LYXUI.DrawNPCOverhead()` | 3D overhead label above NPCs |
| `LYXUI.GetImage()` | Fetch and cache URL image material |
| `LYXUI.FormatMoney()` | Currency formatting with commas |
| `LYXUI.FormatTime()` | Human-readable duration formatting |
| `LYXUI.Colors.*` | Color palette (Background, Primary, etc.) |
| `LYXUI.UI.UI3D2D.*` | 3D2D rendering context management |

## VGUI Component Hierarchy

```
Panel
├── LYXUI.Button (toggle, color animation, disabled state)
│   ├── LYXUI.TextButton (centered text label)
│   │   └── LYXUI.ComboBox (dropdown selection)
│   ├── LYXUI.ImageButton (URL image icon)
│   │   ├── LYXUI.ImgurButton (Imgur ID shorthand)
│   │   └── LYXUI.Checkbox (toggle with checkmark)
│   ├── LYXUI.Slider (horizontal with grip)
│   ├── LYXUI.CategoryHeader (collapsible header)
│   ├── LYXUI.SidebarItem (sidebar button)
│   ├── LYXUI.NavbarItem (nav bar button)
│   └── LYXUI.MenuOption (context menu item)
│       └── LYXUI.MenuOptionCVar (CVar-bound)
├── LYXUI.Label (text with alignment/wrapping)
├── LYXUI.ScrollPanel (momentum scrolling container)
│   └── LYXUI.Menu (dropdown/context menu)
├── LYXUI.Scrollbar (scroll track + grip)
├── LYXUI.ScrollbarGrip (draggable grip)
├── LYXUI.TextEntry (styled input wrapper)
├── LYXUI.ValidatedTextEntry (input with validation)
├── LYXUI.LabelledCheckbox (checkbox + label)
├── LYXUI.ColorPicker (HSL triangle + hue wheel)
├── LYXUI.Category (collapsible container)
├── LYXUI.Sidebar (vertical icon sidebar)
├── LYXUI.Navbar (horizontal nav with indicator)
├── LYXUI.Avatar (circular stencil-masked avatar)
EditablePanel
├── LYXUI.Frame (draggable/resizable window)
│   ├── LYXUI.Message (message dialog)
│   ├── LYXUI.Query (multi-button dialog)
│   └── LYXUI.StringRequest (text input dialog)
└── LYXUI.PropertySheet (tabbed container)
TextEntry
└── LYXUI.TextEntryInternal (custom TextEntry base)
```

## Usage Example

```lua
-- Create a basic LYXUI frame with a button
local frame = vgui.Create("LYXUI.Frame")
frame:SetTitle("My Addon")
frame:SetSize(lyx.Scale(400), lyx.Scale(300))
frame:Center()
frame:MakePopup()

local btn = vgui.Create("LYXUI.TextButton", frame)
btn:SetText("Click Me")
btn:Dock(TOP)
btn:DockMargin(lyx.Scale(10), lyx.Scale(10), lyx.Scale(10), 0)
btn.DoClick = function()
    print("Button clicked!")
end
```

## Files Modified

- `lua/autorun/lyx_loader.lua` - Added LYXUI directory loading after lyx_core

## Files Created

39 new files under `lua/lyxui/` (see directory structure above).

## Skipped Files (identical to existing lyx.* functions)

- `core/cl_scaling.lua` - `lyx.Scale()` and related functions
- `core/cl_color.lua` - `lyx.CopyColor()`, `lyx.OffsetColor()`, `lyx.LerpColor()`, etc.
- `core/cl_fonts.lua` - `lyx.RegisterFont()`, `lyx.SetFont()`, `lyx.GetTextSize()`, etc.
- `drawing/cl_text.lua` - `lyx.DrawSimpleText()`, `lyx.DrawText()`, `lyx.DrawShadowText()`, etc.

## Next Steps

- Test in Garry's Mod by creating a simple addon that uses `vgui.Create("LYXUI.Frame")`
- Verify RNDX shaders load correctly (requires Source Engine GPU shader compilation)
- Customize `LYXUI.Colors` to match your addon's theme
- Consider adding `LYXUI.FullyLoaded` hook handler for addon integration

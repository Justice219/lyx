--[[
	LYXUI Configuration
	Ported from PIXEL UI to integrate with the LYX framework.

	Initializes the LYXUI namespace, defines the default color palette,
	image download settings, and Derma override configuration.
	This file is shared (loaded on both server and client).
]]

LYXUI = LYXUI or {}
LYXUI.UI = LYXUI.UI or {}
LYXUI.UI.Overrides = LYXUI.UI.Overrides or {}
LYXUI.Version = "1.0.0"

--[[
    The Image URL of the progress spinner shown while image content loads.
]]
LYXUI.ProgressImageURL = "https://pixel-cdn.lythium.dev/i/47qh6kjjh"

--[[
    Data folder path where downloaded image assets are cached.
]]
LYXUI.DownloadPath = "lyxui/images/"

--[[
    Derma popup override mode:
    0 = No - forced off.
    1 = No - but users can opt in via convar (lyxui_override_popups).
    2 = Yes - but users can opt out via convar.
    3 = Yes - forced on.
]]
LYXUI.OverrideDermaMenus = 0

--[[
    Default color palette for all LYXUI elements.
    Addons can override individual colors after load:
      LYXUI.Colors.Primary = Color(255, 0, 0)
]]
LYXUI.Colors = {
    Background = Color(22, 22, 22),
    Header = Color(28, 28, 28),
    Scroller = Color(61, 61, 61),

    PrimaryText = Color(255, 255, 255),
    SecondaryText = Color(220, 220, 220),
    DisabledText = Color(40, 40, 40),

    Primary = Color(47, 128, 200),
    Disabled = Color(180, 180, 180),
    Positive = Color(66, 134, 50),
    Negative = Color(164, 50, 50),

    Gold = Color(214, 174, 34),
    Silver = Color(192, 192, 192),
    Bronze = Color(145, 94, 49),

    Transparent = Color(0, 0, 0, 0)
}

--[[
	LYXUI Derma Override System
	Ported from PIXEL UI.

	Provides a system for conditionally overriding default Derma popup
	functions (Derma_Message, Derma_Query, Derma_StringRequest) with
	LYXUI-styled versions. Controlled by LYXUI.OverrideDermaMenus config
	and an optional client convar.
]]

LYXUI.UI.Overrides = LYXUI.UI.Overrides or {}

--- Creates a wrapper function that conditionally calls an override or the original
-- @param method function The original function to wrap
-- @param override function The override replacement function
-- @param toggleGetter function Returns true when override should be active
-- @return function Wrapped function that delegates based on toggleGetter
function LYXUI.UI.CreateToggleableOverride(method, override, toggleGetter)
    return function(...)
        return toggleGetter(...) and override(...) or method(...)
    end
end

local overridePopupsCvar = CreateClientConVar("lyxui_override_popups", (LYXUI.OverrideDermaMenus > 1) and "1" or "0", true, false, "Should the default derma popups be restyled with LYXUI?", 0, 1)

--- Returns whether LYXUI should override default Derma popups based on config and convar
-- @return boolean True if popups should use LYXUI styling
function LYXUI.UI.ShouldOverrideDermaPopups()
    local overrideSetting = LYXUI.OverrideDermaMenus

    if not overrideSetting or overrideSetting == 0 then return false end
    if overrideSetting == 3 then return true end

    return overridePopupsCvar:GetBool()
end

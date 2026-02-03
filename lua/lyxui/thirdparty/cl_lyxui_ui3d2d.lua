--[[
	LYXUI UI3D2D Library
	Ported from PIXEL UI.

	Provides 3D2D rendering context management, cursor position tracking,
	hover detection, and VGUI panel drawing in 3D world space.

	Functions:
	  LYXUI.UI.UI3D2D.isPressing() - Returns true if input is being held
	  LYXUI.UI.UI3D2D.isPressed() - Returns true if input was pressed this frame
	  LYXUI.UI.UI3D2D.startDraw(pos, angles, scale, ignoredEntity) - Starts 3D2D context
	  LYXUI.UI.UI3D2D.endDraw() - Ends the 3D2D rendering context
	  LYXUI.UI.UI3D2D.getCursorPos() - Returns cursor X/Y in 3D2D space
	  LYXUI.UI.UI3D2D.isHovering(x, y, w, h) - Hit test against 3D2D cursor
	  LYXUI.UI.UI3D2D.drawCursor(x, y, w, h, size) - Draws a cursor in 3D2D space
	  LYXUI.UI.UI3D2D.drawVgui(panel, pos, angles, scale, ignoredEntity) - Renders VGUI in 3D2D
]]

local ui3d2d = ui3d2d or {}
LYXUI.UI.UI3D2D = ui3d2d

do --Input handling
    local getRenderTarget, cursorVisible = render.GetRenderTarget, vgui.CursorVisible
    local isMouseDown, isKeyDown = input.IsMouseDown, input.IsKeyDown

    local inputEnabled, isPressing, isPressed

    hook.Add("PreRender", "LYXUI.UI3D2D.InputHandler", function() --Check the input state before rendering UIs
        if getRenderTarget() then inputEnabled = false return end
        if cursorVisible() then inputEnabled = false return end

        inputEnabled = true

        local wasPressing = isPressing
        isPressing = isMouseDown(MOUSE_LEFT) or isKeyDown(KEY_E)
        isPressed = not wasPressing and isPressing
    end)

    --- Returns true if an input (mouse or E key) is being held
    function ui3d2d.isPressing()
        return inputEnabled and isPressing
    end

    --- Returns true if an input was pressed this frame (rising edge)
    function ui3d2d.isPressed()
        return inputEnabled and isPressed
    end
end

do --Rendering context creation and mouse position getters
    local localPlayer

    hook.Add("PreRender", "LYXUI.UI3D2D.GetLocalPlayer", function() --Keep getting the local player until it's available
        localPlayer = LocalPlayer()
        if IsValid(localPlayer) then hook.Remove("PreRender", "LYXUI.UI3D2D.GetLocalPlayer") end
    end)

    local traceLine = util.TraceLine

    local baseQuery = {filter = {}}

    --- Checks if the cursor trace is obstructed by another entity
    -- @param eyePos Vector Player eye position
    -- @param hitPos Vector Hit position on the 3D2D plane
    -- @param ignoredEntity Entity Entity to ignore in the trace
    -- @return boolean True if the path is obstructed
    local function isObstructed(eyePos, hitPos, ignoredEntity)
        local query = baseQuery
        query.start = eyePos
        query.endpos = hitPos
        query.filter[1] = localPlayer
        query.filter[2] = ignoredEntity

        return traceLine(query).Hit
    end

    local mouseX, mouseY
    local hoveredSomething = false

    do
        local start3d2d = cam.Start3D2D
        local isCursorVisible, isHoveringWorld = vgui.CursorVisible, vgui.IsHoveringWorld
        local screenToVector, mousePos = gui.ScreenToVector, gui.MousePos
        local intersectRayWithPlane = util.IntersectRayWithPlane

        local isRendering

        --- Starts a new 3D2D UI rendering context
        -- @param pos Vector World position of the 3D2D plane origin
        -- @param angles Angle Orientation of the plane
        -- @param scale number Scale factor for the plane
        -- @param ignoredEntity Entity Optional entity to ignore in obstruction checks
        -- @return boolean|nil True if rendering should proceed, nil if culled
        function ui3d2d.startDraw(pos, angles, scale, ignoredEntity)
            local eyePos = localPlayer:EyePos()
            if eyePos:DistToSqr(pos) > 400000 then return end

            local eyePosToUi = pos - eyePos

            do --Only draw the UI if the player is in front of it
                local normal = angles:Up()
                local dot = eyePosToUi:Dot(normal)

                if dot >= 0 then return end
            end

            isRendering = true
            mouseX, mouseY = nil, nil

            start3d2d(pos, angles, scale)

            local cursorVisible, hoveringWorld = isCursorVisible(), isHoveringWorld()
            if not hoveringWorld and cursorVisible then return true end

            local eyeNormal
            do
                if cursorVisible and hoveringWorld then
                    eyeNormal = screenToVector(mousePos())
                else
                    eyeNormal = localPlayer:GetEyeTrace().Normal
                end
            end

            local hitPos = intersectRayWithPlane(eyePos, eyeNormal, pos, angles:Up())
            if not hitPos then return true end

            if isObstructed(eyePos, hitPos, ignoredEntity) then return true end

            local diff = pos - hitPos
            mouseX = diff:Dot(-angles:Forward()) / scale
            mouseY = diff:Dot(-angles:Right()) / scale

            hoveredSomething = nil
            return true
        end

        local end3d2d = cam.End3D2D

        --- Safely ends the 3D2D UI rendering context
        function ui3d2d.endDraw()
            if not isRendering then print("[LYXUI.UI3D2D] Attempted to end a non-existent 3d2d ui rendering context.") return end
            isRendering = false
            end3d2d()
        end
    end

    --- Returns the current 3D2D cursor position
    -- @return number|nil X cursor position (nil if not pointing at the panel)
    -- @return number|nil Y cursor position
    function ui3d2d.getCursorPos()
        return mouseX, mouseY
    end

    --- Checks if the cursor is within a specified rectangular area
    -- @param x number Left edge X
    -- @param y number Top edge Y
    -- @param w number Width
    -- @param h number Height
    -- @param preventCursorChange boolean If true, won't mark as hovered for cursor styling
    -- @return boolean True if the cursor is inside the rectangle
    function ui3d2d.isHovering(x, y, w, h, preventCursorChange)
        local mx, my = mouseX, mouseY
        local hovering = mx and my and mx >= x and mx <= (x + w) and my >= y and my <= (y + h)
        if not preventCursorChange and hovering then hoveredSomething = true end
        return hovering
    end

    local cursorMat
    local cursorHoverMat
    LYXUI.GetImage("https://pixel-cdn.lythium.dev/i/cyf6d6gzf", function(mat) cursorMat = mat end)
    LYXUI.GetImage("https://pixel-cdn.lythium.dev/i/m3m6x59yb", function(mat) cursorHoverMat = mat end)

    --- Draws a cursor icon at the current 3D2D cursor position
    -- @param x number Unused (cursor uses its own position)
    -- @param y number Unused
    -- @param w number Unused
    -- @param h number Unused
    -- @param size number Cursor icon size (default 20)
    function ui3d2d.drawCursor(x, y, w, h, size)
        size = size or 20

        local mx, my = ui3d2d.getCursorPos()
        if not (mx and my) then return end

        surface.SetDrawColor(255, 255, 255)
        surface.SetMaterial(hoveredSomething and cursorHoverMat or cursorMat)
        surface.DrawTexturedRect(hoveredSomething and (mx - size / 3.75) or mx, my, size, size)
    end
end

do --3d2d VGUI Drawing
    local insert = table.insert

    --- Gets all parent panels of a given panel in order
    -- @param panel Panel The starting panel
    -- @return table Array of parent panels
    local function getParents(panel)
        local parents = {}
        local parent = panel:GetParent()

        while parent do
            insert(parents, parent)
            parent = parent:GetParent()
        end

        return parents
    end

    local ipairs = ipairs

    --- Calculates the absolute screen position of a panel (accounting for all parents)
    -- @param panel Panel The panel
    -- @return number X absolute position
    -- @return number Y absolute position
    local function absolutePanelPos(panel)
        local x, y = panel:GetPos()
        local parents = getParents(panel)

        for _, parent in ipairs(parents) do
            local parentX, parentY = parent:GetPos()
            x = x + parentX
            y = y + parentY
        end

        return x, y
    end

    --- Checks if a point is inside a panel's absolute bounds
    -- @param panel Panel The panel to test
    -- @param x number Point X
    -- @param y number Point Y
    -- @return boolean True if point is inside the panel
    local function pointInsidePanel(panel, x, y)
        local absoluteX, absoluteY = absolutePanelPos(panel)
        local width, height = panel:GetSize()

        return panel:IsVisible() and x >= absoluteX and y >= absoluteY and x <= absoluteX + width and y <= absoluteY + height
    end

    local pairs = pairs
    local reverseTable = table.Reverse

    --- Recursively checks hover state for a panel and its children
    -- Handles mouse press/release forwarding to the 3D2D panels
    local function checkHover(panel, x, y, found, hoveredPanel)
        local validChild = false
        for _, child in pairs(reverseTable(panel:GetChildren())) do
            if not child:IsMouseInputEnabled() then continue end

            if checkHover(child, x, y, found or validChild) then validChild = true end
        end

        if not panel.isUi3d2dSetup then
            panel.IsHovered = function(s)
                return s.Hovered
            end

            panel:SetPaintedManually(true)
            panel.isUi3d2dSetup = true
        end

        if found then
            if panel.Hovered then
                panel.Hovered = false
                if panel.OnCursorExited then panel:OnCursorExited() end
            end
        else
            if not validChild and pointInsidePanel(panel, x, y) then
                panel.Hovered = true

                if panel.OnMousePressed then
                    local key = input.IsKeyDown(KEY_LSHIFT) and MOUSE_RIGHT or MOUSE_LEFT

                    if panel.OnMousePressed and ui3d2d.isPressed() then
                        panel:OnMousePressed(key)
                    end

                    if panel.OnMouseReleased and not ui3d2d.isPressing() then
                        panel:OnMouseReleased(key)
                    end
                elseif panel.DoClick and ui3d2d.isPressed() then
                    panel:DoClick()
                end

                if panel.OnCursorEntered then panel:OnCursorEntered() end

                return true
            else
                panel.Hovered = false
                if panel.OnCursorExited then panel:OnCursorExited() end
            end
        end
    end

    local oldMouseX, oldMouseY = gui.MouseX, gui.MouseY

    --- Draws a VGUI panel in 3D2D world space with full mouse interaction support
    -- Temporarily overrides gui.MouseX/Y to provide 3D2D cursor coordinates
    -- @param panel Panel The VGUI panel to render
    -- @param pos Vector World position of the 3D2D plane
    -- @param angles Angle Orientation of the plane
    -- @param scale number Scale factor
    -- @param ignoredEntity Entity Optional entity to ignore in traces
    function ui3d2d.drawVgui(panel, pos, angles, scale, ignoredEntity)
        if not (IsValid(panel) and ui3d2d.startDraw(pos, angles, scale, ignoredEntity)) then return end

        do
            local cursorX, cursorY = ui3d2d.getCursorPos()
            cursorX, cursorY = cursorX or -1, cursorY or -1

            function gui.MouseX()
                return cursorX
            end

            function gui.MouseY()
                return cursorY
            end

            checkHover(panel, cursorX, cursorY)
        end

        panel:PaintManual()

        gui.MouseX, gui.MouseY = oldMouseX, oldMouseY

        ui3d2d.endDraw()
    end
end

hook.Run("LYXUI.UI.UI3D2D.FullyLoaded")

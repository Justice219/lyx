lyx = lyx

local PANEL = {}

AccessorFunc(PANEL, "Draggable", "Draggable", FORCE_BOOL)
AccessorFunc(PANEL, "Sizable", "Sizable", FORCE_BOOL)
AccessorFunc(PANEL, "MinWidth", "MinWidth", FORCE_NUMBER)
AccessorFunc(PANEL, "MinHeight", "MinHeight", FORCE_NUMBER)
AccessorFunc(PANEL, "ScreenLock", "ScreenLock", FORCE_BOOL)
AccessorFunc(PANEL, "RemoveOnClose", "RemoveOnClose", FORCE_BOOL)

AccessorFunc(PANEL, "Title", "Title", FORCE_STRING)
AccessorFunc(PANEL, "ImgurID", "ImgurID", FORCE_STRING)

lyx.RegisterFont("UI.FrameTitle", "Open Sans Bold", 24)

function PANEL:Init()
	self.CloseButton = vgui.Create("lyx.ImgurButton2", self)
	self.CloseButton:SetImgurID("z1uAU0b")
	self.CloseButton:SetNormalColor(lyx.Colors.PrimaryText)
	self.CloseButton:SetHoverColor(lyx.Colors.Negative)
	self.CloseButton:SetClickColor(lyx.Colors.Negative)
	self.CloseButton:SetDisabledColor(lyx.Colors.DisabledText)
	-- self.CloseButton:AddCustomSound("buttons/button15.wav")

	self.padding = lyx.Scale(10)

	self.CloseButton.DoClick = function(s)
		self:Close()
	end

	self.ExtraButtons = {}

	self:SetTitle("lyx Frame")

	self:SetDraggable(true)
	self:SetScreenLock(true)
	self:SetRemoveOnClose(true)

	local size = lyx.Scale(200)
	self:SetMinWidth(size)
	self:SetMinHeight(size)

	local oldMakePopup = self.MakePopup
	function self:MakePopup()
		oldMakePopup(self)
		self:Open()
	end
end

function PANEL:DragThink(targetPanel, hoverPanel)
	local scrw, scrh = ScrW(), ScrH()
	local mousex, mousey = math.Clamp(gui.MouseX(), 1, scrw - 1), math.Clamp(gui.MouseY(), 1, scrh - 1)

	if targetPanel.Dragging then
		local x = mousex - targetPanel.Dragging[1]
		local y = mousey - targetPanel.Dragging[2]

		if targetPanel:GetScreenLock() then
			x = math.Clamp(x, 0, scrw - targetPanel:GetWide())
			y = math.Clamp(y, 0, scrh - targetPanel:GetTall())
		end

		targetPanel:SetPos(x, y)
	end

	local _, screenY = targetPanel:LocalToScreen(0, 0)
	if (hoverPanel or targetPanel).Hovered and targetPanel:GetDraggable() and mousey < (screenY + lyx.Scale(30)) then
		targetPanel:SetCursor("sizeall")
		return true
	end
end

function PANEL:SizeThink(targetPanel, hoverPanel)
	local scrw, scrh = ScrW(), ScrH()
	local mousex, mousey = math.Clamp(gui.MouseX(), 1, scrw - 1), math.Clamp(gui.MouseY(), 1, scrh - 1)

	if targetPanel.Sizing then
		local x = mousex - targetPanel.Sizing[1]
		local y = mousey - targetPanel.Sizing[2]
		local px, py = targetPanel:GetPos()

		local screenLock = self:GetScreenLock()
		if x < targetPanel.MinWidth then x = targetPanel.MinWidth elseif x > scrw - px and screenLock then x = scrw - px end
		if y < targetPanel.MinHeight then y = targetPanel.MinHeight elseif y > scrh - py and screenLock then y = scrh - py end

		targetPanel:SetSize(x, y)
		targetPanel:SetCursor("sizenwse")
		return true
	end

	local screenX, screenY = targetPanel:LocalToScreen(0, 0)
	if (hoverPanel or targetPanel).Hovered and targetPanel.Sizable and mousex > (screenX + targetPanel:GetWide() - lyx.Scale(20)) and mousey > (screenY + targetPanel:GetTall() - lyx.Scale(20)) then
		(hoverPanel or targetPanel):SetCursor("sizenwse")
		return true
	end
end

function PANEL:Think()
	if self:DragThink(self) then return end
	if self:SizeThink(self) then return end

	self:SetCursor("arrow")

	if self.y < 0 then
		self:SetPos(self.x, 0)
	end
end

function PANEL:OnMousePressed()
	local screenX, screenY = self:LocalToScreen(0, 0)
	local mouseX, mouseY = gui.MouseX(), gui.MouseY()

	if self.Sizable and mouseX > (screenX + self:GetWide() - lyx.Scale(30)) and mouseY > (screenY + self:GetTall() - lyx.Scale(30)) then
		self.Sizing = {mouseX - self:GetWide(), mouseY - self:GetTall()}
		self:MouseCapture(true)
		return
	end

	if self:GetDraggable() and mouseY < (screenY + lyx.Scale(30)) then
		self.Dragging = {mouseX - self.x, mouseY - self.y}
		self:MouseCapture(true)
		return
	end
end

function PANEL:OnMouseReleased()
	self.Dragging = nil
	self.Sizing = nil
	self:MouseCapture(false)
end

function PANEL:CreateSidebar(defaultItem, imgurID, imgurScale, imgurYOffset, buttonYOffset)
	if IsValid(self.SideBar) then return end
	self.SideBar = vgui.Create("lyx.Sidebar2", self)

	if defaultItem then
		timer.Simple(0, function()
			if not IsValid(self.SideBar) then return end
			self.SideBar:SelectItem(defaultItem)
		end)
	end

	if imgurID then self.SideBar:SetImgurID(imgurID) end
	if imgurScale then self.SideBar:SetImgurScale(imgurScale) end
	if imgurYOffset then self.SideBar:SetImgurOffset(imgurYOffset) end
	if buttonYOffset then self.SideBar:SetButtonOffset(buttonYOffset) end

	return self.SideBar
end

function PANEL:AddHeaderButton(elem, size)
	elem.HeaderIconSize = size or .45
	return table.insert(self.ExtraButtons, elem)
end

function PANEL:LayoutContent(w, h) end

function PANEL:PerformLayout(w, h)
	local headerH = lyx.Scale(40)
	local btnPad = lyx.Scale(12)
	local btnSpacing = lyx.Scale(6)

	if IsValid(self.CloseButton) then
		local btnSize = headerH * .45
		self.CloseButton:SetSize(btnSize, btnSize)
		self.CloseButton:SetPos(w - btnSize - btnPad, (headerH - btnSize) * 0.5)

		btnPad = btnPad + btnSize + btnSpacing
	end

	for _, btn in ipairs(self.ExtraButtons) do
		local btnSize = headerH * btn.HeaderIconSize
		btn:SetSize(btnSize, btnSize)
		btn:SetPos(w - btnSize - btnPad, (headerH - btnSize) * 0.5)
		btnPad = btnPad + btnSize + btnSpacing
	end

	if IsValid(self.SideBar) then
		self.SideBar:SetPos(0, headerH)
		self.SideBar:SetSize(lyx.Scale(200), h - headerH)
	end

	self:DockPadding(self.SideBar and lyx.Scale(200) + self.padding or self.padding, headerH + self.padding, self.padding, self.padding)

	self:LayoutContent(w, h)
end

function PANEL:Open()
	self:SetAlpha(0)
	self:SetVisible(true)
	self:AlphaTo(255, .1, 0)
end

function PANEL:Close()
	self:AlphaTo(0, .1, 0, function(anim, pnl)
		if not IsValid(pnl) then return end
		pnl:SetVisible(false)
		pnl:OnClose()
		surface.PlaySound("buttons/button15.wav")
		if pnl:GetRemoveOnClose() then pnl:Remove() end
	end)
end

function PANEL:OnClose() end

function PANEL:PaintHeader(x, y, w, h)
	lyx.DrawRoundedBoxEx(lyx.Scale(6), x, y, w, h, lyx.Colors.Header, true, true)

	local imgurID = self:GetImgurID()
	if imgurID then
		local iconSize = h * .6
		lyx.DrawImgur(lyx.Scale(6), x + (h - iconSize) * 0.5, y + iconSize, iconSize, imgurID, color_white)
		lyx.DrawSimpleText(self:GetTitle(), "UI.FrameTitle", x + lyx.Scale(16) + iconSize, y + h * 0.5, lyx.Colors.PrimaryText, nil, TEXT_ALIGN_CENTER)
		return
	end

	lyx.DrawSimpleText(self:GetTitle(), "UI.FrameTitle", x + lyx.Scale(8), y + h * 0.5, lyx.Colors.PrimaryText, nil, TEXT_ALIGN_CENTER)
end

function PANEL:Paint(w, h)
	lyx.DrawRoundedBox(lyx.Scale(4), 0, 0, w, h, lyx.Colors.Background)
	self:PaintHeader(0, 0, w, lyx.Scale(40))
end

vgui.Register("lyx.Frame2", PANEL, "EditablePanel")

concommand.Add("lyx_test_frame", function()
	local frame = vgui.Create("lyx.Frame2")
	frame:SetSize(lyx.Scale(400), lyx.Scale(300))
	frame:Center()
	frame:MakePopup()
end)
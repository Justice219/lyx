local PANEL = {}

lyx.RegisterFont("Lyx.Title", "Open Sans SemiBold", 20)
surface.CreateFont( "Lyx.Title", {
	font = "Open Sans SemiBold", --  Use the font-name which is shown to you by your operating system Font Viewer, not the file name
	extended = false,
	size = 20,
	weight = 500,
} )

function PANEL:Init()
    self.ScrollPanel = vgui.Create("lyx.ScrollPanel2", self)
    self.ScrollPanel:Dock(FILL)

    self.fieldPanels = {}

    self.copiedColor = color_white
end

function PANEL:AddCheckbox(label, value, onChange)
    if (!self.ScrollPanel) then 
        self.ScrollPanel = vgui.Create("lyx.ScrollPanel2", self)
        self.ScrollPanel:Dock(FILL)
    end

    local pnl = vgui.Create("DPanel", self.ScrollPanel)
    pnl:Dock(TOP)
    pnl:DockMargin(0, 0, lyx.ScaleW(5), lyx.Scale(5))
    pnl:SetTall(lyx.Scale(30))
    pnl.Paint = function(self, w, h)
        draw.RoundedBox(4, 0, 0, w, h, lyx.Colors.Foreground)
        draw.SimpleText(label, "Lyx.Title", lyx.ScaleW(10), h * 0.5, color_white, 0, 1)
    end
    self.ScrollPanel:AddItem(pnl)

    local pnlCheckbox = vgui.Create("lyx.Checkbox2", pnl)
    pnlCheckbox:SetPos(pnl:GetWide() - lyx.ScaleW(30), lyx.Scale(5))
    pnlCheckbox:SetToggle(value)
    pnlCheckbox.OnToggled = function(self, val)
        onChange(val)
    end

    table.insert(self.fieldPanels, {
        pnl = pnl,
        checkbox = pnlCheckbox
    })
end

function PANEL:AddColorMixer(label, value, onChange, defaultColor)
    if (!self.ScrollPanel) then 
        self.ScrollPanel = vgui.Create("lyx.ScrollPanel2", self)
        self.ScrollPanel:Dock(FILL)
    end

    local pnl = vgui.Create("DPanel", self.ScrollPanel)
    pnl:Dock(TOP)
    pnl:DockMargin(0, 0, lyx.ScaleW(5), lyx.Scale(5))
    pnl:SetTall(30)
    pnl.Paint = function(self, w, h)
        draw.RoundedBox(4, 0, 0, w, h, lyx.Colors.Foreground)
        draw.SimpleText(label, "Lyx.Title", lyx.ScaleW(10), lyx.Scale(15), color_white, 0, 1)
    end
    self.ScrollPanel:AddItem(pnl)

    local editValue = value or color_white
    local pnlColorMixer = vgui.Create("lyx.ColorPicker2", pnl)
    pnlColorMixer:SetColor(value)
    pnlColorMixer.OnChange = function(self, val)
        editValue = val
    end

    local colorPnl = vgui.Create("DPanel", pnl)
    colorPnl:SetSize(lyx.ScaleW(90), lyx.Scale(90))
    colorPnl:SetPos(pnl:GetWide() - lyx.ScaleW(100), pnl:GetTall()*0.5-lyx.Scale(45))
    colorPnl.Paint = function(self, w, h)
        draw.RoundedBox(4, 0, 0, w, h, editValue)
    end

    local pasteBtn = vgui.Create("lyx.TextButton2", pnl)
    pasteBtn:SetSize(lyx.ScaleW(60), lyx.Scale(20))
    pasteBtn:SetText("Set")
    pasteBtn:SetFont("Lyx.Title")
    pasteBtn:AddClickSound()
    pasteBtn.DoClick = function()
        onChange(editValue)
    end

    
    local alphaSlider = vgui.Create("lyx.Slider2", pnl)
    alphaSlider:SetPos(pnl:GetWide() - 100, 75)
    alphaSlider:SetSize(lyx.ScaleW(60), lyx.Scale(25))
    alphaSlider.OnValueChanged = function(self, val)
        editValue.a = val * 255
        pnlColorMixer:SetColor(editValue)
        onChange(editValue)
    end
    alphaSlider.Fraction = editValue.a / 255

    local resetBtn = vgui.Create("lyx.TextButton2", pnl)
    resetBtn:SetPos(lyx.ScaleW(10), lyx.Scale(80))
    resetBtn:SetSize(lyx.ScaleW(60), lyx.Scale(20))
    resetBtn:SetText("Reset")
    resetBtn:SetFont("Lyx.Title")
    resetBtn:AddClickSound()
    resetBtn.DoClick = function()
        local resetColor = defaultColor
        pnlColorMixer:SetColor(resetColor)
        onChange(resetColor)
        editValue = resetColor
        alphaSlider.Fraction = resetColor.a / 255
    end

    table.insert(self.fieldPanels, {
        pnl = pnl,
        colorMixer = pnlColorMixer,
        colorPnl = colorPnl,
        copyBtn = copyBtn,
        pasteBtn = pasteBtn,
        alphaSlider = alphaSlider
    })
end

function PANEL:AddNumericalField(label, value, min, max, onChange)
    if (!self.ScrollPanel) then 
        self.ScrollPanel = vgui.Create("lyx.ScrollPanel2", self)
        self.ScrollPanel:Dock(FILL)
    end

    local pnl = vgui.Create("DPanel", self.ScrollPanel)
    pnl:Dock(TOP)
    pnl:DockMargin(lyx.ScaleW(0), lyx.Scale(0), lyx.ScaleW(5), lyx.Scale(5))
    pnl:SetTall(lyx.Scale(30))
    pnl.Paint = function(self, w, h)
        draw.RoundedBox(4, 0, 0, w, h, lyx.Colors.Foreground)
        draw.SimpleText(label, "Lyx.Title", lyx.ScaleW(10), h * 0.5, color_white, 0, 1)
    end
    self.ScrollPanel:AddItem(pnl)

    local pnlNumField = vgui.Create("lyx.TextEntry2", pnl)
    pnlNumField:SetPos(pnl:GetWide() - lyx.ScaleW(100), lyx.Scale(5))
    pnlNumField:SetValue(value)
    pnlNumField:SetNumeric(true)
    pnlNumField.OnValueChange = function(self, val)
        onChange(val)
    end
    
    local pnlSlider = vgui.Create("lyx.Slider2", pnl)
    pnlSlider:SetPos(lyx.ScaleW(10), lyx.Scale(30))
    pnlSlider:SetWide(pnl:GetWide() - lyx.ScaleW(120))
    pnlSlider.OnValueChanged = function(self, val)
        local changedVal = val * (max - min) + min
        changedVal = math.floor(changedVal)
        pnlNumField:SetValue(changedVal)
        onChange(changedVal)
    end
    pnlSlider.Fraction = (value - min) / (max - min)

    table.insert(self.fieldPanels, {
        pnl = pnl,
        numField = pnlNumField,
        slider = pnlSlider
    })

    return pnlSlider, pnlNumField
end

function PANEL:AddTextField(label, value, onChange)
    if (!self.ScrollPanel) then 
        self.ScrollPanel = vgui.Create("lyx.ScrollPanel2", self)
        self.ScrollPanel:Dock(FILL)
    end

    local pnl = vgui.Create("DPanel", self.ScrollPanel)
    pnl:Dock(TOP)
    pnl:DockMargin(0, 0, lyx.Scale(5), lyx.Scale(5))
    pnl:SetTall(lyx.ScaleW(50))
    pnl.Paint = function(self, w, h)
        draw.RoundedBox(4, 0, 0, w, h, lyx.Colors.Foreground)
        draw.SimpleText(label, "Lyx.Title", lyx.ScaleW(10), h * 0.5, color_white, 0, 1)
    end
    self.ScrollPanel:AddItem(pnl)

    local pnlTextField = vgui.Create("lyx.TextEntry2", pnl)
    pnlTextField:SetPos(pnl:GetWide() - lyx.ScaleW(100), lyx.Scale(5))
    pnlTextField:SetValue(value)
    pnlTextField:SetWide(lyx.ScaleW(120))
    pnlTextField:SetTall(lyx.Scale(30))
    pnlTextField:SetUpdateOnType(true)
    pnlTextField.OnValueChange = function(self, val)
        onChange(val)
    end

    table.insert(self.fieldPanels, {
        pnl = pnl,
        textField = pnlTextField
    })
end

function PANEL:AddComboBox(label, value, values, onChange)
    if (!self.ScrollPanel) then 
        self.ScrollPanel = vgui.Create("lyx.ScrollPanel2", self)
        self.ScrollPanel:Dock(FILL)
    end

    local pnl = vgui.Create("DPanel", self.ScrollPanel)
    pnl:Dock(TOP)
    pnl:DockMargin(0, 0, lyx.ScaleW(5), lyx.Scale(5))
    pnl:SetTall(lyx.Scale(35))
    pnl.Paint = function(self, w, h)
        draw.RoundedBox(4, 0, 0, w, h, lyx.Colors.Foreground)
        draw.SimpleText(label, "Lyx.Title", lyx.ScaleW(10), h * 0.5, color_white, 0, 1)
    end
    self.ScrollPanel:AddItem(pnl)

    local pnlComboBox = vgui.Create("lyx.ComboBox2", pnl)
    pnlComboBox:Dock(RIGHT)
    pnlComboBox:DockMargin(0, lyx.Scale(3), lyx.ScaleW(4), lyx.Scale(5))
    pnlComboBox:SetValue(value)
    pnlComboBox.OnSelect = function(s, index, val)
        onChange(val)
    end
    for k,v in pairs(values) do
        pnlComboBox:AddChoice(v)
    end

    table.insert(self.fieldPanels, {
        pnl = pnl,
        comboBox = pnlComboBox
    })
end

function PANEL:AddButton(label, onClick)
    if (!self.ScrollPanel) then 
        self.ScrollPanel = vgui.Create("lyx.ScrollPanel2", self)
        self.ScrollPanel:Dock(FILL)
    end

    local pnl = vgui.Create("lyx.TextButton2", self.ScrollPanel)
    pnl:Dock(TOP)
    pnl:DockMargin(0, 0, lyx.ScaleW(5), lyx.Scale(5))
    pnl:SetTall(lyx.Scale(35))
    pnl:SetText(label)
    self.ScrollPanel:AddItem(pnl)

    pnl.DoClick = function(self)
        onClick()
    end

    table.insert(self.fieldPanels, {
        pnl = pnl
    })
end

function PANEL:AddLabel(label)
    if (!self.ScrollPanel) then 
        self.ScrollPanel = vgui.Create("lyx.ScrollPanel2", self)
        self.ScrollPanel:Dock(FILL)
    end

    local pnl = vgui.Create("DPanel", self.ScrollPanel)
    pnl:Dock(TOP)
    pnl:DockMargin(0, 0, lyx.ScaleW(5), lyx.Scale(5))
    pnl:SetTall(lyx.Scale(40))
    pnl.Paint = function(self, w, h)
        draw.RoundedBox(4, 0, 0, w, h, lyx.Colors.Foreground)
        draw.SimpleText(label, "Lyx.Title", w * 0.5, h * 0.5, color_white, 1, 1)
    end
    self.ScrollPanel:AddItem(pnl)

    table.insert(self.fieldPanels, {
        pnl = pnl
    })
end

function PANEL:PerformLayout(w, h)
    for k,v in pairs(self.fieldPanels) do
        if (v.checkbox) then
            v.checkbox:SetPos(v.pnl:GetWide() - lyx.ScaleW(30), v.pnl:GetTall()*0.5-lyx.Scale(9))
        end

        if (v.colorMixer) then
            v.pnl:SetTall(110)
            v.colorMixer:SetSize(lyx.ScaleW(90), lyx.Scale(90))
            v.colorMixer:SetPos(v.pnl:GetWide() - lyx.ScaleW(100), v.pnl:GetTall()*0.5-lyx.Scale(45))
        end
        if (v.colorPnl) then
            v.colorPnl:SetSize(30, 30)
            v.colorPnl:SetPos(v.pnl:GetWide() - lyx.ScaleW(150), v.pnl:GetTall()*0.5-lyx.Scale(20))
        end

        if (v.numField) then
            v.numField:SetPos(v.pnl:GetWide() - lyx.ScaleW(80), v.pnl:GetTall()*0.5-lyx.Scale(12))
        end

        if (v.textField) then
            v.textField:SetPos(v.pnl:GetWide() - lyx.ScaleW(125), v.pnl:GetTall()*0.5-lyx.Scale(15))
        end

        if (v.slider) then
            v.slider:SetWide(lyx.ScaleW(80))
            v.slider:SetTall(lyx.Scale(10))
            v.slider:SetPos(w*0.44, lyx.Scale(10))
        end

        if (v.alphaSlider) then
            v.alphaSlider:SetWide(lyx.ScaleW(80))
            v.alphaSlider:SetTall(10)
            v.alphaSlider:SetPos(w*0.33, lyx.Scale(90))
        end

        if (v.copyBtn) then
            v.copyBtn:SetPos(lyx.ScaleW(10), lyx.Scale(30))
        end

        if (v.pasteBtn) then
            v.pasteBtn:SetPos(lyx.ScaleW(10), lyx.Scale(55))
        end

        if (v.resetBtn) then
            v.resetBtn:SetPos(lyx.ScaleW(10), lyx.Scale(80))
        end

    end
end

vgui.Register("lyx.PageBase", PANEL)
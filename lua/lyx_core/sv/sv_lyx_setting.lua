lyx = lyx

do
    function lyx:LoadSettings()
        local settings = lyx:JSONLoad("lyx_settings.txt")
        if not settings then
            lyx.Logger:Log("No settings to load!")
        return end
    
        local tbl = {}
        for k, v in pairs(settings) do
            tbl[k] = v
        end
    
        lyx.Logger:Log("Settings loaded!")
        return tbl
    end
    
    function lyx:SetSetting(key, value)
        local settings = lyx:LoadSettings()
        if settings then
            settings[key] = value
            lyx:JSONSave("lyx_settings.txt", settings)
        else
            local tbl = {}
            tbl[key] = value
            lyx:JSONSave("lyx_settings.txt", tbl)
        end
    end
    
    function lyx:GetSetting(key)
        local settings = lyx:LoadSettings()
        if settings then
            return settings[key]
        else
            lyx.Logger:Log("No settings to load!")
            return false
        end
    end
    
    function lyx:RemoveSetting(key)
        local settings = lyx:LoadSettings()
        if settings then
            settings[key] = nil
            lyx:JSONSave("lyx_settings.txt", settings)
        else
            lyx.Logger:Log("No settings to load!")
        end
    end 
end
do
    function lyx.CompressTable(tbl)
        if (type(tbl) == "table") then return util.Compress(util.TableToJSON(tbl)) end
        if (type(tbl) == "string") then return tbl end

        lyx.Logger:Warn("lyx.CompressTable: Invalid type: " .. type(tbl) .. " (" .. tostring(tbl) .. ")")
        return ""
    end

    function lyx.UnCompressTable(tbl)
        if (type(tbl) == "table") then return tbl end
        if (type(tbl) == "string") then return util.JSONToTable(util.Decompress(tbl)) end
    
        lyx.Logger:Warn("lyx.UnCompressTable: Invalid type: " .. type(tbl) .. " (" .. tostring(tbl) .. ")")
        return {}
    end
end
do
    function lyx.DrawTexturedRect(x, y, w, h, mat, color)
        surface.SetDrawColor(color)
        surface.SetMaterial(mat)
        surface.DrawTexturedRect(x, y, w, h)
    end
end
do
    function lyx.DownloadWorkshop(workshopId, callback)
        steamworks.DownloadUGC(workshopId, function(path)
            if (!path) then print("Failed to download workshop content") return end
            game.MountGMA(path)
            if (callback) then callback() end
        end)
    end
end
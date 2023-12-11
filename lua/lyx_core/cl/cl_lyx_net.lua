lyx = lyx

lyx:NetAdd("lyx:sync:request", {
    func = function()
        lyx.ranks = net.ReadTable()
        lyx.addons = net.ReadTable()
    
        lyx.Logger:Log("Synced data from the server")
    end
})

concommand.Add("lyx_print_table", function()
    PrintTable(lyx.ranks)
end)
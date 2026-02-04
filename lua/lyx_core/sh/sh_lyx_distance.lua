do
    lyx.USE_DISTANCE = 7000
    lyx.VIEW_DISTANCE = 500000

    function lyx.InDistance(entA, entB, distance)
        local firstPos
        local secondPos

        if (isentity(entA)) then
            firstPos = entA:GetPos()
        else
            firstPos = entA
        end

        if (isentity(entB)) then
            secondPos = entB:GetPos()
        else
            secondPos = entB
        end

        if (firstPos:DistToSqr(secondPos) <= distance) then
            return true
        end
        return false
    end
end
-- local UEActorHelper = require("UEActorHelper")
local ActorTriggerGroupHelper = {}

function ActorTriggerGroupHelper.CreateTriggerGroup(pUEActor, nRadius, nInterval, nOffsetHeight, bCheckBounds)
    if bCheckBounds == nil then
        bCheckBounds = false
    end
    local AreaTriggerManager = ClientShell.GetClient(GWorld):GetActorTriggerGroupManager()
    local nTriggerGroupId = nil
    if nOffsetHeight == nil then
        nTriggerGroupId = AreaTriggerManager:CreateTriggerGroup(pUEActor, nRadius, nInterval, bCheckBounds)
    else
        nTriggerGroupId = AreaTriggerManager:CreateTriggerGroupWithOffsetHeight(pUEActor, nRadius, nInterval, nOffsetHeight, bCheckBounds)
    end

    -- log("ActorTriggerGroupHelper.CreateTriggerGroup ", nTriggerGroupId)
    return nTriggerGroupId
end

function ActorTriggerGroupHelper.DestroyTriggerGroup(nTriggerGroupId)
    local AreaTriggerManager = ClientShell.GetClient(GWorld):GetActorTriggerGroupManager()
    -- log("ActorTriggerGroupHelper.DestroyTriggerGroup ", nTriggerGroupId)
    return AreaTriggerManager:DestroyTriggerGroup(nTriggerGroupId)
end

function ActorTriggerGroupHelper.AddTriggerInGroup(nTriggerGroupId, pUEActor)
    if nTriggerGroupId ~= nil then
        local AreaTriggerManager = ClientShell.GetClient(GWorld):GetActorTriggerGroupManager()
        -- log("ActorTriggerGroupHelper.AddTriggerInGroup ", nTriggerGroupId, UEActorHelper:GetActorUniqueId(pUEActor))
        return AreaTriggerManager:AddTriggerInGroup(nTriggerGroupId, pUEActor)
    else
        log("ActorTriggerGroupHelper.AddTriggerInGroup groupid is nil")
    end 
end

function ActorTriggerGroupHelper.RemoveTriggerInGroup(nTriggerGroupId, pUEActor)
    if nTriggerGroupId ~= nil then
        local AreaTriggerManager = ClientShell.GetClient(GWorld):GetActorTriggerGroupManager()
        -- log("ActorTriggerGroupHelper.RemoveTriggerInGroup ", nTriggerGroupId, UEActorHelper:GetActorUniqueId(pUEActor))
        return AreaTriggerManager:RemoveTriggerInGroup(nTriggerGroupId, pUEActor)
    else
        log("ActorTriggerGroupHelper.RemoveTriggerInGroup groupid is nil")
    end
end

return ActorTriggerGroupHelper
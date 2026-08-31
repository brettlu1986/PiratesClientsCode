local SAIMisc = { }

function SAIMisc:FireEvent(tbGameObject, szEventName, ...)
    local tbOwner = tbGameObject.SAIComponent
    if tbOwner then
        local tbEventProcessor = tbOwner[szEventName]
        if not tbEventProcessor then
            tbOwner = tbOwner:GetLogic()
            tbEventProcessor = tbOwner and tbOwner[szEventName] or nil
        end
        if tbEventProcessor then
            tbEventProcessor(tbOwner, ...)
        -- else
        --     logerror("ai perception event function not found.", szEventName)
        end
    end
end



function SAIMisc:CanUseWeapon(tbGameObject, nTemplateId)
    return tbGameObject.SAIComponent:CanUseWeapon(nTemplateId)
end

function SAIMisc:GetWeaponConfig(tbGameObject, nTemplateId)
    return tbGameObject.SAIComponent:GetWeaponConfig(nTemplateId)
end

function SAIMisc:Distance(nSourceX, nSourceY, nTargetX, nTargetY)
    return math.sqrt((nTargetX - nSourceX) ^ 2 + (nTargetY - nSourceY) ^ 2)
end

return SAIMisc
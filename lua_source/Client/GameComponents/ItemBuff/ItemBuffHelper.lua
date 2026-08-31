local ItemBuffHelper = {}

local GamePlayerSelfHelper = require("GamePlayerSelfHelper")
local BuffDataTable = require("BuffDataTable")
local Proto = require("ClientProtoNames")
local NetworkManager = dynamic_require("NetworkManager")
local GlobalVariableSystem = require("GlobalVariableSystem_C")

function ItemBuffHelper.SetItemBuffData(tbBuffs)
    local PlayerSelf = GamePlayerSelfHelper:Get()
    if PlayerSelf then
        PlayerSelf.ItemBuffComponent:SetItemBuffs(tbBuffs)
    end
end

function ItemBuffHelper.GetItemBuffs()
    local PlayerSelf = GamePlayerSelfHelper:Get()
    if PlayerSelf then   
        return PlayerSelf.ItemBuffComponent:GetItemBuffs()
    end
    return nil
end

function ItemBuffHelper.IsBuffValid(tbBuff)
    local tbTemplate = ItemBuffHelper.GetBuffTemplate(tbBuff.id)
    if tbTemplate.bCountType then
        return tbBuff.unit ~= 0
    else  
        local now = GlobalVariableSystem:GetServerTimeUtc()
        return tbBuff.unit > now
    end
end

function ItemBuffHelper.HasValidBuffs() 
    local tbBuffs = ItemBuffHelper.GetItemBuffs()
    if tbBuffs then   
        local bValid = false
        for _,  v in pairs(tbBuffs) do  
            bValid = ItemBuffHelper.IsBuffValid(v)
            if bValid then  
                break
            end
        end
        return bValid
    end
    return false
end


function ItemBuffHelper.GetBuffTemplate(nBuffId)
    return BuffDataTable:GetTemplate(nBuffId)
end

function ItemBuffHelper.RequestToRefreshItemBuffs()
    NetworkManager:GetHubServerProxy():SendPacket(Proto.c2s_GetBuff, {})
end

function ItemBuffHelper.GetBuffTimeLeft(nTimeStamp)
    local now = GlobalVariableSystem:GetServerTimeUtc()
    if nTimeStamp > now then  
        return nTimeStamp - now  
    end
    return 0
end

return ItemBuffHelper
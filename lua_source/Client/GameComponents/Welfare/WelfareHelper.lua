local WelfareHelper = {}

local Proto = require("ClientProtoNames")
local NetworkManager = dynamic_require("NetworkManager")
local GamePlayerSelfHelper = require("GamePlayerSelfHelper")
local TimeUtil = require("TimeUtil")

local function GetSelfWelfareComponent()
    local PlayerSelf = GamePlayerSelfHelper:Get()
    if PlayerSelf and PlayerSelf.WelfareComponent then   
        return PlayerSelf.WelfareComponent
    end
    return nil
end

function WelfareHelper.RequestGetVipAwardDetails()
    NetworkManager:GetHubServerProxy():SendPacket(Proto.c2s_GetVipAwardDetails, {})
end

function WelfareHelper.RequestGetVipAward(nType)
    local c2s_GetVipAward =
    {
        type = nType
    }
    NetworkManager:GetHubServerProxy():SendPacket(Proto.c2s_GetVipAward, c2s_GetVipAward)
end

function WelfareHelper.AddWelfareItemData(tbItemData)
    local WelfareComponent = GetSelfWelfareComponent()
    if WelfareComponent then   
        WelfareComponent:AddWelfareItem(tbItemData)
    end
end

function WelfareHelper.GetAllWelfareItems()
    local WelfareComponent = GetSelfWelfareComponent()
    if WelfareComponent then   
        return WelfareComponent:GetWelfareItems()
    end
    return nil
end

function WelfareHelper.HasCanGetWelfare()
    local WelfareComponent = GetSelfWelfareComponent()
    local bCanGet = false
    if WelfareComponent then   
        local tbWelfareItems = WelfareComponent:GetWelfareItems()
        for _, v in pairs(tbWelfareItems) do  
            local bCanGetToday = TimeUtil.GetDayOfYearOffset(v.receive_timestamp) >= 1 and v.remain_times > 0
            if bCanGetToday then   
                bCanGet = true
                break
            end
        end
    end
    return bCanGet
end


return WelfareHelper
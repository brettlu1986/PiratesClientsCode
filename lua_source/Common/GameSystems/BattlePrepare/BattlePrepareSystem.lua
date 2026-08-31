-- 负责进入战斗前的准备工作，如数据缓存等
local BattlePrepareSystem = {}

local BattlePlayerPrepareInfo = require("BattlePlayerPrepareInfo")

BattlePrepareSystem.tbPlayerPrepareInfoMap = {}
BattlePrepareSystem.tbBotPrepareInfoArray = {}

function BattlePrepareSystem:Init()

end

function BattlePrepareSystem:Uninit()
    self:Clear()
end

function BattlePrepareSystem:GetAllPlayerPrepareInfos()
   return self.tbPlayerPrepareInfoMap
end

function BattlePrepareSystem:AddPlayerPrepareInfo(tbPlayerPrepareInfo)
    self.tbPlayerPrepareInfoMap[tbPlayerPrepareInfo.nPlayerId] = tbPlayerPrepareInfo
    -- MockHumanFashionData(tbPlayerPrepareInfo)
end

function BattlePrepareSystem:RemovePlayerPrepareInfo(nPlayerId)
    self.tbPlayerPrepareInfoMap[nPlayerId] = nil
end

function BattlePrepareSystem:GetPlayerPrepareInfo(nPlayerId)
    return self.tbPlayerPrepareInfoMap[nPlayerId]
end

function BattlePrepareSystem:SetShipTemplateId(nPlayerId, nShipTemplateId)
    local tbPrepareInfo = self:GetPlayerPrepareInfo(nPlayerId)
    if tbPrepareInfo then
        local tbShipInfo = tbPrepareInfo.tbShipInfo
        tbShipInfo.nTypeId = nShipTemplateId
    end
end

function BattlePrepareSystem:BotEmpty()
    return #self.tbBotPrepareInfoArray == 0
end

function BattlePrepareSystem:AddBotPrepareInfo(tbBotPrepareInfo)
    table.insert(self.tbBotPrepareInfoArray, tbBotPrepareInfo)
end

function BattlePrepareSystem:GetBots()
    return self.tbBotPrepareInfoArray
end

function BattlePrepareSystem:Clear()
    self.tbPlayerPrepareInfoMap = {}
    self.tbBotPrepareInfoArray = {}
end

--返回playerid的玩家的身上所有时装的template id
function BattlePrepareSystem:GetFashionTemplateIds(nPlayerId)
    local tbPrepareInfo = self:GetPlayerPrepareInfo(nPlayerId)
    -- if not tbPrepareInfo then
    --     return {}
    -- end
    local tbResult = tbPrepareInfo.tbFashionItemTemplateIds
    if not tbResult then
        return {}
    end
    return tbResult
end

function BattlePrepareSystem:GetAppearancePartData(nPlayerId)
    local tbPrepareInfo = self:GetPlayerPrepareInfo(nPlayerId)
    return tbPrepareInfo.tbAppearancePartData
    -- if not tbPrepareInfo then
    --     return {}
    -- end
    -- local tbResult = tbPrepareInfo.tbDefaultAppearanceIds
    -- if not tbResult then
    --     return {}
    -- end
    -- return tbResult
end

function BattlePrepareSystem:CreatePlayerInfo(nPlayerId, szName, nHumanId,
    nGroupIndex, nToken, szPlayerSessionId)
    local tbRet = BattlePlayerPrepareInfo.Create(nPlayerId, szName, nHumanId,
        nGroupIndex, nToken, szPlayerSessionId)
    self:AddPlayerPrepareInfo(tbRet)
    return tbRet
end

function BattlePrepareSystem:IsBot(nPlayerId)
    local tbPrepareInfo = self.tbPlayerPrepareInfoMap[nPlayerId]
    if tbPrepareInfo then
        return tbPrepareInfo:IsBot()
    end
    return false
end

function BattlePrepareSystem:GetPlayerIdsByGroupIndex(nGroupIndex)
    local tbPlayerIds = {}
    for nPlayerId, tbPlayerPrepareInfo in pairs(self.tbPlayerPrepareInfoMap) do
        if tbPlayerPrepareInfo and tbPlayerPrepareInfo.nGroupIndex == nGroupIndex then
            table.insert( tbPlayerIds, nPlayerId )
        end
    end

    return tbPlayerIds
end

return BattlePrepareSystem
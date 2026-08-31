local BattleFFANoobHelper = {}

local BattleGameModeSystem = dynamic_require("BattleGameModeSystem")
local FFANoobDataTable = require("FFANoobDataTable")
local GameObjectSystem = dynamic_require("GameObjectSystem")
local GameObjectTypeDef = require("GameObjectTypeDef")
local BotAISystem = dynamic_require("BotAISystem")
local BattleItemSystemServer = require("BattleItemSystemServer")

BattleFFANoobHelper.bNoob = false                   -- 是否是新手副本
BattleFFANoobHelper.tbGetNoobItemsPlayerIds = nil   --领取过首次拾取礼包的玩家ids

function BattleFFANoobHelper:Init()
    self.tbGetNoobItemsPlayerIds = {}
end

function BattleFFANoobHelper:Uninit()
    self.tbGetNoobItemsPlayerIds = nil
end

function BattleFFANoobHelper:SetNoob(bNoob)
    self.bNoob = bNoob
end

function BattleFFANoobHelper:AddNoobSpecialBuffs()
    if not self.bNoob then
        return
    end

    local nDungeonId = BattleGameModeSystem.nDungeonId
    local tbNoobData = FFANoobDataTable:GetTemplate(nDungeonId)

    if not tbNoobData then
        return
    end

    local tbAddBuffs = tbNoobData.tbBuffs
    local tbBuffCounts = tbNoobData.tbBuffCounts

    local tbObjects = GameObjectSystem:GetAllByObjectType(GameObjectTypeDef.PlayerSelf)
    for Object, _ in pairs(tbObjects) do
        if not BotAISystem:IsBot(Object) and
           Object.BuffComponentServer then
            --add buff
            for nIndex,nBuffId in pairs(tbAddBuffs) do
                Object.BuffComponentServer:AddBuffById(nBuffId,tbBuffCounts[nIndex])
            end
        end
    end
end

function BattleFFANoobHelper:OnItemPickUp(tbPlayer, tbItem , bWaitStage)
    if self.bNoob and not bWaitStage then
        if tbPlayer.ObjectType == GameObjectTypeDef.PlayerSelf and
           not BotAISystem:IsBot(tbPlayer) then
            local nPlayerId = tbPlayer.nPlayerId
            if self.tbGetNoobItemsPlayerIds[nPlayerId] == nil then
                self.tbGetNoobItemsPlayerIds[nPlayerId] = true

                local nDungeonId = BattleGameModeSystem.nDungeonId
                local tbNoobData = FFANoobDataTable:GetTemplate(nDungeonId)

                if not tbNoobData then
                    return
                end

                local tbItemIds = tbNoobData.tbItemIds
                local tbItemCounts = tbNoobData.tbItemCounts

                for nIndex,nItemId in pairs(tbItemIds) do
                    BattleItemSystemServer:AddItemByTemplate(tbPlayer:GetServerInstanceId(),nItemId,tbItemCounts[nIndex])
                end
            end
        end
    end
end

function BattleFFANoobHelper:NoobBotSetting()
    if self.bNoob then
        local nSenderDlelayTime = 2 * 60
        BotAISystem.nBotSenderDelayTime = nSenderDlelayTime
        BotAISystem.bEnabeBotSender = false
    else
        BotAISystem.nBotSenderDelayTime = 0
        BotAISystem.bEnabeBotSender = true
    end
end

return BattleFFANoobHelper
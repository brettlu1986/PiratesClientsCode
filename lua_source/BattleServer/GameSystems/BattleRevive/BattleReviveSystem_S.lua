--复活系统
local luaclass = require("luaclass")
local BattleReviveSystemClass = require("BattleReviveSystem")
local BattleReviveSystem_S = luaclass("BattleReviveSystem_S", BattleReviveSystemClass)

local HubSenderManager = require("HubSenderManager_S")
local Proto = require("DungeonProtoNames")
local BattleGameModeSystem = dynamic_require("BattleGameModeSystem")
local ProtoDC = require("DungeonCommonProtoNames")
local GameObjectSystem = dynamic_require("GameObjectSystem")


function BattleReviveSystem_S:Init()
    BattleReviveSystem_S.super.Init(self)
    return true 
end


function BattleReviveSystem_S:Uninit()
    BattleReviveSystem_S.super.Uninit(self)
end


function BattleReviveSystem_S:OnReviveMode(nPlayerServerInstanceId, bBackCity)
    BattleReviveSystem_S.super.OnReviveMode(self, nPlayerServerInstanceId, bBackCity)
    local tbPlayer = GameObjectSystem:FindByInstanceId(nPlayerServerInstanceId)
    if tbPlayer ~= nil then
        if bBackCity then
            local tbGameMode = BattleGameModeSystem:GetGameMode()
            if tbGameMode ~= nil and tbPlayer ~= nil then
                tbGameMode:QuitDungeon(tbPlayer,ProtoDC.c2d_QuitDungeon_QuitReason.BACK_TO_PORT)
            end
        else 
            HubSenderManager:Send(Proto.d2s_RevivePlayer, { player_id = tbPlayer.nPlayerId }, tbPlayer.nPlayerId)
        end
    end
end


return BattleReviveSystem_S()
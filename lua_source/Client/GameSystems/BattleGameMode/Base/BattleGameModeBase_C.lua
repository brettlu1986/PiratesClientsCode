-- 纯单机副本用的
local luaclass = require("luaclass")
local BattleGameModeBaseClass = require("BattleGameModeBase")
local BattleGameModeBase_C = luaclass("BattleGameModeBase_C", BattleGameModeBaseClass)

local Proto = require("ClientProtoNames")
local NetworkManager = dynamic_require("NetworkManager")

function BattleGameModeBase_C:CreatePlayerSelf(tbPrepareInfo, pController,
        nControllerNetGuid, nControllerUniqueId)

    self.tbGameState.rGameStateBaseInfo.Rep()

    local tbPlayerSelf = BattleGameModeBase_C.super.CreatePlayerSelf(self, tbPrepareInfo, pController,
        nControllerNetGuid, nControllerUniqueId)
    if(tbPlayerSelf) then
        tbPlayerSelf:OnEnterBattle()
    end
    return tbPlayerSelf
end

function BattleGameModeBase_C:OnAllStepFinished()
    -- 发消息给hub

    BattleGameModeBase_C.super.OnAllStepFinished(self)
end

function BattleGameModeBase_C:QuitDungeon(tbPlayer, nQuitReason)
    BattleGameModeBase_C.super.QuitDungeon(self, tbPlayer, nQuitReason)
    local Socket = NetworkManager:GetHubServerProxy()
    return Socket:SendPacket(Proto.c2s_QuitLocalDungeon)
end

function BattleGameModeBase_C:LeaveDungeon(tbPlayer)
    BattleGameModeBase_C.super.LeaveDungeon(self, tbPlayer)
    local Socket = NetworkManager:GetHubServerProxy()
    return Socket:SendPacket(Proto.c2s_LeaveLocalDungeon)
end

function BattleGameModeBase_C:StartFirstStep()
    BattleGameModeBase_C.super.StartFirstStep(self)

    -- 单机副本需要强制rep一把
    self.bRepBaseInfoWhenSnapshot = false
    self:SnapshotGameState()
    self.tbGameState:ReplicateNow()
end

function BattleGameModeBase_C:OnPlayerLogin(tbGamePlayer)
    BattleGameModeBase_C.super.OnPlayerLogin(self, tbGamePlayer)
end

return BattleGameModeBase_C

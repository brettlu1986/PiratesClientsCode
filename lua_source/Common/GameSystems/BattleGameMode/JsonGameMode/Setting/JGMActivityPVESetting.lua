local luaclass = require("luaclass")
local JGMCommonSetting = dynamic_require("JGMCommonSetting")
local JGMActivityPVESetting = luaclass("JGMActivityPVESetting", JGMCommonSetting)

local EventManager = require("EventManager")
local CommonEventDef = require("CommonEventDef")
local DungeonQuitDialogType = require("DungeonQuitDialogType")
local GlobalVariableSystem = dynamic_require("GlobalVariableSystem")
local BattleReviveModeTypeDef = require("BattleReviveModeTypeDef")
local BattleResultStep = dynamic_require("BattleActivityPVEResultStep")
local GameObjectTypeDef = require("GameObjectTypeDef")

function JGMActivityPVESetting:Init(tbGameMode)
    assert(not GlobalVariableSystem:IsClient(), "Enter Dungeon mode error")

    if(not JGMActivityPVESetting.super.Init(self, tbGameMode)) then
        return false
    end

    EventManager:BindEventMethod(CommonEventDef.EV_GAME_OBJECT_ON_PAWN_DEAD, self, self.OnPawnDead)

    return true
end

function JGMActivityPVESetting:Uninit()
    EventManager:UnBindEventMethod(CommonEventDef.EV_GAME_OBJECT_ON_PAWN_DEAD, self, self.OnPawnDead)
    JGMActivityPVESetting.super.Uninit(self)
end

function JGMActivityPVESetting:Parse(tbJsonData)
    JGMActivityPVESetting.super.Parse(self, tbJsonData)
    
    local tbStep
    local tbGameMode = self.tbGameMode
    local tbGameState = tbGameMode.tbGameState

    local nShowResultTime = tbJsonData.ShowResultTime
    if(nShowResultTime ~= nil and nShowResultTime > 0) then
        tbStep = tbGameMode:CreateStep(BattleResultStep, tbGameState.nShowResultStepId)
        tbStep:SetParams(tbGameState.rBattlePlayerResultStep, nShowResultTime, true)
        self.ResultStep = tbStep
    end

    return true
end

function JGMActivityPVESetting:GetQuitDungeonDialogType()
    return DungeonQuitDialogType.ActivityPVE
end

function JGMActivityPVESetting:OnPawnDead(tbDeadActor)
    if tbDeadActor.ObjectType == GameObjectTypeDef.PlayerSelf then 
        EventManager:OnFireEvent(CommonEventDef.EV_BATTLE_REVIVE_INFOANDSHOW, BattleReviveModeTypeDef.Reset, tbDeadActor)
    end

end

return JGMActivityPVESetting
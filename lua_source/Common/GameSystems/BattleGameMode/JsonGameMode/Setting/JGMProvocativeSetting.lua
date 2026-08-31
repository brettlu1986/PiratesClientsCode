local luaclass = require("luaclass")
local JGMCommonSetting = dynamic_require("JGMCommonSetting")
local JGMProvocativeSetting = luaclass("JGMProvocativeSetting", JGMCommonSetting)

local BattleTeamSystem = require("BattleTeamSystem")
local EventManager = require("EventManager")
local CommonEventDef = require("CommonEventDef")
local BattleBlackboard = require("BattleBlackboard")
local BattleOperationDef = dynamic_require("BattleOperationDef")
local BattleOperationHelper = require("BattleOperationHelper")
local GameObjectTypeDef = require("GameObjectTypeDef")
local BattleReviveModeTypeDef = require("BattleReviveModeTypeDef")
local DungeonQuitDialogType = require("DungeonQuitDialogType")
local GlobalVariableSystem = dynamic_require("GlobalVariableSystem")

local REVIVE_UI_TIME = 30

JGMProvocativeSetting.AggressorGroupIndex = nil     -- 挑衅者组id
JGMProvocativeSetting.RecipientStartAction = nil    -- 受挑衅者StartAction 
JGMProvocativeSetting.RecipientLoginAction = nil    -- 受挑衅者LoginAction

function JGMProvocativeSetting:Init(tbGameMode)
    assert(not GlobalVariableSystem:IsClient(), "Enter Dungeon mode error")

    if(not JGMProvocativeSetting.super.Init(self, tbGameMode)) then
        return false
    end
    EventManager:BindEventMethod(CommonEventDef.EV_GAME_OBJECT_ON_PAWN_DEAD, self, self.OnPawnDead)
    EventManager:BindEventMethod(CommonEventDef.EV_BATTLE_REVIVE_SUCCE, self, self.OnBatterReviveSuccess)
    EventManager:BindEventMethod(CommonEventDef.EV_BATTLE_DUNGEON_END, self, self.OnBatterDungeonEnd)

    return true
end

function JGMProvocativeSetting:Uninit()
    JGMProvocativeSetting.super.Uninit(self)
    EventManager:UnBindEventMethod(CommonEventDef.EV_GAME_OBJECT_ON_PAWN_DEAD, self, self.OnPawnDead)
    EventManager:UnBindEventMethod(CommonEventDef.EV_BATTLE_REVIVE_SUCCE, self, self.OnBatterReviveSuccess)
    EventManager:UnBindEventMethod(CommonEventDef.EV_BATTLE_DUNGEON_END, self, self.OnBatterDungeonEnd)
end

function JGMProvocativeSetting:Parse(tbJsonData)
    JGMProvocativeSetting.super.Parse(self, tbJsonData)
    
    local tbRecipientStartData = tbJsonData.RecipientStartAction
    if(tbRecipientStartData) then
        self.RecipientStartAction = BattleOperationHelper:Create(nil, tbRecipientStartData)
    end

    local tbRecipientLoginAction = tbJsonData.RecipientLoginAction
    if(tbRecipientLoginAction) then
        self.RecipientLoginAction = BattleOperationHelper:Create(nil, tbRecipientLoginAction)
    end    

    local tbReviveAction = tbJsonData.ReviveAction
    if(tbReviveAction) then
        self.ReviveAction = BattleOperationHelper:Create(nil, tbReviveAction)
    end    

    return true
end

function JGMProvocativeSetting:OnFindPlayerStart(tbPlayer)
    local nGroupIndex = BattleTeamSystem:FindTeamId(tbPlayer)
    if self.AggressorGroupIndex == nil then 
        self.AggressorGroupIndex = nGroupIndex
    end 

    local StartAction = self.PlayerStartAction
    if self.AggressorGroupIndex ~= nGroupIndex then 
        StartAction = self.RecipientStartAction
    end

    if(StartAction ~= nil) then
        BattleBlackboard:SetTable(BattleOperationDef.CurrentObject, tbPlayer)
        if(false == StartAction:Execute()) then
            error("StartAction execute failed")
        end
        
        local tbTransform = BattleBlackboard:GetTable(BattleOperationDef.CurrentPlayerStart)
        BattleBlackboard:SetTable(BattleOperationDef.CurrentPlayerStart, nil)
        BattleBlackboard:SetTable(BattleOperationDef.CurrentObject, nil)
        if(tbTransform) then
            return tbTransform
        end
    end

    return JGMProvocativeSetting.super.OnFindPlayerStart(self, tbPlayer)
end

function JGMProvocativeSetting:OnPlayerLogin(tbPlayer)
    local nGroupIndex = BattleTeamSystem:FindTeamId(tbPlayer)
    if self.AggressorGroupIndex == nil then 
        self.AggressorGroupIndex = nGroupIndex
    end 

    local LoginAction = self.PlayerLoginAction
    if self.AggressorGroupIndex ~= nGroupIndex then 
        LoginAction = self.RecipientLoginAction
    end
    if( LoginAction ~= nil and self.bStartedStep ) then
        BattleBlackboard:SetTable(BattleOperationDef.CurrentObject, tbPlayer)
        if(false == LoginAction:Execute()) then
            error("LoginAction execute failed")
        end
        BattleBlackboard:SetTable(BattleOperationDef.CurrentObject, nil)
    end

    JGMProvocativeSetting.super.OnPlayerLogin(self, tbPlayer)
end

function JGMProvocativeSetting:OnPawnDead(tbDeadActor)
    if tbDeadActor.ObjectType == GameObjectTypeDef.PlayerSelf then 
        EventManager:OnFireEvent(CommonEventDef.EV_BATTLE_REVIVE_INFOANDSHOW, BattleReviveModeTypeDef.BackCityAndNow, tbDeadActor, REVIVE_UI_TIME)
    end

end

function JGMProvocativeSetting:OnBatterReviveSuccess(tbPlayer)
    if tbPlayer == nil then
        logerror(" BattlePlayerStateComponent is NULL")
        return false
    end

    if( self.ReviveAction ~= nil and self.bStartedStep ) then
        BattleBlackboard:SetTable(BattleOperationDef.CurrentObject, tbPlayer)
        if(false == self.ReviveAction:Execute()) then
            error("ReviveAction execute failed")
        end
        BattleBlackboard:SetTable(BattleOperationDef.CurrentObject, nil)
    end

end

function JGMProvocativeSetting:OnBatterDungeonEnd(nResult)
    self.tbGameMode:OnAllStepFinished()
end

function JGMProvocativeSetting:GetQuitDungeonDialogType()
    return DungeonQuitDialogType.Provocative
end

return JGMProvocativeSetting
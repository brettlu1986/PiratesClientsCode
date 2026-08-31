local luaclass = require("luaclass")
local JGMCommonSetting = dynamic_require("JGMCommonSetting")
local JGMFactionSetting = luaclass("JGMFactionSetting", JGMCommonSetting)

local BattleTeamSystem = require("BattleTeamSystem")
local EventManager = require("EventManager")
local CommonEventDef = require("CommonEventDef")
local BattleBlackboard = require("BattleBlackboard")
local BattleOperationDef = dynamic_require("BattleOperationDef")
local BattleOperationHelper = require("BattleOperationHelper")
local GameObjectTypeDef = require("GameObjectTypeDef")
local BattleReviveModeTypeDef = require("BattleReviveModeTypeDef")
local DungeonQuitDialogType = require("DungeonQuitDialogType")
local BattlePlayerHelper = require("BattlePlayerHelper")
local GlobalVariableSystem = dynamic_require("GlobalVariableSystem")
local CampDef = require("CampDefine")
local FactionDef = require("FactionDef")


JGMFactionSetting.KillMonsterPiont = nil
JGMFactionSetting.KillEnemyPiont = nil
JGMFactionSetting.CreatorGroupIndex = nil        -- 创建者组
JGMFactionSetting.CreatorFaction = nil           -- 创建者阵营

JGMFactionSetting.IntruderStartAction = nil
JGMFactionSetting.IntruderLoginAction = nil
JGMFactionSetting.ReviveAction = nil

local REVIVE_UI_TIME = 30

local FactionToCampType = {}
FactionToCampType[FactionDef.Type.FACTION_NONE] = CampDef.Type.CAMP_NONE
FactionToCampType[FactionDef.Type.FACTION_ENGLAND] = CampDef.Type.CAMP_ENGLAND
FactionToCampType[FactionDef.Type.FACTION_SPAIN] = CampDef.Type.CAMP_SPAIN
FactionToCampType[FactionDef.Type.FACTION_PIRATE] = CampDef.Type.CAMP_PIRATE


function JGMFactionSetting:Init(tbGameMode)
    assert(not GlobalVariableSystem:IsClient(), "Enter Dungeon mode error")

    if(not JGMFactionSetting.super.Init(self, tbGameMode)) then
        return false
    end
    EventManager:BindEventMethod(CommonEventDef.EV_GAME_OBJECT_ON_PAWN_DEAD, self, self.OnPawnDead)
    EventManager:BindEventMethod(CommonEventDef.EV_BATTLE_REVIVE_SUCCE, self, self.OnBatterReviveSuccess)
    EventManager:BindEventMethod(CommonEventDef.EV_BATTLE_DUNGEON_END, self, self.OnBatterDungeonEnd)

    BattleBlackboard:DefineTable(BattleOperationDef.FactionPoint, nil)
    
    return true
end

function JGMFactionSetting:Uninit()
    JGMFactionSetting.super.Uninit(self)
    EventManager:UnBindEventMethod(CommonEventDef.EV_GAME_OBJECT_ON_PAWN_DEAD, self, self.OnPawnDead)
    EventManager:UnBindEventMethod(CommonEventDef.EV_BATTLE_REVIVE_SUCCE, self, self.OnBatterReviveSuccess)
    EventManager:UnBindEventMethod(CommonEventDef.EV_BATTLE_DUNGEON_END, self, self.OnBatterDungeonEnd)
end

function JGMFactionSetting:Parse(tbJsonData)
    JGMFactionSetting.super.Parse(self, tbJsonData)

    local tbIntruderStartData = tbJsonData.IntruderStartAction
    if(tbIntruderStartData) then
        self.IntruderStartAction = BattleOperationHelper:Create(nil, tbIntruderStartData)
    end

    local tbIntruderLoginAction = tbJsonData.IntruderLoginAction
    if(tbIntruderLoginAction) then
        self.IntruderLoginAction = BattleOperationHelper:Create(nil, tbIntruderLoginAction)
    end    

    local tbReviveAction = tbJsonData.ReviveAction
    if(tbReviveAction) then
        self.ReviveAction = BattleOperationHelper:Create(nil, tbReviveAction)
    end    

    self.KillMonsterPiont = tbJsonData.KillMonsterPiont
    self.KillEnemyPiont = tbJsonData.KillEnemyPiont

    return true
end

function JGMFactionSetting:OnFindPlayerStart(tbPlayer)
    -- 第一队为创建者，其他为闯入者
    local nGroupIndex = BattleTeamSystem:FindTeamId(tbPlayer)
    if self.CreatorGroupIndex == nil then 
        self.CreatorGroupIndex = nGroupIndex
        self.CreatorFaction = tbPlayer.tbPrepareInfo.nFaction
    end 

    local StartAction = self.PlayerStartAction
    if self.CreatorGroupIndex ~= nGroupIndex then 
        StartAction = self.IntruderStartAction
    end

    if(StartAction ~= nil) then
        BattleBlackboard:SetTable(BattleOperationDef.CurrentObject, tbPlayer)
        if(false == StartAction:Execute()) then
            error("StartAction execute failed")
        end
        
        local tbPlayerStart = BattleBlackboard:GetTable(BattleOperationDef.CurrentPlayerStart)
        BattleBlackboard:SetTable(BattleOperationDef.CurrentPlayerStart, nil)
        BattleBlackboard:SetTable(BattleOperationDef.CurrentObject, nil)
        if(tbPlayerStart) then
            -- 设置阵营关系
            tbPlayerStart.CampType = FactionToCampType[tbPlayer.tbPrepareInfo.nFaction]
            return tbPlayerStart
        end
    end

    return JGMFactionSetting.super.OnFindPlayerStart(self, tbPlayer)
end

function JGMFactionSetting:OnPlayerLogin(tbPlayer)
    -- 第一队为创建者，其他为闯入者
    local nGroupIndex = BattleTeamSystem:FindTeamId(tbPlayer)
    if self.CreatorGroupIndex == nil then 
        self.CreatorGroupIndex = nGroupIndex
        self.CreatorFaction = tbPlayer.tbPrepareInfo.nFaction
    end 
    
    local LoginAction = self.PlayerLoginAction
    if self.CreatorGroupIndex ~= nGroupIndex then 
        LoginAction = self.IntruderLoginAction
    end
    if( LoginAction ~= nil and self.bStartedStep ) then
        BattleBlackboard:SetTable(BattleOperationDef.CurrentObject, tbPlayer)
        if(false == LoginAction:Execute()) then
            error("LoginAction execute failed")
        end
        BattleBlackboard:SetTable(BattleOperationDef.CurrentObject, nil)
    end
end

function JGMFactionSetting:OnStartStep(tbStep)
    if self.JsonMainStep == tbStep then
        self:FactionDungeonBegin()
    end
    
    JGMFactionSetting.super.OnStartStep(self, tbStep)
end

function JGMFactionSetting:OnPawnDead(tbDeadActor)
    local tbKillerActor = nil--tbDeadActor.BattleStatusComponent:GetLastDamageCauser()
    -- 阵营本击杀获得积分
    local nPoint = 0
    local bIsDead = false
    if tbDeadActor.ObjectType == GameObjectTypeDef.Npc then 
        nPoint = self.KillMonsterPiont   
        local tbFactionPoint = BattleBlackboard:GetTable(BattleOperationDef.FactionPoint)
        if tbFactionPoint and tbFactionPoint[tbDeadActor.szTag] then 
            nPoint = tbFactionPoint[tbDeadActor.szTag]
        end   
    elseif tbDeadActor.ObjectType == GameObjectTypeDef.PlayerSelf then 
        -- 玩家重复被击杀不计分
        bIsDead = BattlePlayerHelper:CheckInDeadList(tbDeadActor.nPlayerId)
        BattlePlayerHelper:AddDeadList(tbDeadActor.nPlayerId)
        nPoint = self.KillEnemyPiont 
        EventManager:OnFireEvent(CommonEventDef.EV_BATTLE_REVIVE_INFOANDSHOW, BattleReviveModeTypeDef.BackCityAndNow, tbDeadActor, REVIVE_UI_TIME)
    end

    local tbTeams = BattleTeamSystem:GetAllTeamInfo()
    -- 不是人击杀的给创建者计分
    local bHadAddFactionPoint = false
    if not bIsDead and tbKillerActor == nil then 
        for _, tbTeam in pairs(tbTeams) do
            for _, tbObject in pairs(tbTeam.tbGameObjects) do
                local nGroupIndex = BattleTeamSystem:FindTeamId(tbObject)
                if nGroupIndex == self.CreatorGroupIndex or self.CreatorFaction == tbObject.tbPrepareInfo.nFaction then 
                    bHadAddFactionPoint = true
                    self:PlayerAddFactionPoint(tbObject,nPoint)
                end
            end
        end
        -- 如果创建者不在副本则 给副本中所有玩家计分
        if not bHadAddFactionPoint then
            for _, tbTeam in pairs(tbTeams) do
                for _, tbObject in pairs(tbTeam.tbGameObjects) do
                    self:PlayerAddFactionPoint(tbObject,nPoint)
                end
            end
        end
    else
        if  not bIsDead and tbKillerActor.ObjectType == GameObjectTypeDef.PlayerSelf then 
            local nKillerFaction = tbKillerActor.tbPrepareInfo.nFaction
            for _, tbTeam in pairs(tbTeams) do
                for _, tbObject in pairs(tbTeam.tbGameObjects) do
                    if tbObject.tbPrepareInfo.nFaction == nKillerFaction then 
                        self:PlayerAddFactionPoint(tbObject,nPoint)
                    end
                end
            end
        end
    end
end

function JGMFactionSetting:OnBatterReviveSuccess(tbPlayer)
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

function JGMFactionSetting:OnBatterDungeonEnd(nResult)
    self.tbGameMode:OnAllStepFinished()
end

function JGMFactionSetting:GetQuitDungeonDialogType()
    return DungeonQuitDialogType.Faction
end

function JGMFactionSetting:FactionDungeonBegin()
end

function JGMFactionSetting:PlayerAddFactionPoint()
end

return JGMFactionSetting
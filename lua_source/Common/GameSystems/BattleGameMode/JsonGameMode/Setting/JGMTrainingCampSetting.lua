local luaclass = require("luaclass")
local JGMCommonSetting = dynamic_require("JGMCommonSetting")
local JGMTrainingCampSetting = luaclass("JGMTrainingCampSetting", JGMCommonSetting)

local BattleDataStatisticsSystem = dynamic_require("BattleDataStatisticsSystem")
local BattleTemplateActorSystem = dynamic_require("BattleTemplateActorSystem")
local BattleGameModeSystem = dynamic_require("BattleGameModeSystem")
local GlobalVariableSystem = dynamic_require("GlobalVariableSystem")
local BattleOperationDef = dynamic_require("BattleOperationDef")
local BattleFFAReLoginHelper = require("BattleFFAReLoginHelper")
local DungeonQuitDialogType = require("DungeonQuitDialogType")
local GameObjectSystem = dynamic_require("GameObjectSystem")
local BattlePrepareSystem = require("BattlePrepareSystem")
local PropNameGameState = require("PropNameGameState")
local GameObjectTypeDef = require("GameObjectTypeDef")
local BattleBlackboard = require("BattleBlackboard")
local AIVariableSystem = require("AIVariableSystem")
local BattleTeamSystem = require("BattleTeamSystem")
local SelfEventHelper = require("SelfEventHelper")
local TemplateTypeDef = require("TemplateTypeDef")
local BotAISystem = dynamic_require("BotAISystem")
local CommonEventDef = require("CommonEventDef")
local SpawnerSystem = require("SpawnerSystem")
local SpawnerDef = require("SpawnerDef")
local Timer = require("Timer")

JGMTrainingCampSetting.EventHelper            = nil
JGMTrainingCampSetting.nTrainTime             = 31*60 -- 训练时间
JGMTrainingCampSetting.tbReleaseTimer         = nil   --副本回收Timer
JGMTrainingCampSetting.tbNotifyReleaseTimer   = nil   --副本回收前一段事件需要通知
JGMTrainingCampSetting.tbQuitDungeonInstanceIds = nil  --主动退出副本的玩家PlayerInstanceIds集合
JGMTrainingCampSetting.bStopAcceptingPlayers  = false -- 是否停止接收玩家加入

local NOTIFY_RELEASE_TIME = 60 --副本回收前1分钟发出通知

local function DefineGameStatePropertiesDefaultValues(self, tbGameState)
    tbGameState.nTrainingCampReleaseTimeStamp:Set(0)
    tbGameState.rTrainingCampPlayerInfos:Set(nil)
end

local function IsRealPlayerExist(self)
    local tbObjects = GameObjectSystem:GetAllByObjectType(GameObjectTypeDef.PlayerSelf)
    for Object, _ in pairs(tbObjects) do
        if not BotAISystem:IsBot(Object) then
            return true
        end
    end

    return false
end

local function UpdateGameStatePlayerInfos(self)
    local tbPlayerInfos = { PlayerInfos = {} }
    local tbObjects = GameObjectSystem:GetAllByObjectType(GameObjectTypeDef.PlayerSelf)
    for tbPlayer, _ in pairs(tbObjects) do
        local nPlayerId    = tbPlayer:GetPlayerId()
        local nInstanceId  = tbPlayer:GetServerInstanceId()
        local tbInfo       = BattlePrepareSystem:GetPlayerPrepareInfo(nPlayerId)

        local tbPlayerInfo = {}
        tbPlayerInfo.nInstanceId = nInstanceId
        tbPlayerInfo.nLevel      = tbInfo.nLevel
        tbPlayerInfo.nAvatarId   = tbInfo.nAvatarId
        tbPlayerInfo.nSeasonRank = tbInfo.nMaxGrade

        table.insert(tbPlayerInfos.PlayerInfos, tbPlayerInfo)
    end

    local rTrainingCampPlayerInfos = self.tbGameMode.tbGameState.rTrainingCampPlayerInfos
    if rTrainingCampPlayerInfos then
        rTrainingCampPlayerInfos:Set(tbPlayerInfos)
    end
end

local function InitTemplateActorRegions(self, tbGameMode)
    -- default region
    GlobalVariableSystem.bEnableTemplateActor = true
    local tbMapSize = tbGameMode.tbJsonTableFile.tbContainer.MapSize[1]
    BattleTemplateActorSystem:InitDefaultRegion(tbMapSize.GamePlayWidth, tbMapSize.GamePlayHeight, 0, 0)

    if(GlobalVariableSystem.bEnableTemplateActor) then
        BattleTemplateActorSystem:SwitchToDefaultRegion(true)
    end
end

local function ClearNotifyReleaseTimer(self)
    if self.tbNotifyReleaseTimer then
        self.tbNotifyReleaseTimer:Clear()
        self.tbNotifyReleaseTimer = nil
    end
end

local function ClearTrainTimer(self)
    if self.tbReleaseTimer then
        self.tbReleaseTimer:Clear()
        self.tbReleaseTimer = nil
    end
end

local function OnNotifyReleaseTimeEnd(self)
    ClearNotifyReleaseTimer(self)

    local tbObjects = GameObjectSystem:GetAllByObjectType(GameObjectTypeDef.PlayerSelf)
    for Object, _ in pairs(tbObjects) do
        local nId = Object:GetServerInstanceId()
        if not BotAISystem:IsBot(Object) and
           not self.tbQuitDungeonInstanceIds[nId] then
            self:OnNotifyPlayerLeaveDungeon(Object)
        end
    end
end

local function ForceReleaseDungeon(self)
    --强制ReleaseDungeon
    self.tbGameMode:OnAllPlayerLogoutWithEvent()
end

local function OnTrainTimeEnd(self)
    ClearTrainTimer(self)
    ForceReleaseDungeon(self)
end

local function OnPlayerQuitDungeon(self, tbPlayer)
    local nInstanceId = tbPlayer:GetServerInstanceId()
    if tbPlayer.ObjectType == GameObjectTypeDef.PlayerSelf then
        if self.tbQuitDungeonInstanceIds[nInstanceId] == nil then
            self.tbQuitDungeonInstanceIds[nInstanceId] = true
        end
    end
end

local function CheckReleaseDungeon(self)
    if self.bStopAcceptingPlayers and not IsRealPlayerExist(self) then
        ForceReleaseDungeon(self)
    end
end

local function ProcessPlayerQuitDungeon(self, tbPlayer, nGroupIndex)
    if tbPlayer and tbPlayer.ObjectType == GameObjectTypeDef.PlayerSelf then
        local nPlayerId   = tbPlayer:GetPlayerId()
        local nInstanceId = tbPlayer:GetServerInstanceId()
        
        BattleTeamSystem:RemoveMember(tbPlayer, nGroupIndex)
        GameObjectSystem:DestroyPlayerSelfInGameMode(nInstanceId)
        BattleGameModeSystem:UninitPlayerState(nPlayerId, tbPlayer)
        UpdateGameStatePlayerInfos(self)

        CheckReleaseDungeon(self)
    end
end

local function SetGameStateReleaseTime(self, nTimeStamp)
    local tbGameMode = self.tbGameMode
    local tbGameState = tbGameMode.tbGameState
    local rSetTime = tbGameState.nTrainingCampReleaseTimeStamp
    if rSetTime then
        rSetTime:Set(nTimeStamp)
    end
end

local function StartReleaseDungeonTimer(self)
    if not self.tbReleaseTimer and not self.tbNotifyReleaseTimer then
        self.tbReleaseTimer = Timer.NewTimerMethod(self, OnTrainTimeEnd, self.nTrainTime, false)
        self.tbNotifyReleaseTimer = Timer.NewTimerMethod(self, OnNotifyReleaseTimeEnd, self.nTrainTime - NOTIFY_RELEASE_TIME, false)
        SetGameStateReleaseTime(self, GlobalVariableSystem:GetLocalTime() + self.nTrainTime - NOTIFY_RELEASE_TIME)
    end
end

local function OnNotifyStopAcceptingPlayers(self)
    self.bStopAcceptingPlayers = true
    CheckReleaseDungeon(self)
end

--重连玩家发送完Item后需要设置当前武器
local function OnBattleItemResetAfterReLogin(self, tbPlayer)
    BattleFFAReLoginHelper:BattleItemResetAfterReLogin(tbPlayer)
end
-- local function end.


function JGMTrainingCampSetting:Init(tbGameMode)
    assert(not GlobalVariableSystem:IsClient(), "Enter Dungeon mode error")

    if(not JGMTrainingCampSetting.super.Init(self, tbGameMode)) then
        return false
    end

    InitTemplateActorRegions(self, tbGameMode)
    self:DefineGameStateByType(PropNameGameState.PropType.TYPE_TRAININGCAMP)
    DefineGameStatePropertiesDefaultValues(self, tbGameMode:GetGameState())

    self.EventHelper = SelfEventHelper()
    self.EventHelper:RegisterEvent(CommonEventDef.EV_BATTLE_PLAYER_POST_LOGOUT,       self, self.OnPlayerPostLogout)
    self.EventHelper:RegisterEvent(CommonEventDef.EV_NOTIFY_STOPACCEPTINGNEWPLAYERS , self, OnNotifyStopAcceptingPlayers)
    self.EventHelper:RegisterEvent(CommonEventDef.EV_BATTLE_ITEM_RESET_AFTER_RELOGIN_SERVER , self, OnBattleItemResetAfterReLogin)

    self.tbQuitDungeonInstanceIds = {}
    return true
end

function JGMTrainingCampSetting:Uninit()
    ClearNotifyReleaseTimer(self)
    ClearTrainTimer(self)

    self.EventHelper:UnregisterAll()
    self.EventHelper = nil
    self.tbQuitDungeonInstanceIds = nil

    JGMTrainingCampSetting.super.Uninit(self)
end

function JGMTrainingCampSetting:GetQuitDungeonDialogType()
    return DungeonQuitDialogType.TrainingCamp
end

function JGMTrainingCampSetting:Parse(tbJsonData)
    if(not JGMTrainingCampSetting.super.Parse(self, tbJsonData)) then
        return false
    end

    self.nTrainTime = tbJsonData.TrainTime
    return true
end

function JGMTrainingCampSetting:OnStartStep(tbStep)
    log("JGMTrainingCampSetting:OnStartStep")
    if self.JsonMainStep == tbStep then
        AIVariableSystem:SetBattleStart(false)
        -- 关闭副本内伤害
        GlobalVariableSystem:SetDungeonDamageEnabled(false)
        --伤害值显示
        GlobalVariableSystem:SetNotifyDamageWhenIgnoreDamage(true)
        --关闭统计系统
        BattleDataStatisticsSystem:Deactivate()
        self.tbGameMode:SetCheckAllPlayerLogoutFunc(function() return false end)

        -- 地图上生成资源
        log("SpawnAllItemDrop")
        local tbTypes = {
            [SpawnerDef.SpawnerType.ITEMDROP] = true,
            [SpawnerDef.SpawnerType.VEHICLE] = true,
            [SpawnerDef.SpawnerType.DESTRUCTIBLEOBJECT] = true,
        }

        SpawnerSystem:AsyncSpawnAllByType(tbTypes)

        if(GlobalVariableSystem.bEnableTemplateActor) then
            BattleTemplateActorSystem:FinishInit()
        end

        StartReleaseDungeonTimer(self)
    end

    JGMTrainingCampSetting.super.OnStartStep(self, tbStep)
end

function JGMTrainingCampSetting:OnFindPlayerStart(tbPlayer)
    if(self.PlayerStartAction ~= nil) then
        BattleBlackboard:SetTable(BattleOperationDef.CurrentObject, tbPlayer)
        if(false == self.PlayerStartAction:Execute()) then
            error("PlayerStartAction execute failed")
        end

        local tbPlayerStart = BattleBlackboard:GetTable(BattleOperationDef.CurrentPoint)
        BattleBlackboard:SetTable(BattleOperationDef.CurrentPoint, nil)
        BattleBlackboard:SetTable(BattleOperationDef.CurrentObject, nil)
        if(tbPlayerStart) then
            return tbPlayerStart
        end
    end

    return nil
end

local function GetBornPos(self, tbGamePlayer)
    return self:OnFindPlayerStart(tbGamePlayer)
end

function JGMTrainingCampSetting:OnSpawnPlayerPawn(tbGamePlayer, bPossess)
    local tbStartJsonData = GetBornPos(self, tbGamePlayer)
    if(tbStartJsonData == nil) then
        logerror("JGMTrainingCampSetting:OnPlayerSpawnPawn failed, OnFindPlayerStart is invalid", tbGamePlayer.nPlayerId)
        return false
    end

    local tbPlayerStart = { }
    tbPlayerStart.Transform = tbStartJsonData
    tbPlayerStart.CampType = 1

    local tbPrepareInfo = tbGamePlayer.tbPrepareInfo
    local tbSpawnInfo = {}
    tbSpawnInfo.tbStartJsonData = tbPlayerStart
    tbSpawnInfo.nTemplateType = TemplateTypeDef.HUMAN
    tbSpawnInfo.nTemplateId = tbPrepareInfo.nHumanId
    local bRet = GameObjectSystem:SpawnPlayerSelfUEActorInGameMode(tbGamePlayer, tbPrepareInfo, tbSpawnInfo, bPossess)
    if(not bRet) then
        logerror("JGMTrainingCampSetting:OnPlayerSpawnPawn failed, the returned gameobject is nil", tbGamePlayer.nPlayerId)
        return false
    end

    return true
end

function JGMTrainingCampSetting:OnPlayerLogin(tbPlayer)
    if( self.PlayerLoginAction ~= nil and  self.bStartedStep ) then
        BattleBlackboard:SetTable(BattleOperationDef.CurrentObject, tbPlayer)
         if(false == self.PlayerLoginAction:Execute()) then
            error("PlayerLoginAction execute failed")
        end
        BattleBlackboard:SetTable(BattleOperationDef.CurrentObject, nil)
    end

    UpdateGameStatePlayerInfos(self)
    
    JGMTrainingCampSetting.super.OnPlayerLogin(self, tbPlayer)
end

function JGMTrainingCampSetting:OnPlayerPostLogout(nPlayerId, nGroupIndex)
    local tbPlayer = GameObjectSystem:FindPlayerByPlayerId(nPlayerId)
    local nInstanceId = tbPlayer:GetServerInstanceId()

    if self.tbQuitDungeonInstanceIds[nInstanceId] then
        ProcessPlayerQuitDungeon(self, tbPlayer, nGroupIndex)
    end
end


function JGMTrainingCampSetting:NotifyPlayerLeave(tbPlayer)
    log("JGMTrainingCampSetting:NotifyPlayerLeave")

    OnPlayerQuitDungeon(self, tbPlayer)

    --如果此玩家已经Logout，则调用ProcessPlayerQuitDungeon
    local nInstanceId = tbPlayer:GetServerInstanceId()
    local bFind = false
    local tbOnlinePlayers = self.tbGameMode.tbPlayers
    for nIndex, tbCurPlayer in ipairs(tbOnlinePlayers) do
        local nCurInstanceId = tbCurPlayer:GetServerInstanceId()
        if nInstanceId == nCurInstanceId then
            bFind = true
            break
        end
    end

    if not bFind then
        local nTeamId = -1
        if tbPlayer and tbPlayer.BattleTeamComponent then
            nTeamId = tbPlayer.BattleTeamComponent.nTeamId
        end

        if nTeamId ~= -1 then
            ProcessPlayerQuitDungeon(self, tbPlayer, nTeamId)
        else
            logerror("JGMTrainingCampSetting:NotifyPlayerLeave nTeamId == -1 PlayerName:", tbPlayer.szName)
        end
    end
end

--踢人逻辑
function JGMTrainingCampSetting:OnKickPlayer(tbPlayer)
    log("JGMTrainingCampSetting:OnKickPlayer", tbPlayer.szName)
    OnPlayerQuitDungeon(self, tbPlayer)
end

function JGMTrainingCampSetting:OnNotifyPlayerLeaveDungeon(tbPlayer)
end

function JGMTrainingCampSetting:OnForceReleaseDungeon()
    ForceReleaseDungeon(self)
end

function JGMTrainingCampSetting:ResetReleaseTime(nTime)
    ClearNotifyReleaseTimer(self)
    ClearTrainTimer(self)
    self.nTrainTime = nTime
    StartReleaseDungeonTimer(self)
end

return JGMTrainingCampSetting
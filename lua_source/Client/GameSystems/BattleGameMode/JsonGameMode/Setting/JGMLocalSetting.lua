local luaclass = require("luaclass")
local JGMCommonSetting = dynamic_require("JGMCommonSetting")
local JGMLocalSetting = luaclass("JGMLocalSetting", JGMCommonSetting)

local GamePlayerSelfHelper = require("GamePlayerSelfHelper")
local EventManager = require("EventManager")
local ClientEventDef = require("ClientEventDef")
local NetworkManager = dynamic_require("NetworkManager")
local Proto = require("ClientProtoNames")
local CommonEventDef = require("CommonEventDef")
local BattleResultStep = dynamic_require("BattlePVEResultStep")
local GlobalVariableSystem = dynamic_require("GlobalVariableSystem")
local TemplateTypeDef = require("TemplateTypeDef")
local GameObjectSystem = require("GameObjectSystem_C")
local BattleBlackboard = require("BattleBlackboard")
local AIVariableSystem = require("AIVariableSystem")

JGMLocalSetting.nChangeShipId = nil
JGMLocalSetting.bCanResetGame = false
JGMLocalSetting.szPlayerFollowNpcTag = nil
JGMLocalSetting.szLocalPlayerKey = nil
JGMLocalSetting.ResultStep = nil
JGMLocalSetting.bBornInShip = false

local function SendPacket(szProto, tbPacket)
    local Socket = NetworkManager:GetHubServerProxy()
    return Socket:SendPacket(szProto, tbPacket)
end

function JGMLocalSetting:Init(tbGameMode)
    assert(GlobalVariableSystem:IsClient(), "Enter Dungeon mode error")

    if(not JGMLocalSetting.super.Init(self, tbGameMode)) then
        return false
    end
    EventManager:BindEventMethod(CommonEventDef.EV_RECEIVE_BATTLE_RETRY_GAME_FROM_HUB, self, self.OnRetryLocalGame)

    return true
end

function JGMLocalSetting:Uninit()
    JGMLocalSetting.super.Uninit(self)
    EventManager:UnBindEventMethod(CommonEventDef.EV_RECEIVE_BATTLE_RETRY_GAME_FROM_HUB, self, self.OnRetryLocalGame)
end


function JGMLocalSetting:Parse(tbJsonData)
    local bRet = JGMLocalSetting.super.Parse(self, tbJsonData)
    self.nChangeShipId = tbJsonData.ChangeShipId
    -- self.nChangeShipId = 1031
    self.szPlayerFollowNpcTag = tbJsonData.PlayerFollowNpcTag
    self.szLocalPlayerKey = tbJsonData.LocalPlayerKey
    self.bBornInShip = tbJsonData.BornInShip

    -- 单击副本加结算step
    local tbStep
    local tbGameMode = self.tbGameMode
    local tbGameState = tbGameMode.tbGameState
    local nShowResultTime = tbJsonData.ShowResultTime
    if(nShowResultTime ~= nil and nShowResultTime > 0) then
        tbStep = tbGameMode:CreateStep(BattleResultStep, tbGameState.nShowResultStepId)
        tbStep:SetParams(tbGameState.rBattlePlayerResultStep, nShowResultTime, false)
        self.ResultStep = tbStep
    end

    return bRet
end

function JGMLocalSetting:SetPlayerSelfInfo(tbPrepareInfo)
    JGMLocalSetting.super.SetPlayerSelfInfo(self, tbPrepareInfo)
    if self.nChangeShipId ~= nil and self.nChangeShipId > 0 then
        tbPrepareInfo.tbShipInfo.nTypeId = self.nChangeShipId
    end
end

function JGMLocalSetting:OnStartStep(Step)
    local tbPlayer = GamePlayerSelfHelper:Get()
    if(tbPlayer
        and tbPlayer.BattleAIComponent
        and self.szPlayerFollowNpcTag ~= nil
        and string.len(self.szPlayerFollowNpcTag) > 0) then
        tbPlayer.BattleAIComponent:SetFollowNpcTag(self.szPlayerFollowNpcTag)
    end

    JGMLocalSetting.super.OnStartStep(self, Step)

    self.bCanResetGame = Step == self.ResultStep

    -- 临时解决造三级船崩溃的问题
    KismetSystemLibrary.ExecuteConsoleCommand(GWorld, "s.EnableAsyncLoadingReturnImmediately 0", nil)
    AIVariableSystem:SetBattleStart(true)
end

function JGMLocalSetting:OnAllStepFinished()
    -- 临时解决造三级船崩溃的问题
    KismetSystemLibrary.ExecuteConsoleCommand(GWorld, "s.EnableAsyncLoadingReturnImmediately 1", nil)

    JGMLocalSetting.super.OnAllStepFinished(self)
end

function JGMLocalSetting:OnPostResetAllSteps()
    -- local CameraControlManager = GameplayStatics.GetPlayerCameraManager(GWorld, 0)
    -- CameraControlManager.CurrentActiveModeComponent:ResetToDefaultParam()
    EventManager:OnFireEvent(ClientEventDef.EV_BATTLE_RESTART_GAME)
end

function JGMLocalSetting:CanResetAllSteps()
    return self.bCanResetGame
end

-- 发消息给hub
function JGMLocalSetting:TryResetAllSteps(nSenderUniqueId)
    -- 编辑器直接复活 方便测试
    if GWithEditor then
       self:OnRetryLocalGame()
       return
    end

    self:SendRetryLocalGame()
end

function JGMLocalSetting:OnRetryLocalGame()
    self.tbGameMode:ResetAllSteps(self.bCanResetGame)
    self:OnPostResetAllSteps()
    EventManager:OnFireEvent(CommonEventDef.EV_BATTLE_RETRY_GAME)
end

function JGMLocalSetting:SendRetryLocalGame()
    local c2s_RetryLocalGame = {}
    SendPacket(Proto.c2s_RetryLocalGame, c2s_RetryLocalGame)
end

function JGMLocalSetting:OnSpawnPlayerPawn(tbGamePlayer, bPossess)
    local tbStartJsonData = self:OnFindPlayerStart(tbGamePlayer)
    if(tbStartJsonData == nil) then
        logerror("JGMLocalSetting:OnPlayerSpawnPawn failed, OnFindPlayerStart is invalid", tbGamePlayer.nPlayerId)
        return false
    end

    local tbSpawnInfo = {}
    tbSpawnInfo.tbStartJsonData = tbStartJsonData
    tbSpawnInfo.nTemplateType = self.bBornInShip and TemplateTypeDef.SHIP or TemplateTypeDef.HUMAN
    local tbPrepareInfo = tbGamePlayer.tbPrepareInfo
    local bRet = GameObjectSystem:SpawnPlayerSelfUEActorInGameMode(tbGamePlayer, tbPrepareInfo, tbSpawnInfo, bPossess)
    if(not bRet) then
        logerror("JGMLocalSetting:OnPlayerSpawnPawn failed, the returned gameobject is nil", tbGamePlayer.nPlayerId)
        return false
    end

    if tbGamePlayer and self.szLocalPlayerKey and string.len(self.szLocalPlayerKey) > 0 then
        BattleBlackboard:DefineTable(self.szLocalPlayerKey, tbGamePlayer)
    end

    return true
end

return JGMLocalSetting

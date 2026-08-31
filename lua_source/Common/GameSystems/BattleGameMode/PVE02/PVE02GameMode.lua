local luaclass = require("luaclass")
local BattleGameModeBaseClass = dynamic_require("BattleCommonGameMode")
local PVE02GameMode = luaclass("PVELevel30GameMode", BattleGameModeBaseClass)

local CampDef = require("CampDefine")

local BattleMatineeStepClass = require("BattleMatineeStep")
local CommonEventDef = require("CommonEventDef")
local EventManager = require("EventManager")
local BattleReviveModeTypeDef = require("BattleReviveModeTypeDef")
local BattleTeamSystem = require("BattleTeamSystem")
local NetworkManager = dynamic_require("NetworkManager")
local ProtoDC = require("DungeonCommonProtoNames")
local DelayTimer = require("DelayTimer")

local Battle1StepClass = require("PVE02Battle1GameStep")
local Battle2StepClass = require("PVE02Battle2GameStep")
local Battle3StepClass = require("PVE02Battle3GameStep")
local BattlePlayerResultStepClass = dynamic_require("BattlePVEResultStep")

local PVE02DataTable = require("PVE02DataTable")
local DungeonQuitDialogType = require("DungeonQuitDialogType")
local D2CHelper = require("D2CHelper")
local BattleTargetTrackHelper = require("BattleTargetTrackHelper")

local nMaxPlayerCount = 4
local nMaxBattleCount = 3

PVE02GameMode.tbStartPoints = nil  -- 玩家出生点 tbStartPoints[1]第一场战斗出生点 tbStartPoints[2]第二场战斗出生点 ...

PVE02GameMode.nCurrentBattleIndex = nil -- 当前处于第几场战斗

PVE02GameMode.tbPlayerIndex = nil -- <nInstanceId, nIndex> map
PVE02GameMode.nPlayerCount = nil

PVE02GameMode.nPlayerTeamId = nil

PVE02GameMode.tbBattle1GameStep = nil
PVE02GameMode.tbBattle2GameStep = nil
PVE02GameMode.tbBattle3GameStep = nil

PVE02GameMode.tbRestartTimer = nil

PVE02GameMode.nDelayRestartTime = nil

function PVE02GameMode:InitStartPositions(tbJsonTableFile)
    self.tbStartPoints = {}
    for i=1, nMaxBattleCount do
        self.tbStartPoints[i] = {}
    end

    for i,v in ipairs(tbJsonTableFile.tbContainer.DungeonPlayerStarts) do
        local nGroupIndex = v.GroupIndex
        assert(v.CampType == CampDef.Type.CAMP_2, "PlayerStart camp not CAMP_2")
        if nGroupIndex < 1 or nGroupIndex > nMaxBattleCount then
            logwarning("PVE02GameMode init start position step error. Step: ", nGroupIndex)
        else
            table.insert(self.tbStartPoints[nGroupIndex], v)
        end
    end

    for i=1, nMaxBattleCount do
        if #self.tbStartPoints[i] < nMaxPlayerCount then
            logerror("PVE02GameMode StartPoints[", i,"] count less than ", nMaxPlayerCount, ". Error.")
            return false
        end
    end

    self.tbPlayerIndex = {}
    self.nPlayerCount = 0
    return true
end

-- 进入第nIndex场战斗
function PVE02GameMode:OnEnterBattle(nIndex)
    if nIndex >= 1 or nIndex <= nMaxBattleCount then
        log("PVE02GameMode OnEnterBattle", nIndex)
        self.nCurrentBattleIndex = nIndex
    else
        logerror("PVE02GameMode OnEnterBattle exceed max battle index. Index: ", nIndex, ". Max index: ", nMaxBattleCount)
    end
end

function PVE02GameMode:OnBattleStepComplete(tbGameStep)
    if tbGameStep == self.tbBattle1GameStep then
        self:OnEnterBattle(2)
        self:RebornAllPlayers()
    elseif tbGameStep == self.tbBattle2GameStep then
        self:OnEnterBattle(3)
        self:RebornAllPlayers()
    end
end

function PVE02GameMode:OnStepComplete(Step)
    self:OnBattleStepComplete(Step)
    PVE02GameMode.super.OnStepComplete(self, Step)
end

function PVE02GameMode:Init(nSubDungonId, pGameMode, tbGameState, tbJsonTableFile)
    if not PVE02GameMode.super.Init(self, nSubDungonId, pGameMode, tbGameState, tbJsonTableFile) then
        return false
    end

    self:OnEnterBattle(1)
    if not self:InitStartPositions(tbJsonTableFile) then
        return false
    end

    local tbTemplateData = PVE02DataTable:GetTemplate(nSubDungonId)
    if(tbTemplateData == nil) then
        logerror("PVE02GameMode init failed, can not find id", nSubDungonId)
        return false
    end

    self:AddSteps(tbTemplateData, tbGameState)

    self:InitTargetTrack(tbJsonTableFile, tbTemplateData.nTargetTrackId)

    self.nDelayRestartTime = tbTemplateData.nRebornCountdown

    return true
end

function PVE02GameMode:InitTargetTrack(tbJsonTableFile, nTargetTrackId)
    for _, tbTransform in ipairs(tbJsonTableFile.tbContainer.Transforms) do
        if tbTransform.TransformId == nTargetTrackId then
            BattleTargetTrackHelper:ShowTargetTrackPos(nil, tbTransform.Transform.X, tbTransform.Transform.Y, tbTransform.Transform.Z)
            BattleTargetTrackHelper:SetTargetTrackVisible(nil, false) -- Init but not display.
            return
        end 
    end
    logerror("PVE02GameMode:InitTargetTrack no target track found which id =", nTargetTrackId)
end

function PVE02GameMode:Uninit()
    log("PVE02GameMode:Uninit()")
    if self.tbRestartTimer ~= nil then
        DelayTimer:ClearTimer(self.tbRestartTimer)
        self.tbRestartTimer = nil
    end

    PVE02GameMode.super.Uninit(self)
end

function PVE02GameMode:AddSteps(tbTemplateData, tbGameState)    
    local tbStep

    -- 过场动画1
    local nMatinee1 = tbTemplateData.nMatinee1
    if nMatinee1 ~= -1 then
        tbStep = self:CreateStep(BattleMatineeStepClass, tbGameState.nMatinee1StepId)
        tbStep:SetParams(nMatinee1, true)
    end

    -- 战斗1
    self.tbBattle1GameStep = self:CreateStep(Battle1StepClass, tbGameState.nBattle1StepId)
    self.tbBattle1GameStep:SetParams(tbGameState, tbTemplateData, self.tbJsonTableFile)

    -- 过场动画2
    local nMatinee2 = tbTemplateData.nMatinee2
    if nMatinee2 ~= -1 then
        tbStep = self:CreateStep(BattleMatineeStepClass, tbGameState.nMatinee2StepId)
        tbStep:SetParams(nMatinee2, true)
    end

    -- 战斗2
    self.tbBattle2GameStep = self:CreateStep(Battle2StepClass, tbGameState.nBattle2StepId)
    self.tbBattle2GameStep:SetParams(tbGameState, tbTemplateData, self.tbJsonTableFile)

    -- 过场动画3
    local nMatinee3 = tbTemplateData.nMatinee3
    if nMatinee3 ~= -1 then
        tbStep = self:CreateStep(BattleMatineeStepClass, tbGameState.nMatinee3StepId)
        tbStep:SetParams(nMatinee3, true)
    end

    -- 战斗3
    self.tbBattle3GameStep = self:CreateStep(Battle3StepClass, tbGameState.nBattle3StepId)
    self.tbBattle3GameStep:SetParams(tbGameState, tbTemplateData, self.tbJsonTableFile)

    -- 过场动画4
    local nMatinee4 = tbTemplateData.nMatinee4
    if nMatinee4 ~= -1 then
        tbStep = self:CreateStep(BattleMatineeStepClass, tbGameState.nMatinee4StepId)
        tbStep:SetParams(nMatinee4, true)
    end

    -- 战斗结算阶段
    tbStep = self:CreateStep(BattlePlayerResultStepClass, tbGameState.nShowResultStepId)
    tbStep:SetParams(tbGameState.rBattlePlayerResultStep, tbTemplateData.nShowResultTime, true)

end

function PVE02GameMode:FindPlayerStartJsonData(tbGamePlayer)
    local nInstanceId = tbGamePlayer.nServerInstanceId

    if self.tbPlayerIndex[nInstanceId] == nil then
        if self.nPlayerCount >= nMaxPlayerCount then
            logerror("PVE02GameMode:FindPlayerStartJsonData exceed max player count.")
        end
        self.tbPlayerIndex[nInstanceId] = self.nPlayerCount + 1
        self.nPlayerCount = self.nPlayerCount + 1
    end

    local nIndex = self.tbPlayerIndex[nInstanceId]

    local tbJsonStart = self.tbStartPoints[self.nCurrentBattleIndex][nIndex]

    local tbTans = tbJsonStart.Transform
    log("PVE02GameMode:FindPlayerStartJsonData", nInstanceId, tbGamePlayer.nPlayerId, nIndex, 
        tbTans.X, tbTans.Y, tbTans.Z, tbTans.Yaw)
    return tbJsonStart
end

function PVE02GameMode:OnPostDestroyPlayerPawn(GamePlayerSelf)
    PVE02GameMode.super.OnPostDestroyPlayerPawn(self, GamePlayerSelf)
    EventManager:OnFireEvent(CommonEventDef.EV_BATTLE_REVIVE_INFOANDSHOW, BattleReviveModeTypeDef.Reset, GamePlayerSelf)
    self:CheckRestart()
end

function PVE02GameMode:OnPlayerLogin(tbGamePlayer)
    PVE02GameMode.super.OnPlayerLogin(self, tbGamePlayer)
    if self.nPlayerTeamId == nil then
        self.nPlayerTeamId = BattleTeamSystem:FindTeamId(tbGamePlayer)
    else
        assert(self.nPlayerTeamId == BattleTeamSystem:FindTeamId(tbGamePlayer))
    end
end

function PVE02GameMode:OnPlayerLogout(tbGamePlayer)
    PVE02GameMode.super.OnPlayerLogout(self, tbGamePlayer)
    if self.tbPlayers ~= nil and #self.tbPlayers ~= 0 then
        self:CheckRestart()
    end
end

function PVE02GameMode:CheckRestart()
    if self.tbRestartTimer ~= nil then
        log("PVE02GameMode:CheckRestart ignore. Restarting in progress...")
        return
    end

    local tbCurrentStep = self:GetCurrentStep()
    if tbCurrentStep ~= self.tbBattle1GameStep
            and tbCurrentStep ~= self.tbBattle2GameStep
            and tbCurrentStep ~= self.tbBattle3GameStep then
        return
    end

    local tbGameObjects = BattleTeamSystem:GetTeamMembers(self.nPlayerTeamId)
    if tbGameObjects == nil then
        logerror("PVE02GameMode:CheckRestart TeamId", self.nPlayerTeamId, " has no players.")
        return
    end

    for _, tbGameObject in pairs(tbGameObjects) do
        if not tbGameObject:IsDead() then
            -- there is player alive. do not reborn.
            log("There is player alive. Do not reborn.")
            return
        end
    end

    -- Delay restart all players and restart current step.
    local fnRestart = function()
        self.tbRestartTimer = nil
        self:RebornAllPlayers()
        tbCurrentStep:Restart()
    end
    NetworkManager:GetRPCNetworkProxy():Multicast(ProtoDC.d2c_ReviveCountdown, { countdown = self.nDelayRestartTime })
    self.tbRestartTimer = DelayTimer:DelayRun(fnRestart, self.nDelayRestartTime)
end

function PVE02GameMode:RebornAllPlayers()
    log("PVE02GameMode:RebornAllPlayers")
    local tbGameObjects = BattleTeamSystem:GetTeamMembers(self.nPlayerTeamId)
    for _, tbGameObject in pairs(tbGameObjects) do
        if tbGameObject:IsDead() then
            local tbTransform = self:FindPlayerStartJsonData(tbGameObject).Transform
            tbGameObject:Reborn(tbTransform.X, tbTransform.Y, tbTransform.Z, tbTransform.Yaw)
            D2CHelper:PlayerSetCameraYaw(tbGameObject, tbTransform.Yaw)
        end
    end
end

function PVE02GameMode:GetQuitDungeonDialogType()
    log("PVE02GameMode:GetQuitDungeonDialogType")
    return DungeonQuitDialogType.PVE02
end

return PVE02GameMode

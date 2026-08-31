-- ffa机器人生成阶段step

local luaclass = require("luaclass")
local BattleTargetActionStep = require("BattleTargetActionStep")
local FFABotSpawnStep = luaclass("FFABotSpawnStep", BattleTargetActionStep)
local BotSpawner = require("BotSpawner")
local BotAISystem = dynamic_require("BotAISystem")
local BattleGameModeSystem = dynamic_require("BattleGameModeSystem")
local BattleBlackboard = require("BattleBlackboard")
--local EventManager = require("EventManager")
local CommonEventDef = require("CommonEventDef")
local ProtoDR = require("DungeonRepProtoNames")
local BattlePrepareSystem = require("BattlePrepareSystem")
local GlobalVariableSystem = dynamic_require("GlobalVariableSystem")

FFABotSpawnStep.bCanRealPlayerEnter = true     --真实玩家是否能够加入副本
FFABotSpawnStep.nStopAcceptingPlayerTime = 50
FFABotSpawnStep.nWaitTimeRandomOfBotSpawn = 0
FFABotSpawnStep.nCountDownTimeRandomOfBotSpawn = 0
FFABotSpawnStep.nBotId = 1
FFABotSpawnStep.nBotCount = -1
FFABotSpawnStep.nMaxCDWaitTime = 0
FFABotSpawnStep.nState = -1
FFABotSpawnStep.nTeamModeId = 1
FFABotSpawnStep.tbAutoBotTeams = 1 -- 添加ai的队伍
FFABotSpawnStep.bHasAddBotTeammate = false -- 是否已经添加过机器人队友

local nMaxPlayerCount = 100

local function LOG(...)
    log("CJ->FFABotSpawnStep:", ...)
end


local function InitData(self)
    self.bCanRealPlayerEnter = true
    self.nState = -1
    self.nBotCount = BattleGameModeSystem:GetGameInitData().nBotCount or -1
    self.nBotId = BattleGameModeSystem:GetGameInitData().nBotId
    self.nCountDownTimeRandomOfBotSpawn = BattleGameModeSystem:GetGameInitData().nCountDownTimeRandom
    self.nWaitTimeRandomOfBotSpawn = BattleGameModeSystem:GetGameInitData().nWaitTimeRandom
    self.nMaxCDWaitTime  = BattleGameModeSystem:GetGameInitData().nCountDownMaxWaitTime
    self.nStopAcceptingPlayerTime = BattleGameModeSystem:GetGameInitData().nStopAcceptingPlayerTime
    self.nTeamModeId = BattleGameModeSystem:GetGameInitData().nTeamModeId or 1
    self.tbAutoBotTeams = {}
    self.bHasAddBotTeammate = false
end

local function GetSelectionPointPopTime()
    return BattleBlackboard:GetNumber("SelectionPointPopTime")
end

local function GetRealPlayerCount()
    local nRealPlayerCount = 0
    for k,v in pairs(BattlePrepareSystem.tbPlayerPrepareInfoMap) do
        if k and k > 0 then
            nRealPlayerCount = nRealPlayerCount + 1
        end
    end
    return nRealPlayerCount
end

local function AddBotTeammate(self)
    if GlobalVariableSystem.bEnableTeamWithBot and not self.bHasAddBotTeammate then
        local nTeamSize = self.nTeamModeId
        for nTeamId, nCurrentNumberCount in pairs(self.tbAutoBotTeams) do
            local nRequiredCount = nTeamSize - nCurrentNumberCount
            if nRequiredCount > 0 then
                BotSpawner.SpawnTeammate(nRequiredCount, nTeamId, self.nBotId)
                log("BotSpawner.SpawnTeammate", nTeamId, nRequiredCount, self.nBotId)
            end
        end
        self.bHasAddBotTeammate = true
    end
end

local function OnFFAProcessStateChanged(self, nState)
    self.nState = nState
    if nState == ProtoDR.rFFAProcessState_EState.COUNTDOWN then
        local nTime = GetSelectionPointPopTime()
        -- spawn bot step two
        if self.nBotCount > 0 then
            BotSpawner.Spawn(self.nBotCount, self.nBotId, nTime +
            self.nCountDownTimeRandomOfBotSpawn)
            LOG("spawn bot step two :", self.nBotCount, self.nBotId, nTime ,
            self.nCountDownTimeRandomOfBotSpawn)
        end
    elseif nState == ProtoDR.rFFAProcessState_EState.SELECTION then
        -- final check step four
        AddBotTeammate(self)

        if self.nBotCount >= 0 then
            local nRealPlayerCount = GetRealPlayerCount()
            BotSpawner.SpawnImmediately(nMaxPlayerCount - nRealPlayerCount, self.nBotId)
            LOG("spawn bot step final :", nMaxPlayerCount, nRealPlayerCount, self.nBotId)
        end
    end
end

local function OnNotifyStopAcceptingPlayers(self)
    -- spawn bot step three
    self.bCanRealPlayerEnter = false

    if self.nState == ProtoDR.rFFAProcessState_EState.COUNTDOWN and self.nBotCount >= 0 then
        AddBotTeammate(self)

        local nTime = GetSelectionPointPopTime()
        local nFinalTime =  nTime - self.nStopAcceptingPlayerTime
        if nFinalTime > 0 then
            local nRealPlayerCount = GetRealPlayerCount()
            BotSpawner.Spawn(nMaxPlayerCount - nRealPlayerCount, self.nBotId, nFinalTime)
            LOG("spawn bot step three :", nMaxPlayerCount, nRealPlayerCount, self.nBotId, nFinalTime)
        else
            logerror("ffa setting nCountDownTime id less than nStopAcceptingPlayerTime")
        end
    end
end

local function GetTeamId(tbPlayers)
    local tbFirstPlayer = tbPlayers[1]
    if tbFirstPlayer then
        return tbFirstPlayer.group_id
    end
    return nil
end

local function OnPlayerPrepare(self, tbPacket, tbPlayerIds)
    local nTeamId = GetTeamId(tbPacket.players)
    local nCurrentNumberCount = self.tbAutoBotTeams[nTeamId]
    if not nCurrentNumberCount then
        nCurrentNumberCount = 0
    end
    nCurrentNumberCount = nCurrentNumberCount + 1
    self.tbAutoBotTeams[nTeamId] = nCurrentNumberCount
end

function FFABotSpawnStep:Init()
    FFABotSpawnStep.super.Init(self)

    self.szName = "FFABotSpawnStep"
    InitData(self)


end

function FFABotSpawnStep:Parse(tbJsonData)
    if(not FFABotSpawnStep.super.Parse(self, tbJsonData)) then
        return false
    end

    return true
end

function FFABotSpawnStep:RegisterEvent()
    FFABotSpawnStep.super.RegisterEvent(self)

    self.SelfEventHelper:RegisterEvent(CommonEventDef.EV_FFA_PROCESS_STATE_CHANGED, self, OnFFAProcessStateChanged)
    self.SelfEventHelper:RegisterEvent(CommonEventDef.EV_NOTIFY_STOPACCEPTINGNEWPLAYERS , self, OnNotifyStopAcceptingPlayers)
    self.SelfEventHelper:RegisterEvent(CommonEventDef.EV_ON_PLAYER_PREPARE , self, OnPlayerPrepare)
end

function FFABotSpawnStep:UnregisterEvent()
    FFABotSpawnStep.super.UnregisterEvent(self)
end

function FFABotSpawnStep:Start()
    FFABotSpawnStep.super.Start(self)
     -- spawn bot step one

    BotAISystem:SetBotTeamSize(self.nTeamModeId)
    if self.nBotCount > 0 then
        BotAISystem:ConfigReplicatesInfo(self.nBotCount)
        local nTime = GetSelectionPointPopTime()
        BotSpawner.Spawn(self.nBotCount, self.nBotId, self.nMaxCDWaitTime + nTime +
        self.nWaitTimeRandomOfBotSpawn)
        LOG("spawn bot step one :", self.nBotCount, self.nBotId, self.nMaxCDWaitTime , nTime,
        self.nWaitTimeRandomOfBotSpawn)
    end
end

function FFABotSpawnStep:Uninit()
    FFABotSpawnStep.super.Uninit(self)
end

function FFABotSpawnStep:ForceStop()
    FFABotSpawnStep.super.ForceStop(self)
end

function FFABotSpawnStep:OnCompleted()
    FFABotSpawnStep.super.OnCompleted(self)
end

-- 子类必须重载，将当前状态的快照写入replicate属性中，这里可根据情况调用rep，这函数会在新玩家登入时调用
function FFABotSpawnStep:SnapshotToReplicatedProperty()
    return true
end

return FFABotSpawnStep
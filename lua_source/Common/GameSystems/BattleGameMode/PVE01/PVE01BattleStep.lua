-- PVE 20级副本玩法

local luaclass = require("luaclass")
local BattleStepBaseClass = require("BattleStepBase")
local PVE01BattleStep = luaclass("PVE01BattleStep", BattleStepBaseClass)

local BattleRuntimePawnDeadTargetClass = require("BattleRuntimePawnDeadTarget")

local PVE01BattleTargetClass = require("PVE01BattleTarget")

local GameObjectSystem = dynamic_require("GameObjectSystem")
local BattleTeamSystem = require("BattleTeamSystem")
local CommonEventDef = require("CommonEventDef")
local EventManager = require("EventManager")
local BattleReviveModeTypeDef = require("BattleReviveModeTypeDef")
local GameObjectTypeDef = require("GameObjectTypeDef")
local SpawnerSystem = require("SpawnerSystem")
local BaseUtil  = require("BaseUtil")
local UEActorHelper = require("UEActorHelper")
local BattleResultDef = require("BattleResultDef")
local BattleInteractionHelper = require("BattleInteractionHelper")
local D2CHelper = require("D2CHelper")
local BattleObjectiveHelper = require("BattleObjectiveHelper")
local NetworkManager = dynamic_require("NetworkManager")
local ProtoDC = require("DungeonCommonProtoNames")
local DelayTimer = require("DelayTimer")

local PLAYER_WIN = BattleResultDef.WIN

PVE01BattleStep.tbJsonData       = nil
PVE01BattleStep.tbTemplateData   = nil
PVE01BattleStep.PVE01GameState   = nil
PVE01BattleStep.rBattlePlayerResultStep = nil

-- key : GroupIndex
-- value : [npcjsondata list]
--[[ 
    tbNpcJsonDataList = 
    [{
        "Transform":
        {
            "X": 5920,
            "Y": 79300,
            "Z": 530,
            "Yaw": 0
        },
        "TemplateId": 7,
        "GroupIndex": 0
    }],
    tbDummyJsonDataList = 
    [{
        "Transform":
        {
            "X": -172740,
            "Y": 200360,
            "Z": 5520,
            "Yaw": 90
        },
        "SpawnerId": 6,
        "Rotation":
        {
            "Roll": 147,
            "Pitch": 90,
            "Yaw": 90
        },
        "Scale":
        {
            "X": 100,
            "Y": 300,
            "Z": 1
        },
        "ResId": 1,
        "GroupIndex": 1,
        "SubGroupIndex": 1
    }],
    tbPlayerStartsJsonDataList = 
    [{
        
    }],
]]
PVE01BattleStep.tbGroupJsonDataMap  = nil

-- key : [] stage number
-- value : stage info 
-- {
--      Class = xxx           Target的Class
--      Instance = xxx        Target的实例
--      fnSetTargetParams(self, TargetInstance)   设置Target的Parmas
--      tbDummyInstanceList     dummy instance list
-- }
PVE01BattleStep.tbStageTargetList = {}
PVE01BattleStep.nCurrentStage = 0   -- 当前stage

PVE01BattleStep.fnGetPlayerStartJsonData = nil

PVE01BattleStep.tbRestartTimer = nil

-- 解析npc json data
local function ParseNpcsJsonData(self, tbNpcJsonTableFile)
    if tbNpcJsonTableFile == nil then
        error('PVE01BattleStep ParseNpcsJsonData() tbNpcJsonTableFile is nil')
        return
    end
    local nGroupIndex = 0
    local tbNpcJsonDataList = self.tbGroupJsonDataMap.tbNpcJsonDataList
    for _, tbNpcJsonData in pairs(tbNpcJsonTableFile) do
        nGroupIndex = tbNpcJsonData.GroupIndex
        if tbNpcJsonDataList[nGroupIndex] == nil then
            tbNpcJsonDataList[nGroupIndex] = {}
        end
        local tbNpcDataGroupList = tbNpcJsonDataList[nGroupIndex]
        table.insert(tbNpcDataGroupList, tbNpcJsonData)
    end
end

-- 解析 dummy json data
local function ParseDummysJsonData(self, tbDummyJsonTableFile)
    if tbDummyJsonTableFile == nil then
        logerror('PVE Battle Step ParseDummysJsonData : ', tbDummyJsonTableFile)
        return
    end

    local nGroupIndex = 0
    local tbDummyJsonDataList = self.tbGroupJsonDataMap.tbDummyJsonDataList
    for _, tbDummyJsonData in pairs(tbDummyJsonTableFile) do
        nGroupIndex = tbDummyJsonData.GroupIndex
        if tbDummyJsonDataList[nGroupIndex] == nil then
            tbDummyJsonDataList[nGroupIndex] = {}
        end
        local tbDummyDataGroupList = tbDummyJsonDataList[nGroupIndex]
        table.insert(tbDummyDataGroupList, tbDummyJsonData)
    end
end

local function ParsePlayerStartsJsonData(self, tbPlayerStartsJsonTableFile)
    if tbPlayerStartsJsonTableFile == nil then
        logerror('PVE01 Battle Step ParsePlayerStartsJsonData : ', tbPlayerStartsJsonTableFile)
        return
    end

    local nGroupIndex = 0
    local tbPlayerStartsJsonDataList = self.tbGroupJsonDataMap.tbPlayerStartsJsonDataList
    for _, tbPlayerStartJsonData in pairs(tbPlayerStartsJsonTableFile) do
        nGroupIndex = tbPlayerStartJsonData.GroupIndex
        if tbPlayerStartsJsonDataList[nGroupIndex] == nil then
            tbPlayerStartsJsonDataList[nGroupIndex] = {}
        end
        local tbPlayerStartDataGroupList = tbPlayerStartsJsonDataList[nGroupIndex]
        table.insert(tbPlayerStartDataGroupList, tbPlayerStartJsonData)
    end
end
 
local function SetPVE01BattleTarget(self, PVE01TargetInstance, NpcInstanceList)
    if PVE01TargetInstance == nil then
        error('PVE01BattleStep SetPVE01BattleTarget(), PVE01TargetInstance == nil')
        return
    end

    if NpcInstanceList == nil then
        error('PVE01BattleStep SetPVE01BattleTarget(), NpcInstanceList == nil')
        return
    end
    PVE01TargetInstance:SetParams(GameObjectTypeDef.Npc,  NpcInstanceList)
end

local function SetRuntimePawnDeadTarget(self, PawnDeadTargetInstance, NpcInstanceList)
    -- 找出当前所有的Boss
    local tbAllGameObjectMap = GameObjectSystem:GetAllByObjectType(GameObjectTypeDef.Npc)
    local nBossCount = 0
    for GameObject, _ in pairs(tbAllGameObjectMap) do
        if GameObject:IsDead() == false and GameObject.bIsBoss then
            nBossCount = nBossCount + 1
            PawnDeadTargetInstance:AddTargetPawn(GameObject)
        end
    end
    log("PVE01BattleStep SetRuntimePawnDeadTarget", nBossCount, " bosses.")
    PawnDeadTargetInstance:SetCanComplete(true)
end

PVE01BattleStep.tbStageTargetList[1] = {
    TargetClass = PVE01BattleTargetClass,
    fnSetTargetParams = SetPVE01BattleTarget,
    TargetInstance = nil
}

PVE01BattleStep.tbStageTargetList[2] = {
    TargetClass = BattleRuntimePawnDeadTargetClass,
    fnSetTargetParams = SetRuntimePawnDeadTarget,
    TargetInstance = nil
}

local function CreateStageTarget(self, nStageIndex)
    local tbStageTargetInfo = self.tbStageTargetList[nStageIndex]
    tbStageTargetInfo.TargetInstance = self:CreateTarget(tbStageTargetInfo.TargetClass)
    local TargetInstance = tbStageTargetInfo.TargetInstance
    local nGroupIndex = nStageIndex

    local tbNpcJsonDataList  = self.tbGroupJsonDataMap.tbNpcJsonDataList[nGroupIndex]
    if tbNpcJsonDataList == nil then
        logerror('PVE01BattleStep CreateStageTarget() tbNpcJsonDataList == nil, nGroupIndex : ', nGroupIndex)
        return
    end

    local tbNpcInstanceList = {}
    local GameNpcInstanceOrTable = nil
    for _, tbNpcJsonData in pairs(tbNpcJsonDataList) do
        GameNpcInstanceOrTable = SpawnerSystem:SpawnById(tbNpcJsonData.SpawnerId, false)
	    assert(GameNpcInstanceOrTable)
        if(GameNpcInstanceOrTable.ObjectType == nil) then
            for _, Instance in ipairs(GameNpcInstanceOrTable) do
                table.insert(tbNpcInstanceList, Instance)
            end
        else
            table.insert(tbNpcInstanceList, GameNpcInstanceOrTable)
        end
    end

    local tbDummyJsonDataList = self.tbGroupJsonDataMap.tbDummyJsonDataList[nGroupIndex]
    local GameDummyInstance = nil
    if tbDummyJsonDataList ~= nil then
        if tbStageTargetInfo.tbDummyInstanceList == nil then
            tbStageTargetInfo.tbDummyInstanceList = {}
        end
        for _, tbDummyJsonData in pairs(tbDummyJsonDataList) do
            GameDummyInstance = SpawnerSystem:SpawnById(tbDummyJsonData.SpawnerId, false)
            assert(GameDummyInstance)
            table.insert(tbStageTargetInfo.tbDummyInstanceList, GameDummyInstance)
        end
    end

    tbStageTargetInfo.fnSetTargetParams(self, TargetInstance, tbNpcInstanceList)

    return TargetInstance
end

local function GetStageCount(self)
    return BaseUtil:GetTableCount(self.tbGroupJsonDataMap.tbNpcJsonDataList)
end

local function GetTargetCount(self)
    return #self.tbStageTargetList
end

-- stage 结束
local function OnStageFinished(self)
    local nStageIndex = self.nCurrentStage
    local tbStageTargetInfo = self.tbStageTargetList[nStageIndex]
    if tbStageTargetInfo ~= nil and tbStageTargetInfo.tbDummyInstanceList ~= nil then
        for _, GameDummyInstance in pairs(tbStageTargetInfo.tbDummyInstanceList) do
            GameObjectSystem:DestroyDummyInGameMode(GameDummyInstance:GetUEActorUniqueId())
        end
    end
end

local function ResetPlayerPosition(self, nStageIndex)
    local DEFAULT_PVE_TEAM_ID = 1
    local NEED_RESET_STAGE = 2
    if nStageIndex == NEED_RESET_STAGE then
        local tbPlayerStartsJsonDataList = self.tbGroupJsonDataMap.tbPlayerStartsJsonDataList[nStageIndex]
        local tbTransform = nil
        local nTeamId = DEFAULT_PVE_TEAM_ID
        local tbTeamMemberList = BattleTeamSystem:GetTeamMembers(nTeamId)
        if tbTeamMemberList == nil then
            error('ResetPlayerPosition Battle team system has empty team : ' .. nTeamId)
            return
        end
        for k, GamePlayerMember in pairs(tbTeamMemberList) do
            if not GamePlayerMember:IsDead() then
                tbTransform = tbPlayerStartsJsonDataList[k].Transform
                local pLocation = Vector{X = tbTransform.X, Y = tbTransform.Y, Z = tbTransform.Z}
                if UEActorHelper:TeleportShip(GamePlayerMember.pUEActor, pLocation, tbTransform.Yaw, true) then
                    D2CHelper:PlayerSetCameraYaw(GamePlayerMember, tbTransform.Yaw)
                    D2CHelper:PlayerSwitchCommonHandlerMode(GamePlayerMember)
                else
                    logwarning("PVE01BattleStep ResetPlayerPosition teleport ship failed.")
                end
            end
        end
    end
end

-- 开始下一个阶段
local function StartNextStage(self)
    self.nCurrentStage = self.nCurrentStage + 1
    local nCurrentStage = self.nCurrentStage
    local nStageCount  = GetStageCount(self)
    local nTargetCount = GetTargetCount(self)
    if nCurrentStage > nStageCount then
        error('PVE01BattleStep StartNextStage() current stage greater than stage count : ', self.nCurrentStage, nStageCount)
        return
    end

    if nCurrentStage > nTargetCount then
        error('PVE01BattleStep StartNextStage() current stage greater than target count : ', self.nCurrentStage, nTargetCount)
        return
    end

    local TargetInstance = CreateStageTarget(self, nCurrentStage)
    if TargetInstance == nil then
        error('PVE01BattleStep StartNextStage() target instance is nil' )
        return
    end
    TargetInstance:Start()
    BattleObjectiveHelper:ObjectiveStepForward()
end

local function IsStepFinished(self, TargetFinishedInstance)
    local nStageCount = GetTargetCount(self)
    local bAllFinishedTarget = false
    local bHaveNextGroupData = false

    for i = 1, nStageCount do
        if self.tbStageTargetList[i] == TargetFinishedInstance then
            if i == nStageCount then
                bAllFinishedTarget = true
            end
            break
        end
    end

    local nNextStageIndex = self.nCurrentStage + 1
    bHaveNextGroupData = self.tbGroupJsonDataMap.tbNpcJsonDataList[nNextStageIndex] ~= nil
    return bAllFinishedTarget or (not bHaveNextGroupData)
end

local function IsNextStageExistBoss(self)
    local EXIST_BOSS_STAGE = 2
    local nNextStage = self.nCurrentStage + 1
    if nNextStage == EXIST_BOSS_STAGE then
        return true
    end

    return false
end

local function PlayBossBornMatinee(self, nMatineeId, fnFinishedCallback)
    self.SelfEventHelper:RegisterEvent(CommonEventDef.EV_BATTLE_MATINEE_END, self, fnFinishedCallback)
    BattleInteractionHelper:PlayMatinee(nMatineeId)
end

local function ProcessTargetComplete(self, TargetInstance)
    OnStageFinished(self)
    local bAllFinished = IsStepFinished(self, TargetInstance)
    if bAllFinished == true then
        return true
    end

-- 前置 Reset player position 以防止在 player 下一阶段开始时由于 server 卡顿导致 player position 不能立即同步，从而使客户端有
-- 较大重置位置的延迟，出现位置来回跳的现象，前置重置位置可以使用 play matinee 掩盖位置同步延迟，使客户端平滑过渡
    ResetPlayerPosition(self, self.nCurrentStage + 1)
    if IsNextStageExistBoss(self) then
        PlayBossBornMatinee(self, self.tbTemplateData.nBossBornMatineeId, StartNextStage)
    else 
        StartNextStage(self)
    end
    
    return bAllFinished
end

local function KillAllNpc()
    local tbAllGameObjectMap = GameObjectSystem:GetAllByObjectType(GameObjectTypeDef.Npc)
    for GameObject, _ in pairs(tbAllGameObjectMap) do
        GameObjectSystem:DestroyNpcInGameMode(GameObject:GetUEActorUniqueId())
    end
end

local function ResetStage(self, tbPlayerList)
    local nCurrentStage = self.nCurrentStage

    local tbStageTargetInfo = self.tbStageTargetList[nCurrentStage]
    local TargetInstance = tbStageTargetInfo.TargetInstance
    assert(TargetInstance)
    if TargetInstance.Reset then
        TargetInstance:Reset()
    end

    -- UnregisterEvent to avoid target complete during restarting phase. Recover later at the end of ResetStage.
    TargetInstance:UnregisterEvent()

    -- 复活所有的player
    local tbTransform = nil
    local tbPlayerStartsJsonDataList = self.tbGroupJsonDataMap.tbPlayerStartsJsonDataList
    local tbCurrentStagePlayerStartsList = tbPlayerStartsJsonDataList[nCurrentStage]
    for k, GamePlayerMember in pairs(tbPlayerList) do
        tbTransform = tbCurrentStagePlayerStartsList[k].Transform
        GamePlayerMember:Reborn(tbTransform.X, tbTransform.Y, tbTransform.Z, tbTransform.Yaw)
        D2CHelper:PlayerSetCameraYaw(GamePlayerMember, tbTransform.Yaw)
    end

    -- 删除所有的Npc
    KillAllNpc()

    local nGroupIndex = nCurrentStage
    local tbNpcJsonDataList  = self.tbGroupJsonDataMap.tbNpcJsonDataList[nGroupIndex]
    if tbNpcJsonDataList == nil then
        logerror('PVE01BattleStep CreateStageTarget() tbNpcJsonDataList == nil, nGroupIndex : ', nGroupIndex)
        return
    end

    local tbNpcInstanceList = {}
    local GameNpcInstanceOrTable = nil
    for _, tbNpcJsonData in pairs(tbNpcJsonDataList) do
        GameNpcInstanceOrTable = SpawnerSystem:SpawnById(tbNpcJsonData.SpawnerId, false)
	    assert(GameNpcInstanceOrTable)
        if(GameNpcInstanceOrTable.ObjectType == nil) then
            for _, Instance in ipairs(GameNpcInstanceOrTable) do
                table.insert(tbNpcInstanceList, Instance)
            end
        else
            table.insert(tbNpcInstanceList, GameNpcInstanceOrTable)
        end
    end
    
    TargetInstance:RegisterEvent()
    tbStageTargetInfo.fnSetTargetParams(self, TargetInstance, tbNpcInstanceList)

    return TargetInstance
end

local function CheckRestart(self, tbPlayerList)
    log("Pve01BattleStep check restart.")

    if self.tbRestartTimer ~= nil then
        log("Pve01BattleStep CheckRestart ignore. Restarting in progress...")
        return false
    end

    if tbPlayerList == nil then
        error('Pve01BattleStep CheckRestart empty players.')
        return false
    end

    local bAllTeamMemberDead = true
    for k, GamePlayerMember in pairs(tbPlayerList) do
        if GamePlayerMember:IsDead() == false then
            bAllTeamMemberDead = false
        end
    end

    if bAllTeamMemberDead == false then
        return false
    end

    local fnRestart = function()
        self.tbRestartTimer = nil
        ResetStage(self, tbPlayerList)
    end

    local nDelayRestartTime = self.tbTemplateData.nRebornCountdown
    NetworkManager:GetRPCNetworkProxy():Multicast(ProtoDC.d2c_ReviveCountdown, { countdown = nDelayRestartTime })
    self.tbRestartTimer = DelayTimer:DelayRun(fnRestart, nDelayRestartTime)

    return true
end

local function OnPawnDead(self, DeadObject)
    local nObjectType = DeadObject.ObjectType
    if(nObjectType == GameObjectTypeDef.PlayerSelf) then
        EventManager:OnFireEvent(CommonEventDef.EV_BATTLE_REVIVE_INFOANDSHOW, BattleReviveModeTypeDef.Reset, DeadObject)
        local nTeamId = BattleTeamSystem:FindTeamId(DeadObject)
        local tbPlayerList = BattleTeamSystem:GetTeamMembers(nTeamId)
        CheckRestart(self, tbPlayerList)
    end
end

function PVE01BattleStep:OnPlayerLogout(tbGamePlayer)
    PVE01BattleStep.super.OnPlayerLogout(self, tbGamePlayer)
    local tbPlayers = {}
    local nTeamId = BattleTeamSystem:FindTeamId(tbGamePlayer)
    local tbPlayerList = BattleTeamSystem:GetTeamMembers(nTeamId)
    if tbPlayerList ~= nil then
        for _, v in ipairs(tbPlayerList) do
            if v ~= tbGamePlayer then
                table.insert(tbPlayers, v)
            end
        end
    end
    if #tbPlayers > 0 then
        CheckRestart(self, tbPlayers)
    end
end

function PVE01BattleStep:Init()
    PVE01BattleStep.super.Init(self)
    self.szName = "PVE01BattleStep"
    self.tbGroupJsonDataMap = {}
    self.tbGroupJsonDataMap.tbNpcJsonDataList = {}
    self.tbGroupJsonDataMap.tbDummyJsonDataList = {}
    self.tbGroupJsonDataMap.tbPlayerStartsJsonDataList = {}

    ------------------------------------------------
    self.SelfEventHelper:RegisterEvent(CommonEventDef.EV_GAME_OBJECT_ON_PAWN_DEAD, self, OnPawnDead)
end

function PVE01BattleStep:ClearRestartTimer()
    if self.tbRestartTimer ~= nil then
        DelayTimer:ClearTimer(self.tbRestartTimer)
        self.tbRestartTimer = nil
    end
end

function PVE01BattleStep:Uninit()
    self:ClearRestartTimer()
    PVE01BattleStep.super.Uninit(self)
end

function PVE01BattleStep:OnCompleted()
    self:ClearRestartTimer()
    PVE01BattleStep.super.OnCompleted(self)
end

function PVE01BattleStep:OnForceStop()
    self:ClearRestartTimer()
    PVE01BattleStep.super.OnForceStop(self)
end

function PVE01BattleStep:SetParams(tbGameState, tbTemplateData, tbJsonTableFile, fnGetPlayerStartJsonData)
    self.PVE01GameState = tbGameState
    self.tbTemplateData = tbTemplateData

    self.rBattlePlayerResultStep = tbGameState.rBattlePlayerResultStep
    local rStep = self.rBattlePlayerResultStep
    rStep.nStepTime = tbTemplateData.nShowResultTime
    rStep.Results = {}

    ParseNpcsJsonData(self, tbJsonTableFile.tbContainer.DungeonTeamNPCSpawners)
    ParseNpcsJsonData(self, tbJsonTableFile.tbContainer.DungeonNPCSpawners)
    ParseDummysJsonData(self, tbJsonTableFile.tbContainer.DungeonDummySpawners)
    ParsePlayerStartsJsonData(self, tbJsonTableFile.tbContainer.DungeonPlayerStarts)
    self.fnGetPlayerStartJsonData = fnGetPlayerStartJsonData
end

-- 同步Step信息
function PVE01BattleStep:RepStepInfo(bRepNow)
    -- if(bRepNow) then
    --     self.rPVE01BattleStepInfo.RepNow()
    -- else
    --     self.rPVE01BattleStepInfo.Rep()
    -- end
    PVE01BattleStep.super.RepStepInfo(self, bRepNow)
end

function PVE01BattleStep:OnPlayerLogin(tbGamePlayer)
    PVE01BattleStep.super.OnPlayerLogin(self, tbGamePlayer)
    BattleInteractionHelper:PlayerPlayMatinee(tbGamePlayer, self.tbTemplateData.nEnterSceneMatineeId)
end

-- 子类必须重载，将当前状态的快照写入replicate属性中，这里可根据情况调用rep，这函数会在新玩家登入时调用
function PVE01BattleStep:SnapshotToReplicatedProperty()

    return true
end

-- 当Target结束时候会调用这个函数
-- return true  该step完成
-- return false 该step没完成
function PVE01BattleStep:CheckComplete(BattleTarget)
    local bRet = ProcessTargetComplete(self, BattleTarget)
    if true == bRet then
        local tbResults  = self.rBattlePlayerResultStep.Results
        local tbAllTeamsInfo = BattleTeamSystem:GetAllTeamInfo()
        for _, tbTeamInfo in pairs(tbAllTeamsInfo) do
            for _, nPlayerId in pairs(tbTeamInfo.tbPlayerIds) do
                local tbResult = {}
                tbResult.nPlayerId = nPlayerId
                tbResult.nResult = PLAYER_WIN
                table.insert(tbResults, tbResult)
            end
        end
    end
    return bRet
end

function PVE01BattleStep:Start()
    PVE01BattleStep.super.Start(self)
    StartNextStage(self)
end

function PVE01BattleStep:Complete()
    KillAllNpc()
    SpawnerSystem:DestroyAll()
    self:CalculateResult()
    PVE01BattleStep.super.Complete(self)
end

-- 将结果写入到GameState数据面板里
function PVE01BattleStep:CalculateResult()
    
end

return PVE01BattleStep

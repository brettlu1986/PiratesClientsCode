local luaclass = require("luaclass")
local BattleGameModeBaseClass = dynamic_require("BattleCommonGameMode")
local TestGameMode = luaclass("TestGameMode", BattleGameModeBaseClass)

local TestGameModeStepClass = require("TestGameModeStep")
--local CampDef = require("CampDefine")
local TemplateTypeDef = require("TemplateTypeDef")
local GameObjectSystem = dynamic_require("GameObjectSystem")
local SpawnerDef = require("SpawnerDef")
local SpawnerSystem = require("SpawnerSystem")
local BattleTransformPointHelper = require("BattleTransformPointHelper")
local GlobalVariableSystem = dynamic_require("GlobalVariableSystem")

TestGameMode.tbPlayerStarts = nil
TestGameMode.nPlayerStartIndex = 0


local function InitGame(self)
    GlobalVariableSystem:EnableTemplateActor(false)
    local tbContainer = self.tbJsonTableFile.tbContainer
    BattleTransformPointHelper:Init(tbContainer)
end

local function UninitGame(self)
    BattleTransformPointHelper:Uninit()
    GlobalVariableSystem:EnableTemplateActor(true)
end

function TestGameMode:Init(nSubDungonId, pGameMode, tbGameState, tbJsonTableFile)
    TestGameMode.super.Init(self, nSubDungonId, pGameMode, tbGameState, tbJsonTableFile)

    self.tbPlayerStarts = pGameMode:GetAllPlayerStart()
    self.nPlayerStartIndex = 0

    self:CreateStep(TestGameModeStepClass, tbGameState.nStepId)
    InitGame(self)

    return true
end

function TestGameMode:Uninit()
    UninitGame(self)
    TestGameMode.super.Uninit(self)
end

function TestGameMode:FindPlayerStartJsonData(tbGamePlayer)
    --[[
    local tbPlayerStarts = self.tbPlayerStarts
    if(tbPlayerStarts == nil or #tbPlayerStarts == 0) then
        logerror("TestGameMode:FindPlayerStartJsonData failed, Can not find player start")
        return
    end

    local nCount = #tbPlayerStarts
    self.nPlayerStartIndex = self.nPlayerStartIndex + 1
    local nIndex = self.nPlayerStartIndex % nCount
    if(nIndex == 0) then
        nIndex = nCount
    end
    ]]
    --local pPlayerStartActor = tbPlayerStarts[nIndex]
    --local pLocation = EngineExtActorShell.GetActorLocation(pPlayerStartActor)
    --local pRotation = EngineExtActorShell.GetActorRotation(pPlayerStartActor)
    local tbJsonData = {}
    tbJsonData.Transform = {}
    local tbTransform = tbJsonData.Transform
    tbTransform.X = 0
    tbTransform.Y = -6695.0
    tbTransform.Z = 4000.0
    --tbTransform.Yaw = pRotation.Yaw
    tbJsonData.CampType = 1

    return tbJsonData
end

function TestGameMode:SpawnPlayerPawn(tbGamePlayer, bPossess)
    local tbStartJsonData = self:FindPlayerStartJsonData(tbGamePlayer)
    if(tbStartJsonData == nil) then
        logerror("TestGameMode:OnPlayerSpawnPawn failed, FindPlayerStartJsonData is invalid", tbGamePlayer.nPlayerId)
        return false
    end

    local tbPrepareInfo = tbGamePlayer.tbPrepareInfo
    local tbSpawnInfo = {}
    tbSpawnInfo.tbStartJsonData = tbStartJsonData
    tbSpawnInfo.nTemplateType = TemplateTypeDef.HUMAN
    tbSpawnInfo.nTemplateId = tbPrepareInfo.nHumanId

    local bRet = GameObjectSystem:SpawnPlayerSelfUEActorInGameMode(tbGamePlayer, tbPrepareInfo, tbSpawnInfo, bPossess)
    if(not bRet) then
        logerror("TestGameMode:OnPlayerSpawnPawn failed, the returned gameobject is nil", tbGamePlayer.nPlayerId)
        return false
    end

    return true
end

function TestGameMode:OnPlayerLogin(tbGamePlayer)
    TestGameMode.super.OnPlayerLogin(self,tbGamePlayer)
end

function TestGameMode:OnPlayerLogout(tbGamePlayer)
    TestGameMode.super.OnPlayerLogout(self, tbGamePlayer)
    GameObjectSystem:DestroyPlayerSelfInGameMode(tbGamePlayer:GetServerInstanceId())
end

function TestGameMode:OnStartStep(Step)
    log("TestGameMode:OnStartStep")
    
    -- 地图上生成资源
    local tbTypes = {
        [SpawnerDef.SpawnerType.ITEMDROP] = true,
        [SpawnerDef.SpawnerType.VEHICLE] = true,
        [SpawnerDef.SpawnerType.NPC] = true,
    }
    SpawnerSystem:AsyncSpawnAllByType(tbTypes)

    TestGameMode.super.OnStartStep(self, Step)
end

return TestGameMode

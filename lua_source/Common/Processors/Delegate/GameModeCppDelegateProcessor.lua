local luaclass = require("luaclass")
local CppDelegateProcessorBaseClass = require("CPPDelegateProcessorBase")
local GameModeCppDelegateProcessor = luaclass("GameModeCppDelegateProcessor", CppDelegateProcessorBaseClass)

local ReplicatedPropertyGenerateSystem = require("ReplicatedPropertyGenerateSystem")
local BattleGameModeSystem = dynamic_require("BattleGameModeSystem")
local GameObjectSystem = dynamic_require("GameObjectSystem")
local BattlePrepareSystem = require("BattlePrepareSystem")
local GlobalVariableSystem = dynamic_require("GlobalVariableSystem")

local EventManager = require("EventManager")
local CommonEventDef = require("CommonEventDef")
local DungeonDataTable = require("DungeonDataTable")

local function TryMockPlayerData(nPlayerId, szOptions)
    local szPlayerName = GameplayStatics.ParseOption(szOptions, "PlayerName")
    EventManager:OnFireEvent(CommonEventDef.EV_GAME_MODE_TRY_MOCK_PLAYER_DATA, nPlayerId, szPlayerName)
end

function GameModeCppDelegateProcessor:TryMockApproveLogin()
    local tbInOutParams = {}
    tbInOutParams.bSkipApproveLogin = false
    EventManager:OnFireEvent(CommonEventDef.EV_GAME_MODE_TRY_MOCK_APPROVE_LOGIN, tbInOutParams)
    return tbInOutParams.bSkipApproveLogin
end

function GameModeCppDelegateProcessor:ParsePlayerId(szOptions)
    local szPlayerId = GameplayStatics.ParseOption(szOptions, "PlayerID")
    local nPlayerId = -1
    if szPlayerId ~= "" and szPlayerId ~= nil then
        nPlayerId = tonumber(szPlayerId)
    end

    -- 如果有MockSystem接入，这里会hook一下下
    TryMockPlayerData(nPlayerId, szOptions)

    if (nPlayerId == 0) then
        logerror("Invalid PlayerId:" .. nPlayerId)
        return nil
    end

    return nPlayerId
end

function GameModeCppDelegateProcessor:VerifyVersion(szOptions)
    local szVersion = GameplayStatics.ParseOption(szOptions, "Version")
    local szPlatform = GameplayStatics.ParseOption(szOptions, "Platform")
    if szVersion == "" or szPlatform == "" then
        return ""
    end
    local nPlatform = tonumber(szPlatform)

    local tbVersionInfo = GlobalVariableSystem:GetVersionInfo()
    if tbVersionInfo == nil then
        log("VerifyVersion info is nil ", szVersion, nPlatform)
        return ""
    end
    if tbVersionInfo[nPlatform] == nil then
        log(string.format("OnApproveLogin the platform %s version is nil ", nPlatform))
        return ""
    end

    if tbVersionInfo[nPlatform] ~= szVersion then
        return string.format("OnApproveLogin failed, the platform %s version %s is invalid ", nPlatform, szVersion)
    end

    return ""
end

------------------------------------------------------------------------------------------------
-- 验证，过了验证会创建controller，所以在这里吧能判断的都判了，要不然就晚了
function GameModeCppDelegateProcessor:OnApproveLogin(szOptions)
    log("OnGameModeApproveLogin", szOptions)

    if(self:TryMockApproveLogin()) then
        return ""
    end

    return self:ApproveLogin(szOptions)
end

function GameModeCppDelegateProcessor:ApproveLogin(szOptions)
    local nPlayerId = self:ParsePlayerId(szOptions)
    if(nPlayerId == nil) then
        return "OnApproveLogin failed, the player id is invalid"
    end

    local szVersionError = self:VerifyVersion(szOptions)
    if (string.len(szVersionError) > 0) then
        return szVersionError
    end

    local tbPrepareInfo = BattlePrepareSystem:GetPlayerPrepareInfo(nPlayerId)
    if(tbPrepareInfo == nil) then
        return "OnApproveLogin failed, cannot find playerid from prepare system"..nPlayerId
    end
    return ""
end

local function OnInitGameMode(pGameMode, szOptions)
    log("OnInitGameMode", szOptions)
    local szDungeonId = GameplayStatics.ParseOption(szOptions, "DungeonId")
    local nDungeonId = tonumber(szDungeonId)
    if (not nDungeonId) or (nDungeonId <= 0) then
        logerror("Invalid DungeonId in Options.")
        return
    end

    local szDungeonMode = GameplayStatics.ParseOption(szOptions, "DungeonMode")
    local nDungeonMode = tonumber(szDungeonMode) or 0

    -- 尝试使 Mock 模式下不填写 DungeonMode 可以运行，随机一个 DungeonMode
    if nDungeonMode == 0 then
        local tbDungeonDataTemplate = DungeonDataTable:GetTemplate(nDungeonId)
        local nModeCount = #tbDungeonDataTemplate.tbModes
        if nModeCount > 0 then
            nDungeonMode = tbDungeonDataTemplate.tbModes[math.random(1, nModeCount)]
            pGameMode.OptionsString = pGameMode.OptionsString.."?DungeonMode="..nDungeonMode
            log("NOTE: random dungeon mode to", nDungeonMode, "in MOCK mode. If not in mock mode, there should be error. Set OptionString to", pGameMode.OptionsString)
        end
    end

    -- local SceneResDataTable = require("SceneResDataTable")
    -- local DungeonDataTable = require("DungeonDataTable")
    -- local nResId = DungeonDataTable:GetTemplate(nDungeonId).nResID
    -- local szMapName = SceneResDataTable:GetTemplate(nResId).szMapName
    -- if CommonShell.GetCommon(GWorld):EnterDungeonNavMode():LoadGridData(szMapName) then
    --     log("Load nav grid data for dungeon " .. szMapName)
    -- else
    --     logerror("Fail to load nav grid data for dungeon " .. szMapName)
    -- end

    BattleGameModeSystem:InitGameMode(pGameMode, nDungeonId, nDungeonMode)
    EventManager:OnFireEvent(CommonEventDef.EV_INIT_GAME_MODE_COMPLETE)
end

local function OnStartPlay(pGameMode, szOptions)
    BattleGameModeSystem:StartPlay()
end

function GameModeCppDelegateProcessor:OnInitNewPlayer(pController, nControllerUniqueId, nControllerNetGuid, szOptions)
    log("OnInitNewPlayer", nControllerUniqueId, nControllerNetGuid, szOptions)
    local nPlayerId = self:ParsePlayerId(szOptions)
    if(nPlayerId == nil) then
        logerror("OnInitNewPlayer failed, the player id is invalid")
        return
    end

    local tbPrepareInfo = BattlePrepareSystem:GetPlayerPrepareInfo(nPlayerId)
    if(tbPrepareInfo == nil) then
        logerror("OnInitNewPlayer failed, cannot find playerid from prepare system", nPlayerId)
        return
    end

    --重连机制执行到这GameObject可能已经存在了
    local tbPlayer = GameObjectSystem:FindPlayerByPlayerId(nPlayerId)
    BattleGameModeSystem:SetPlayerReLoading(nPlayerId, tbPlayer ~= nil)
    
    if tbPlayer then
        --强制关闭掉上一个Controller的Connection.
        if tbPlayer.pUEController then
            ServerShell.GetServer(GWorld):KickPlayer(tbPlayer.pUEController)
        end

        GameObjectSystem:RestorePlayerSelf(tbPlayer, pController, nControllerNetGuid, nControllerUniqueId)
    else
        local GameObject = BattleGameModeSystem:CreatePlayerSelf(tbPrepareInfo,
            pController, nControllerNetGuid, nControllerUniqueId)
        if(GameObject == nil) then
            logerror("OnInitNewPlayer failed, the returned gameobject is nil")
            return
        end
    end

    ReplicatedPropertyGenerateSystem:SetReplicationCRC(pController)
end

-- StartLocation和StartRotation等公博去掉FindPlayerStart就可以不传到lua里了
local function OnSpawnDefaultPawnForController(nControllerUniqueId)
    log("OnSpawnDefaultPawnForController", nControllerUniqueId)

    local tbPlayerSelf = GameObjectSystem:FindByUniqueId(nControllerUniqueId)
    if(tbPlayerSelf == nil) then
        logerror("OnSpawnDefaultPawnForController failed, can not find gameobject,", nControllerUniqueId)
        return nil
    end

    local pController = tbPlayerSelf:GetUEController()
    local tbRetActor = nil
    --重连机制不用新创建Pawn
    if tbPlayerSelf:GetModelActor() then
        --possess
        local tbObject = BattleGameModeSystem:ReLoginPossessGamePlayer(tbPlayerSelf)
        tbRetActor = tbObject:GetModelActor()
    else
        BattleGameModeSystem:SpawnPlayerPawn(tbPlayerSelf, false)
        tbRetActor = tbPlayerSelf:GetModelActor()
    end

    pController:K2_SetActorTransform(tbRetActor:GetTransform())
    return tbRetActor
end

local function OnPostLogin(nPCUniqueId)
    log("OnGameModePostLogin", nPCUniqueId)

    local tbGamePlayer = GameObjectSystem:FindByUniqueId(nPCUniqueId)
    if(tbGamePlayer == nil) then
        logerror("OnPostLogin failed, cannot find player controller uniqueId", nPCUniqueId)
        return
    end
    BattleGameModeSystem:OnPlayerLogin(tbGamePlayer)
end

local function OnLogout(nPCUniqueId)
    log("OnGameModeLogout", nPCUniqueId)

    local tbGameMode = BattleGameModeSystem:GetGameMode()
    if tbGameMode ~= nil then
        -- 删除玩家
        local tbGamePlayer = GameObjectSystem:FindByUniqueId(nPCUniqueId)
        if(tbGamePlayer == nil) then
            log("OnLogout cannot find player uniqueId", nPCUniqueId)
            return
        end
        --local nPlayerId = tbGamePlayer.tbPrepareInfo.nPlayerId
        BattleGameModeSystem:OnPlayerLogout(tbGamePlayer)
        --BattlePrepareSystem:RemovePlayerPrepareInfo(nPlayerId)
    else
        -- this happened when we do nonsmooth travel from wild world to dungeon.
        -- for reason, please refer to comments in GetCurrentBattleWorld in ActorCppDelegateProcessor.lua
        log("Ignore logout event in battle.")
    end
end

local function OnEndPlay()
    log("OnGameModeEndPlay")
    BattleGameModeSystem:OnEndPlay()
end

function GameModeCppDelegateProcessor:OnStartGameModeManually(pGameMode, szOptions)
    log("OnStartGameModeManually", szOptions)
    OnInitGameMode(pGameMode, szOptions)
    OnStartPlay(pGameMode, szOptions)
end

function GameModeCppDelegateProcessor:Init()
    GameModeCppDelegateProcessor.super.Init(self)
    -- Register Gameplay Delegate
    local DelegateMgr = CommonShell.GetCommon(GWorld):GetGameDelegateManager().GameMode

    -- GameMode初始化相关
    if(not CommonShell.GetCommon(GWorld):IsPreloadMap()) then
        self:Register(DelegateMgr.OnInitGameMode, OnInitGameMode)
        self:Register(DelegateMgr.OnStartPlay, OnStartPlay)
    else
        self:RegisterMethod(DelegateMgr.OnStartGameModeManually, self, self.OnStartGameModeManually)
    end

    self:RegisterMethod(DelegateMgr.OnApproveLogin, self, self.OnApproveLogin)
    self:RegisterMethod(DelegateMgr.OnInitNewPlayer, self, self.OnInitNewPlayer)
    self:Register(DelegateMgr.OnSpawnDefaultPawnForController, OnSpawnDefaultPawnForController)
    self:Register(DelegateMgr.OnPostLogin, OnPostLogin)
    self:Register(DelegateMgr.OnLogout, OnLogout)
    self:Register(DelegateMgr.OnEndPlay, OnEndPlay)
    return true
end

return GameModeCppDelegateProcessor

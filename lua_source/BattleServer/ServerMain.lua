log("Init Battle Server Logic....")
local ManagerRoot = require("ManagerRoot")
local ManagerGroupDef = require("ManagerGroupDef")
local CppDelegate = require("CppDelegate")
local ShutDownChecker = require("ShutDownChecker")
local GlobalVariableSystem = dynamic_require("GlobalVariableSystem")

local pOnShutdownDelegate = nil
local pOnStartDungeon = nil
local pOnEndDungeon = nil
local pOnReadyToBeConnected = nil

-- 开始副本
local StartDungeon = function(nDungeonId)
    log("BattleServer start dungeon", nDungeonId)
    ServerShell.GetServer(GWorld):SetGameStatus(EPiratesGameStatus.BATTLE_SERVER)
    ManagerRoot:InitGroup(ManagerGroupDef.nDefaultGroupID)
    ManagerRoot:InitGroup(ManagerGroupDef.nBattleGroupID)
end

-- 结束副本
-- local EndDungeon = function()
--     log("BattleServer end dungeon")
--     ManagerRoot:UninitGroup(ManagerGroupDef.nBattleGroupID, true)
--     ManagerRoot:UninitGroup(ManagerGroupDef.nDefaultGroupID, true)
--     ServerShell.GetServer(GWorld):SetGameStatus(EPiratesGameStatus.NONE)
-- end

-- 开始接受客户端连接
local ReadyToBeConnected = function()
end

-- 整个lua结束
local OnShutdown = function()
    -- 反着来一遍
    ManagerRoot:UninitGroup(ManagerGroupDef.nBattleGroupID, true)
    ManagerRoot:UninitGroup(ManagerGroupDef.nDefaultGroupID, true)
    ManagerRoot:UninitGroup(ManagerGroupDef.nImmortalGroupID, true)
    ManagerRoot:UninitAll()
    pOnShutdownDelegate:Unbind()
    pOnStartDungeon:Unbind()
    pOnEndDungeon:Unbind()
    pOnReadyToBeConnected:Unbind()
    ShutDownChecker.Check()
    log("Battle server shut down")
end

local BindEvents = function ()
    -- local GameInstance = GameplayStatics.GetGameInstance(GWorld)
    -- pOnShutdownDelegate = CppDelegate:Bind(GameInstance.OnShutdown, OnShutdown)
    local OnUninitLua = CommonShell.Get(GWorld):GetGameDelegateManager().GameMisc.OnUninitLua
    pOnShutdownDelegate = CppDelegate:Bind(OnUninitLua, OnShutdown)

    local ServerShell = ServerShell.GetServer(GWorld)
    pOnStartDungeon = CppDelegate:Bind(ServerShell.OnStartDungeon, StartDungeon)
    --pOnEndDungeon = CppDelegate:Bind(ServerShell.OnStopDungeon, EndDungeon)
    pOnEndDungeon = CppDelegate:Bind(ServerShell.OnStopDungeon, OnShutdown)
    pOnReadyToBeConnected = CppDelegate:Bind(ServerShell.OnReadyToBeConnected, ReadyToBeConnected)
end

local InitManagerRoot = function()
    local Binder = require("ManagerGroupChangeBinder")
    local InitGroupCallback = function(nGroupID)
        Binder:InitGroup(nGroupID)
    end
    local UninitGroupCallback = function(nGroupID)
        Binder:UninitGroup(nGroupID)
    end
    ManagerRoot:SetInitGroupCallback(InitGroupCallback)
    ManagerRoot:SetUninitGroupCallback(UninitGroupCallback)

    log("ManagerRoot RegisterAllManagers start")
    ManagerRoot:RegisterAllManagers()
    log("ManagerRoot RegisterAllManagers end")
    ManagerRoot:InitGroup(ManagerGroupDef.nImmortalGroupID)

    if(not ServerShell.GetServer(GWorld):IsDungeonWithHub()) then
        StartDungeon()
    end
end

local GameStart = function()
    InitManagerRoot()
    BindEvents()
end

local LuaErrorReporter = function(Name, Reason, CallStack)
    logerror("Reason: " .. Reason)
    logerror("CallStack: " .. CallStack)

    if ServerShell.GetServer(GWorld):IsDungeonWithHub() and ServerShell.GetServer(GWorld):ShouldTriggerCrashDueToLuaError() then
        logerror("Server lua error. Aborting...")
        log("Trying to disable core dumps...")
        if ServerShell.GetServer(GWorld):SetDumpPolicy(false) then
            log("Successfully disable core dumps.")
        else
            log("Failed to disable core dumps.")
        end
        ServerShell.GetServer(GWorld):RequestExit(true)
    end
end

GlobalVariableSystem:SetEnableDebugLog(GWithEditor, GWithEditor, false)
setLuaErrorCallback(LuaErrorReporter)

GameStart()

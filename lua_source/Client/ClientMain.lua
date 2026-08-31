log("Init Client Logic....")

log("require ManagerRoot start")
local ManagerRoot = require("ManagerRoot")
local ManagerGroupDef = require("ManagerGroupDef")
local Binder = require("ManagerGroupChangeBinder")
local ShutDownChecker = require("ShutDownChecker")
local GlobalVariableSystem = require("GlobalVariableSystem_C")
local ProcedureTool = require("ProcedureTool")
log("require ManagerRoot end")

local pOnShutdownDelegate = nil
local GameEnd = function()
    -- 反着来一遍
    ProcedureTool:UninitAllGroups()
    ManagerRoot:UninitAll()
    pOnShutdownDelegate:Unbind()
    ShutDownChecker.Check()
end

local InitManagerRoot = function()
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

    log("ManagerRoot InitGroup start")
    ManagerRoot:InitGroup(ManagerGroupDef.nImmortalGroupID)
    log("ManagerRoot InitGroup end")

end

local BindShutdownEvent = function ()
    local CppDelegate = require("CppDelegate")
    -- local GameInstance = GameplayStatics.GetGameInstance(GWorld)
    -- local OnShutdown = GameInstance.OnShutdown
    -- pOnShutdownDelegate = CppDelegate:Bind(OnShutdown, GameEnd)
    local OnUninitLua = CommonShell.Get(GWorld):GetGameDelegateManager().GameMisc.OnUninitLua
    pOnShutdownDelegate = CppDelegate:Bind(OnUninitLua, GameEnd)
end

local GameStart = function()
    BindShutdownEvent()
    InitManagerRoot()
end

local LuaErrorReporter = function(Name, Reason, CallStack)
    if LogCatcher.IsEnabled() then
        BuglyCrashReportBPLibrary.ReportExceptionWithCategory(6, Name,  Reason, CallStack )
    end

    local UIUtils = require("UIUtils")
    local UIResourceDef = require("UIResourceDef")
    UIUtils.PrintScreen(Reason .. CallStack, 10, UIResourceDef.COLOR.RED.SLATE_COLOR)
end

GlobalVariableSystem:SetEnableDebugLog(GWithEditor, GWithEditor, false)
if (not GWithEditor) then
    LogCatcher.SetEnable(true)
end

log("Lua Main start")
setLuaErrorCallback(LuaErrorReporter)
GameStart()
log("Lua Main end")


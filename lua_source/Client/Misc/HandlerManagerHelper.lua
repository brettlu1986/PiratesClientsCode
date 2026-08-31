local HandlerManagerHelper = {}

local CppDelegate = require("CppDelegate")
local LuaDelegateClass = require("LuaDelegate")

local tbValueCache = {}
local pHandlerManager = nil
-- luacheck: push ignore
-- Holds HandlerManager
local pHandlerManagerHodler = nil
-- luacheck: pop
local pOnModeSwitchDelegate = nil
local fnSwitchMode = nil
local fnGetCurrentMode = nil

HandlerManagerHelper.OnModeSwitchDelegate = LuaDelegateClass()

setmetatable(HandlerManagerHelper, {
    __index = function(t, key)
        local pLocalValue = tbValueCache[key]
        if pLocalValue then
            return pLocalValue
        end
        pLocalValue = pHandlerManager[key]
        tbValueCache[key] = pLocalValue
        return pLocalValue
    end,
    __newindex = nil
})

local function OnModeSwitch(pMode)
    HandlerManagerHelper.OnModeSwitchDelegate:Fire(pMode)
end

function HandlerManagerHelper:Init(pObject)
    local pGameInstance = GameplayStatics.GetGameInstance(GWorld)
    pHandlerManager = ExtendBlueprintFunctions.CreateObject(pObject, pGameInstance)
    pHandlerManagerHodler = luaholder(pHandlerManager)
    pHandlerManager:Init()
    pGameInstance.HandlerManager = pHandlerManager
    fnSwitchMode = pHandlerManager.SwitchMode
    fnGetCurrentMode = pHandlerManager.GetCurrentMode
    tbValueCache = {}
    pOnModeSwitchDelegate = CppDelegate:Bind(pHandlerManager.OnModeSwitchDispatcher, OnModeSwitch)
    log("HandlerManager init.")
end

function HandlerManagerHelper:Uninit()
    if pOnModeSwitchDelegate then
        pOnModeSwitchDelegate:Unbind()
        pOnModeSwitchDelegate = nil
    end
    local pGameInstance = GameplayStatics.GetGameInstance(GWorld)
    pGameInstance.HandlerManager = nil
    pHandlerManagerHodler = nil
    pHandlerManager = nil
    log("HandlerManager uninit.")
end

function HandlerManagerHelper:SwitchMode(pHandlerMode)
    fnSwitchMode(pHandlerManager, pHandlerMode)
end

function HandlerManagerHelper:GetCurrentMode()
    return fnGetCurrentMode(pHandlerManager)
end

function HandlerManagerHelper:Get()
    return pHandlerManager
end

function HandlerManagerHelper:CallFireDispatcher()
    pHandlerManager.FireDispatcher:call()
end

function HandlerManagerHelper:DoubleFireDispatcher()
    pHandlerManager.DoubleFireDispatcher:call()
end

function HandlerManagerHelper:CallNextCameraParamGroupDispatcher()
    pHandlerManager.NextCameraParamGroupDispatcher:call()
end

function HandlerManagerHelper:CallZoomCameraDispatcher(nValue)
    pHandlerManager.ZoomCameraDispatcher:call(nValue)
end

return HandlerManagerHelper

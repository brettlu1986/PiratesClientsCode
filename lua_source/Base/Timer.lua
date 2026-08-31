-----------------------------------------------------
--File Name    : Timer.lua
--Author       : chendi
--Create Time  : 2016-07-20
--Description  : 定时器和延迟执行工具类
-----------------------------------------------------

--[[
    Notice: You should always save the lua instance timer to somwhere to ensure that the timer will not be gc.
    Useage For use once next tick:
        Context.OnceTimer = Timer()	                    // the timer should save in your context
        local function Callback()                       // define the callback
            log("Once Called")
            Context.OnceTimer = nil                     // use once and drop it
        end
        Context.OnceTimer:SetTimer(Callback)            // default time to next tick and never loop
]]

local luaclass = require("luaclass")

local Timer = luaclass("Timer")
local GlobalVariableSystem = dynamic_require("GlobalVariableSystem")

local Signature = U4LDelegateProxy.Fire
local K2_SetTimer = KismetSystemLibrary.K2_SetTimer
local K2_ClearTimerHandle = KismetSystemLibrary.K2_ClearTimerHandle
local K2_PauseTimerHandle = KismetSystemLibrary.K2_PauseTimerHandle
local K2_UnPauseTimerHandle = KismetSystemLibrary.K2_UnPauseTimerHandle
local K2_IsTimerActiveHandle = KismetSystemLibrary.K2_IsTimerActiveHandle
local K2_IsTimerPausedHandle = KismetSystemLibrary.K2_IsTimerPausedHandle
local K2_GetTimerElapsedTimeHandle = KismetSystemLibrary.K2_GetTimerElapsedTimeHandle
local K2_GetTimerRemainingTimeHandle = KismetSystemLibrary.K2_GetTimerRemainingTimeHandle
local tbHandles = {}
local bEnableDebugLog = false

function Timer.CheckAndClearAllTimer()
    local tbIgnoreClearHandles = {}
    for k,v in pairs(tbHandles) do
        if v then
            if k.bIgnoreClear then
                tbIgnoreClearHandles[k] = v
            else
                logerror("!!!!!!!!!!!!! Please check timer clear,", k.DebugTraceback)
                K2_ClearTimerHandle(GWorld, v)
            end
        end
    end
    tbHandles = tbIgnoreClearHandles
end

-- Create a new lua instance timmer and set to start
function Timer.NewTimer(fnCallback, nTime, bLooping, szInfo)
    local OneTimer = Timer()
    if(GEnableNewLua) then
        szInfo = szInfo or getdebuginfo_f(fnCallback)
    end
    OneTimer:SetTimer(fnCallback, nTime, bLooping, szInfo)
    return OneTimer
end

-- Create a new lua instance timmer and set to start
function Timer.NewTimerMethod(tbSelf, fnCallback, nTime, bLooping, szInfo)
    assert(fnCallback ~= nil)
    local OneTimer = Timer()
    if(GEnableNewLua) then
        szInfo = szInfo or getdebuginfo_f(fnCallback)
        OneTimer:SetTimer(function(...) return fnCallback(tbSelf, ...) end,
            nTime, bLooping, szInfo)
    else
        OneTimer:SetTimer(function(_, ...) return fnCallback(tbSelf, ...) end, nTime, bLooping)
    end
    return OneTimer
end

-- Restart an existing timer or create a new timer and start it
-- Use this function to avoid judge everytime for a reused timer
function Timer.StartTimer(OneTimer, fnCallback, nTime, bLooping, szInfo)
    if OneTimer then
        OneTimer:Restart()
    else
        OneTimer = Timer.NewTimer(fnCallback, nTime, bLooping, szInfo)
    end
    return OneTimer
end

-- Restart an existing timer or create a new timer and start it
-- Use this function to avoid judge everytime for a reused timer
function Timer.StartTimerMethod(OneTimer, tbSelf, fnCallback, nTime, bLooping, szInfo)
    if OneTimer then
        OneTimer:Restart()
    else
        OneTimer = Timer.NewTimerMethod(tbSelf, fnCallback, nTime, bLooping, szInfo)
    end
    return OneTimer
end

-- Set a timer then save handle and delegate
-- fnCallback for callback function which will be called when the time is up
-- nTime for interval time the next call will be triggered
-- bLooping for whether the timer will be triggered again or not
function Timer:SetTimer(fnCallback, nTime, bLooping, szInfo)
    assert(fnCallback ~= nil)
    nTime = nTime or 0.01
    if nTime <= 0 then
        logerror("SetTimer passed a negative or zero time ", debug.traceback( ))
    end
    bLooping = bLooping or false
    if self.TimerHandle then
        error("TimerHandle already exists")
    end
    if(GEnableNewLua) then
        szInfo = szInfo or getdebuginfo_f(fnCallback)
    end
    if bEnableDebugLog or GlobalVariableSystem.bEnableCaptureLag then
        self.DebugTraceback = "Timer:SetTimer: \n" .. debug.traceback()
    end
    if(GlobalVariableSystem.bEnableCaptureLag) then
        local fnSavedCallback = fnCallback
        local fnNewCallback = function()
            local fStartTime = getseconds()
            fnSavedCallback()
            local fEndTime = getseconds()
            if(fEndTime - fStartTime >= GlobalVariableSystem.fCaptureLagTime) then
                printScreen("Timer laged!!!: " .. self.DebugTraceback)
                BuglyCrashReportBPLibrary.LogInfo(self.DebugTraceback)
            end
        end
        fnCallback = fnNewCallback
    end
    if not bLooping then
        local fnSavedCallback = fnCallback
        local fnNewCallback = function()
            self:Clear()
            fnSavedCallback()
        end
        fnCallback = fnNewCallback
    end
    self.TimerDelegate = createDelegate(Signature, fnCallback, szInfo)
    self.TimerHandle = K2_SetTimer(self.TimerDelegate, "Fire", nTime, bLooping, 0, 0)
    self.nTime = nTime
    self.bLooping = bLooping
    self.fnCallback = fnCallback
    tbHandles[self] = self.TimerHandle
end

-- Call this function when you don't need this timer,if you called this, you should not call 'Restart' 'Pause' and 'Resume'.
function Timer:Clear()
    if self.TimerHandle then
        K2_ClearTimerHandle(GWorld, self.TimerHandle)
        self.TimerHandle = nil
    end
    tbHandles[self] = nil
    self.TimerDelegate = nil
end

function Timer:SetIgnoreClear(bIgnoreClear)
    self.bIgnoreClear = bIgnoreClear
end

-- Stop this timmer by clear timmer handle
-- function Timer:Stop()
--     if self.TimerHandle then
--         K2_ClearTimerHandle(GWorld, self.TimerHandle)
--         self.TimerHandle = nil
--     end
-- end

-- Restart an existing timer which is stopped
function Timer:Restart(nTime, bLooping)
    if self.TimerDelegate then
        self.nTime = nTime or self.nTime
        self.bLooping = bLooping or self.bLooping
        self.TimerHandle = K2_SetTimer(self.TimerDelegate, "Fire", self.nTime, self.bLooping, 0, 0)
    else
        error("this timer is clear and cannot restart.")
    end
end

-- Pause this timer, use Resume to continue
function Timer:Pause()
    if self.TimerHandle then
        K2_PauseTimerHandle(GWorld, self.TimerHandle)
    else
        error("this timer is stopped or clear and cannot Pause.")
    end
end

-- Resume a paused timer
function Timer:Resume()
    if self.TimerHandle then
        K2_UnPauseTimerHandle(GWorld, self.TimerHandle)
    else
        error("this timer is stopped or clear and cannot Resume.")
    end
end

-- Get a timer is active or not
function Timer:IsActive()
    if self.TimerHandle then
        return K2_IsTimerActiveHandle(GWorld, self.TimerHandle)
    end
    return false
end

-- Get a timer is paused or not
function Timer:IsPaused()
    if self.TimerHandle then
        return K2_IsTimerPausedHandle(GWorld, self.TimerHandle)
    end
    return false
end

function Timer:GetElapsedTime()
    if self.TimerHandle then
        return K2_GetTimerElapsedTimeHandle(GWorld, self.TimerHandle)
    end
    return 0
end

function Timer:GetRemainingTime()
    if self.TimerHandle then
        return K2_GetTimerRemainingTimeHandle(GWorld, self.TimerHandle)
    end
    return 0
end

function Timer.EnableDebugLog(bEnabled)
    bEnableDebugLog = bEnabled
end

function Timer.IsDebugLogEnabled()
    return bEnableDebugLog
end

function Timer.StartOwnerTimer(Owner, szTimerName, fnFunc, nTime, bLoop)
    if(nTime == nil or nTime <= 0) then
        assert(not bLoop)
        if fnFunc then
            fnFunc(Owner)
        end
        return
    end

    local tbTimer = Owner._tbTimer
    local tbTimerFunc = Owner._tbTimerFunc
    if(tbTimer == nil) then
        assert(tbTimerFunc == nil)
        tbTimer = {}
        tbTimerFunc = {}
        Owner._tbTimer = tbTimer
        Owner._tbTimerFunc = tbTimerFunc
    end

    local TempTimer = tbTimer[szTimerName]
    local fnTempFunc = tbTimerFunc[szTimerName]
    if(fnTempFunc ~= fnFunc) then
        fnTempFunc = nil
        if(TempTimer) then
            TempTimer:Clear()
            TempTimer = nil
        end
    end

    if(TempTimer) then
        TempTimer:Restart(nTime, bLoop ~= nil and bLoop)
    else
        if(fnTempFunc == nil) then
            fnTempFunc = function()
                if not bLoop then
                    tbTimer[szTimerName] = nil
                end
                if fnFunc then
                    fnFunc(Owner)
                end
            end
            tbTimerFunc[szTimerName] = fnTempFunc
        end
        TempTimer = Timer.NewTimer(fnTempFunc, nTime, bLoop ~= nil and bLoop)
        tbTimer[szTimerName] = TempTimer
    end
end

function Timer.StopOwnerTimer(Owner, szTimerName)
    local tbTimer = Owner._tbTimer
    if(not tbTimer) then
        return false
    end

    local TempTimer = tbTimer[szTimerName]
    if(not TempTimer) then
        return false
    end

    TempTimer:Clear()
    tbTimer[szTimerName] = nil
    return true
end

function Timer.StopOwnerAllTimer(Owner, bDestroyAll)
    local tbTimer = Owner._tbTimer
    if(not tbTimer) then
        return
    end

    for _, TempTimer in pairs(tbTimer) do
        TempTimer:Clear()
    end

    if(bDestroyAll) then
        Owner._tbTimer = nil
        Owner._tbTimerFunc = nil
    else
        Owner._tbTimer = {}
    end
end

function Timer.IsOwnerTimerAlived(Owner, szTimerName)
    return Timer.GetOwnerTimer(Owner, szTimerName) ~= nil
end

function Timer.GetOwnerTimer(Owner, szTimerName)
    local tbTimer = Owner._tbTimer
    if(not tbTimer) then
        return nil
    end

    return tbTimer[szTimerName]
end

return Timer

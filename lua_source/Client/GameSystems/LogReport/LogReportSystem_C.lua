local luaclass = require("luaclass")
local LogReportSystem = require("LogReportSystem")
local LogReportSystem_C = luaclass("LogReportSystem_C", LogReportSystem)

local Timer = require("Timer")
local UIUtils = require("UIUtils")
local StringUtil = require("StringUtil")
local UIResourceDef = require("UIResourceDef")
local ClientEventDef = require("ClientEventDef")

local fnReportExceptionWithCategory = BuglyCrashReportBPLibrary.ReportExceptionWithCategory
local fnIsGarbageCollecting = ExtendBlueprintFunctions.IsGarbageCollecting

local REPORT_INTERVAL = 1
local BUGLY_CATEGORY = {
    [LogReportSystem.LOG_LEVEL_WARNING] = 4, -- bugly中C#分类的category
    [LogReportSystem.LOG_LEVEL_ERROR] = 5, -- -- bugly中JS分类的category
}
local LEVEL_TAG_STRING = {
    [LogReportSystem.LOG_LEVEL_WARNING] = "Warning",
    [LogReportSystem.LOG_LEVEL_ERROR] = "Error",
}

LogReportSystem_C.tbLogCaches = nil
LogReportSystem_C.tbReportTimer = nil
LogReportSystem_C.bTimerActive = false

local function SentLog(self, tbPacket)
    local nCategory = BUGLY_CATEGORY[tbPacket.level]
    if nCategory then
        local szCategory = LEVEL_TAG_STRING[tbPacket.level]
        local szName = tbPacket.message
        local szReason = string.format("[%s]: %s", szCategory, tbPacket.category)
        local szTraceback = string.format("message: %s \n %s", tbPacket.message, tbPacket.traceback)
        fnReportExceptionWithCategory(nCategory, szName, szReason, szTraceback)
    end
end

local function PauseReportTimer(self)
    if self.tbReportTimer then
        self.tbReportTimer:Pause()
        self.bTimerActive = false
    end
end

local function ResumeReportTimer(self)
    if self.tbReportTimer then
        self.bTimerActive = true
        self.tbReportTimer:Resume()
    end
end

local function ClearCache(self)
    PauseReportTimer(self)
    self.tbLogCaches = {}
end

local function OnDelayLogStreaming(self)
    SentLog(self, self.tbLogCaches[1])
    table.remove(self.tbLogCaches, 1)
    if #self.tbLogCaches == 0 then
        PauseReportTimer(self)
    end
end

local function ProcessCaches(self)
    if (not self.bTimerActive)
    and (#self.tbLogCaches > 0)
    and (not fnIsGarbageCollecting())
    and isvalidhandle(getWorld()) then
        ResumeReportTimer(self)
    end
end

local function OnBattleTimeOut(self, bTimeOut)
    if bTimeOut then
        self:SetEnabled(false)
    end
end

local function OnDisconnectedFromHubServer(self)
    self:SetEnabled(false)
end

function LogReportSystem_C:Init()
    if not LogReportSystem_C.super.Init(self) then
        return false
    end
    self.tbLogCaches = {}
    self:SetErrorFiltered(true)
    self:SetWarningFiltered(true)
    self:SetEnabled(true)
    self.EventHelper:RegisterEvent(ClientEventDef.EV_BATTLE_TIMEOUT, self, OnBattleTimeOut)
    self.EventHelper:RegisterEvent(ClientEventDef.EV_DISCONNECTED, self, OnDisconnectedFromHubServer)
    self.EventHelper:RegisterEvent(ClientEventDef.EV_LEAVE_PROCEDURE_LOBBY, self, PauseReportTimer)
    self.EventHelper:RegisterEvent(ClientEventDef.EV_LEAVE_PROCEDURE_BATTLE, self, PauseReportTimer)

    self.tbReportTimer = Timer.NewTimerMethod(self, OnDelayLogStreaming, REPORT_INTERVAL, true, "LogReport", true)
    self.tbReportTimer:SetIgnoreClear(true)
    PauseReportTimer(self)
    return true
end

function LogReportSystem_C:Uninit()
    self.tbReportTimer:Clear()
    self.tbReportTimer = nil
    self.tbLogCaches = nil
    LogReportSystem_C.super.Uninit(self)
end

function LogReportSystem_C:SetEnabled(bEnable)
    if bEnable then
        ProcessCaches(self)
    else
        ClearCache(self)
    end
    LogReportSystem_C.super.SetEnabled(self, bEnable)
end

function LogReportSystem_C:OnLogReport(nLevel, szMessage, szCategory, nCurrentTime, nFrameCount, szTraceback)
    local tbPacket = {
        timestamp = nCurrentTime,
        frame = nFrameCount,
        category = szCategory,
        level = nLevel,
        message = szMessage,
        traceback = szTraceback
    }
    table.insert(self.tbLogCaches, tbPacket)
    ProcessCaches(self)
end

function LogReportSystem_C:RecvServerLog(nCurrentTime, nFrameCount, szCategory, nLevel, szMessage, szTraceback)
    local szDisplayMessage = string.format("[%s] [%s] %s", LEVEL_TAG_STRING[nLevel], szCategory, szMessage)
    if not StringUtil.IsEmptyString(szTraceback) then
        szDisplayMessage = szDisplayMessage .. "\n" .. szTraceback
    end
    self:Log(szDisplayMessage)
    UIUtils.PrintScreen(szDisplayMessage, 10, UIResourceDef.COLOR.PURPLE.SLATE_COLOR)
end

return LogReportSystem_C()
local luaclass = require("luaclass")
local LogReportSystem = luaclass("LogReportSystem")

local SelfEventHelper = require("SelfEventHelper")
local LogReportWhiteList = dynamic_require("LogReportWhiteList")

local SYSTEM_TAG = "[LogReportSystem]"
local MAX_RECENT_RECORD = 10
local RECENT_CURSOR_START = 1

LogReportSystem.LOG_LEVEL_ERROR   = 2 -- 枚举定义参见 LogVerbosity.h
LogReportSystem.LOG_LEVEL_WARNING = 3

LogReportSystem.EventHelper = nil
LogReportSystem.pLogReport = nil
LogReportSystem.bEnabled = false
LogReportSystem.bErrorFiltered = false
LogReportSystem.bWarningFiltered = false
LogReportSystem.tbRecentSendList = nil
LogReportSystem.nRecentCursor = RECENT_CURSOR_START

local function IsValidLogLevel(self, nLevel)
    if self.bErrorFiltered and (nLevel == LogReportSystem.LOG_LEVEL_ERROR) then
        return true
    elseif self.bWarningFiltered and (nLevel == LogReportSystem.LOG_LEVEL_WARNING) then
        return true
    end
    return false
end

local function InWhiteList(szMessage)
    for _, v in ipairs(LogReportWhiteList) do
        if string.match(szMessage, v) then
            return true
        end
    end
    return false
end

local function CheckRencentSentList(self, nLevel, szMessage, szCategory)
    for _,v in ipairs(self.tbRecentSendList) do
        if (nLevel == v.nLevel) and (szMessage == v.szMessage) and (szCategory == v.szCategory) then
            return true
        end
    end

    local tbLogInfos = self.tbRecentSendList[self.nRecentCursor] or {}
    tbLogInfos.nLevel = nLevel
    tbLogInfos.szMessage = szMessage
    tbLogInfos.szCategory = szCategory
    self.tbRecentSendList[self.nRecentCursor] = tbLogInfos

    self.nRecentCursor = self.nRecentCursor + 1
    if self.nRecentCursor > MAX_RECENT_RECORD then
        self.nRecentCursor = RECENT_CURSOR_START
    end
    return false
end

local function HandleLogReport(self, nLevel, szMessage, szCategory, nCurrentTime, nFrameCount)
    if not self.bEnabled then
        return
    end
    if not IsValidLogLevel(self, nLevel) then
        return
    end
    if InWhiteList(szMessage) then
        return
    end
    -- 不重复连续发送相同日志，避免刷屏，也避免lua嵌套爆栈
    if CheckRencentSentList(self, nLevel, szMessage, szCategory) then
        return
    end

    local szTraceback = ""
    if (szCategory == "LogLua") or (szCategory == "LogGameLua") then
        -- LogLua -> U4Lua插件
        -- LogGameLua -> UE4SimpleLua插件
        szTraceback = debug.traceback()
        local i = 1
        local nPos = 0
        repeat
            i = i + 1
            nPos = string.find(szTraceback, "\n", nPos + 1)
        until (i > 4) or (not nPos)
        if nPos then
            szTraceback = "stack traceback:\n" .. string.sub(szTraceback, nPos + 1, -1)
        end
    end
    self:OnLogReport(nLevel, szMessage, szCategory, nCurrentTime, nFrameCount, szTraceback)
end

function LogReportSystem:Init()
    self.pLogReport = CommonShell.GetCommon(GWorld):GetLogReport()
    if not self.pLogReport then
        logerror("LogReportSystem:Init failed, pLogReport is nil")
        return false
    end

    self.tbRecentSendList = {}
    self.EventHelper = SelfEventHelper()
    self.EventHelper:RegisterCppDelegate(self.pLogReport.OnLogReport, self, HandleLogReport)
    return true
end

function LogReportSystem:Uninit()
    if self.EventHelper then
        self.EventHelper:UnregisterAll()
        self.EventHelper = nil
    end
end

function LogReportSystem:SetEnabled(bEnabled)
    if not self.pLogReport then
        logerror("LogReportSystem:SetEnabled failed, pLogReport is nil")
        return
    end
    self:Log("SetEnabled", bEnabled)
    self.bEnabled = bEnabled
    self.pLogReport:SetEnabled(bEnabled)
end

function LogReportSystem:SetErrorFiltered(bFiltered)
    self:Log("SetErrorFiltered", bFiltered)
    self.bErrorFiltered = bFiltered
end

function LogReportSystem:SetWarningFiltered(bFiltered)
    self:Log("SetWarningFiltered", bFiltered)
    self.bWarningFiltered = bFiltered
end

function LogReportSystem:OnLogReport(nLevel, szMessage, szCategory, nCurrentTime, nFrameCount)
    -- derived class implement it
end

function LogReportSystem:Log(...)
    log(SYSTEM_TAG, ...)
end

return LogReportSystem
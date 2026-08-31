local luaclass = require("luaclass")
local LogReportSystem = require("LogReportSystem")
local LogReportSystem_S = luaclass("LogReportSystem_S", LogReportSystem)

local Timer = require("Timer")
local Proto = require("DungeonCommonProtoNames")
local StringUtil = require("StringUtil")
local CommonEventDef = require("CommonEventDef")
local NetworkManager = dynamic_require("NetworkManager")

local CMD_ARG_NAME = "-logreport="
local CMD_ARG_KEY_ERROR = "error"
local CMD_ARG_KEY_WARNING = "warning"
local REPORT_INTERVAL = 1
local MAX_REP_LEN = 2000

LogReportSystem_S.bServerInstance = true
LogReportSystem_S.bCachingLog = true
LogReportSystem_S.tbLogCaches = nil

local function ClearTimer(self)
    if self.tbReportTimer then
        self.tbReportTimer:Clear()
        self.tbReportTimer = nil
    end
end

local function OnDelayMulticastLog(self)
    NetworkManager:GetRPCNetworkProxy():Multicast(Proto.d2c_MulticastServerLog, self.tbLogCaches[1], false)
    table.remove(self.tbLogCaches, 1)
    if #self.tbLogCaches == 0 then
        ClearTimer(self)
    end
end

local function OnPlayerLogin(self)
    self.EventHelper:UnregisterEvent(CommonEventDef.EV_GAME_MODE_ON_PLAYER_LOGIN)
    -- 听到第一个玩家登陆后再把日志广播下去
    self.bCachingLog = false
    if #self.tbLogCaches > 0 then
        self.tbReportTimer = Timer.NewTimerMethod(self, OnDelayMulticastLog, REPORT_INTERVAL, true)
    end
end

function LogReportSystem_S:Init()
    if GWithEditor then
        return
    end

    LogReportSystem_S.super.Init(self)
    self.tbLogCaches = {}
    self.EventHelper:RegisterEvent(CommonEventDef.EV_GAME_MODE_ON_PLAYER_LOGIN, self, OnPlayerLogin)

    local szCommandLine = KismetSystemLibrary.GetCommandLine()
    local tbCmdArgs = StringUtil.Split(szCommandLine, " ")
    local szArgValue = ""
    for _,v in ipairs(tbCmdArgs) do
        if StringUtil.StartsWith(v, CMD_ARG_NAME) then
            szArgValue = string.sub(v, #CMD_ARG_NAME + 1, -1)
            break
        end
    end
    self:Log("cmd arg: '" .. szArgValue .. "', length:", #szArgValue)
    self:SetErrorFiltered(string.find(szArgValue, CMD_ARG_KEY_ERROR) ~= nil)
    self:SetWarningFiltered(string.find(szArgValue, CMD_ARG_KEY_WARNING) ~= nil)
    self:SetEnabled(self.bErrorFiltered or self.bWarningFiltered)
end

function LogReportSystem_S:OnLogReport(nLevel, szMessage, szCategory, nCurrentTime, nFrameCount, szTraceback)
    -- 堆栈太长时需要截取，避免超长
    local nCurrentLen = string.len(szMessage) + string.len(szCategory) + string.len(szTraceback)
    local nLenDelta = nCurrentLen - MAX_REP_LEN
    if nLenDelta > 0 then
        szTraceback = string.sub(szTraceback, 1, -1 - nLenDelta)
    end

    -- TEMP CODE BEGIN
    -- 临时 DEBUG 需要
    if (szMessage == "Other object in slot") and (szCategory == "LogUObjectArray") then
        self:Log(debug.traceback())
    end
    -- TEMP CODE END

    local tbPacket = {
        timestamp = nCurrentTime,
        frame = nFrameCount,
        category = szCategory,
        level = nLevel,
        message = szMessage,
        traceback = szTraceback
    }

    if self.bCachingLog then
        table.insert(self.tbLogCaches, tbPacket)
    else
        NetworkManager:GetRPCNetworkProxy():Multicast(Proto.d2c_MulticastServerLog, tbPacket, false)
    end
end

return LogReportSystem_S()
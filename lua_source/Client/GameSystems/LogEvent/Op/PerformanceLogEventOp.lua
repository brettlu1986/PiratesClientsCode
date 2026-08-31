local luaclass                      = require("luaclass")
local LogEventOpBase                = dynamic_require("LogEventOpBase")
local PerformanceLogEventOp         = luaclass("PerformanceLogEventOp", LogEventOpBase)

local DataSDKHelper             = require("DataSDKHelper")
local Analytics                 = require("ClientAnalyticsProtoNames")
local ClientEventDef            = require("ClientEventDef")
local SelfTimerHelperClass      = require("SelfTimerHelper")
local PerformanceEventDef       = require("PerformanceEventDef")
--------------------------------------------------------------------
local DEFAULT_INTERVAL  = 1
local DEFAULT_VALUE     = 0
local EVENT_ID          = "performance_analytics"
local EVENT_DESC        = "性能分析日志"

PerformanceLogEventOp.TimerHelper       = nil
--------------------------------------------------------------------

--性能追踪
local function UploadFramesAndMemoryInfo(self)
    local tbPacket = {}
    local szEventInfoKey = PerformanceEventDef.FRAMES_MEMORY
    local tbExt = {}
    tbExt.eventTargetId = PerformanceEventDef.EVENT_ID[szEventInfoKey]
    tbExt.eventTargetName = PerformanceEventDef.EVENT_DESC[szEventInfoKey]
    tbExt.frame = tostring(GamePlatformMiscLibrary.GetAverageFPS())
    tbExt.currentMemory = tostring(GamePlatformMiscLibrary.GetMemoryUsed())
    tbPacket.data_info = DataSDKHelper.CreateCustomEventData(EVENT_ID, EVENT_DESC, DEFAULT_VALUE, tbExt)
    self:LogEvent(Analytics.OnCustomEvent, tbPacket)
end

local function OnEnterBattle(self)
    self.TimerHelper:NewTimerMethod(self, UploadFramesAndMemoryInfo, DEFAULT_INTERVAL, true)
end

local function OnLeaveBattle(self)
    self.TimerHelper:ClearAllTimer()
end

local function OnImageQualityChnage(self, nLevel)
    local tbPacket = {}
    local szEventInfoKey = PerformanceEventDef.IMAGE_QUALITY
    local tbExt = {}
    tbExt.eventTargetId = PerformanceEventDef.EVENT_ID[szEventInfoKey]
    tbExt.eventTargetName = PerformanceEventDef.EVENT_DESC[szEventInfoKey]
    tbExt.imageQuality = tostring(nLevel)
    tbPacket.data_info = DataSDKHelper.CreateCustomEventData(EVENT_ID, EVENT_DESC, DEFAULT_VALUE, tbExt)
    self:LogEvent(Analytics.OnCustomEvent, tbPacket)
end

local function UploadCheapsInfo(self)
    local tbPacket = {}
    local szEventInfoKey = PerformanceEventDef.CHEAPS
    local tbExt = {}
    tbExt.eventTargetId = PerformanceEventDef.EVENT_ID[szEventInfoKey]
    tbExt.eventTargetName = PerformanceEventDef.EVENT_DESC[szEventInfoKey]
    tbExt.cheapInfo = GamePlatformMiscLibrary.GetCPUChipset()
    tbExt.vulkanSupport = tostring(GamePlatformMiscLibrary.HasVulkanDriverSupport())
    tbPacket.data_info = DataSDKHelper.CreateCustomEventData(EVENT_ID, EVENT_DESC, DEFAULT_VALUE, tbExt)
    self:LogEvent(Analytics.OnCustomEvent, tbPacket)
end

function PerformanceLogEventOp:Init()
    PerformanceLogEventOp.super.Init(self)
    self.TimerHelper = SelfTimerHelperClass()
    self:RegisterEvent()
    UploadCheapsInfo(self)
end

function PerformanceLogEventOp:Uninit()
    PerformanceLogEventOp.super.Uninit(self)
    self.TimerHelper:ClearAllTimer()
    self.TimerHelper = nil
end

function PerformanceLogEventOp:RegisterEvent()
    local EventHelper = self.EventHelper
    EventHelper:RegisterEvent(ClientEventDef.EV_CLIENT_LOG_EVENT_IMAGE_QUALITY_CHANGE, self, OnImageQualityChnage)
    EventHelper:RegisterEvent(ClientEventDef.EV_ENTER_PROCEDURE_BATTLE, self, OnEnterBattle)
    EventHelper:RegisterEvent(ClientEventDef.EV_LEAVE_PROCEDURE_BATTLE, self, OnLeaveBattle)
    -- EventHelper:RegisterEvent(ClientEventDef.EV_LEAVE_PROCEDURE_BATTLE, self, UploadCheapsInfo)
end

return PerformanceLogEventOp
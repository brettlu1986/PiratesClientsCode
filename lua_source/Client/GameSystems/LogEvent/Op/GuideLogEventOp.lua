local luaclass                  = require("luaclass")
local LogEventOpBase            = dynamic_require("LogEventOpBase")
local GuideLogEventOp           = luaclass("GuideLogEventOp", LogEventOpBase)

local DataSDKHelper         = require("DataSDKHelper")
local Analytics             = require("ClientAnalyticsProtoNames")
local ClientEventDef        = require("ClientEventDef")

--前端转化
local function OnGuideEnd(self, szEventTargetId, szEventTargetName, szEventSpendTime)
    local tbPacket = {}
    local tbExt = {}
    tbExt.eventTargetId = szEventTargetId
    tbExt.eventTargetName = szEventTargetName
    tbExt.eventSpendTime = szEventSpendTime
    tbPacket.data_info = DataSDKHelper.CreateCustomEventData("new_guide", "新手引导", 0, tbExt)
    self:LogEvent(Analytics.OnCustomEvent, tbPacket)
end

function GuideLogEventOp:Init()
    GuideLogEventOp.super.Init(self)
    self:RegisterEvent()
end

function GuideLogEventOp:Uninit()
    GuideLogEventOp.super.Uninit(self)
end

function GuideLogEventOp:RegisterEvent()
    local EventHelper = self.EventHelper
    EventHelper:RegisterEvent(ClientEventDef.EV_CLIENT_LOG_EVENT_GUIDE_END, self, OnGuideEnd) 
end

return GuideLogEventOp
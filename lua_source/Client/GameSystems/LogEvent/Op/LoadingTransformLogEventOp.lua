local luaclass                      = require("luaclass")
local LogEventOpBase                = dynamic_require("LogEventOpBase")
local LoadingTransformLogEventOp    = luaclass("LoadingTransformLogEventOp", LogEventOpBase)

local DataSDKHelper             = require("DataSDKHelper")
local Analytics                 = require("ClientAnalyticsProtoNames")
local ClientEventDef            = require("ClientEventDef")
local TransformEventDef         = require("TransformEventDef")

local EVENT_ID      = "loading_transform"
local EVENT_DESC    = "前端加载转化"
local DEFAULT_VALUE = 0

--前端转化
local function OnLoadingTransform(self, szEventTargetId)
    local tbPacket = {}
    local nTargetTime = math.floor(KismetSystemLibrary.GetGameTimeInSeconds(GWorld))
    local tbExt = {}
    if szEventTargetId == TransformEventDef.TARGET_EVENT_NAME.APP_START then
        nTargetTime = 0
    end
    local tbEventDef = TransformEventDef[szEventTargetId]
    tbExt.eventTargetId = tbEventDef.szId
    tbExt.eventTargetName = tbEventDef.szDes
    tbExt.eventTargetTime = tostring(nTargetTime)
    tbPacket.data_info = DataSDKHelper.CreateCustomEventData(EVENT_ID, EVENT_DESC, DEFAULT_VALUE, tbExt)
    self:LogEvent(Analytics.OnCustomEvent, tbPacket)
end

function LoadingTransformLogEventOp:Init()
    LoadingTransformLogEventOp.super.Init(self)
    self:RegisterEvent()
end

function LoadingTransformLogEventOp:Uninit()
    LoadingTransformLogEventOp.super.Uninit(self)
end

function LoadingTransformLogEventOp:RegisterEvent()
    local EventHelper = self.EventHelper
    EventHelper:RegisterEvent(ClientEventDef.EV_CLIENT_LOG_EVENT_LOADING_TRANSFORM, self, OnLoadingTransform) 
end

return LoadingTransformLogEventOp
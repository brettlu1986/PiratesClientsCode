-----------------------------------------------------
--File Name    : GuideTriggerToolTipShow.lua
--Description  : 指引触发
-----------------------------------------------------
local luaclass = require("luaclass")
local GuideTrigger = require("GuideTrigger")
local GuideTriggerToolTipShow = luaclass("GuideTriggerToolTipShow",GuideTrigger)

local ClientEventDef = require("ClientEventDef")
local UIManager = require("UIManager")
local UIDef = require("UIDef")

--override
function GuideTriggerToolTipShow:Begin()
    GuideTriggerToolTipShow.super.Begin(self)
    local Wnd = UIManager:GetWnd(UIDef.UI_TOOL_TIP)
    if(Wnd ~= nil and UIManager:IsWndOpen(UIDef.UI_TOOL_TIP))then
        self:Trigger()
    end
end
function GuideTriggerToolTipShow:BindEvent(EventHelper)
    EventHelper:RegisterEvent(ClientEventDef.EV_GUIDE_TOOL_TIP_SHOW, self, self.OnToolTipShow)
end

function GuideTriggerToolTipShow:OnToolTipShow(bShow)
    self:DebugLog("bShow="..tostring(bShow).." self.tbTemplate.bIsEnable="..tostring(self.tbTemplate.bIsEnable))
    if(self.tbTemplate.bIsEnable == bShow)then
        self:Trigger()
    end 
end

return GuideTriggerToolTipShow

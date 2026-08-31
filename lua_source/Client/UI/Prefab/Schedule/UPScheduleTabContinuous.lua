local luaclass = require("luaclass")
local UPScheduleTabBase = require("UPScheduleTabBase")
local UPScheduleTabContinuous = luaclass("UPScheduleTabContinuous", UPScheduleTabBase)
local UIManager = require("UIManager")
local UIDef = require("UIDef")

local function OnClickedGo(self)
    UIManager:OpenWnd(UIDef.UI_SCHEDULE_CONTINUOUS, {szFrom = UIDef.UI_SCHEDULE, nId = self.nId})
    UIManager:CloseWnd(UIDef.UI_SCHEDULE)
end

function UPScheduleTabContinuous:Activate()
    UPScheduleTabContinuous.super.Activate(self)
end

function UPScheduleTabContinuous:Deactivate()
    UPScheduleTabContinuous.super.Deactivate(self)
end

function UPScheduleTabContinuous:OnLoad()
end

function UPScheduleTabContinuous:OnBindEvent(EventHelper)
    EventHelper:RegisterCppDelegate(self.pWidgetRef.btnGo.OnClicked,  self, OnClickedGo)
end

return UPScheduleTabContinuous
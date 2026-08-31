local luaclass = require("luaclass")
local UPScheduleTabBase = require("UPScheduleTabBase")
local UPScheduleTabNoobLogin = luaclass("UPScheduleTabNoobLogin", UPScheduleTabBase)
local UIManager = require("UIManager")
local UIDef = require("UIDef")

local function OnClickedGo(self)
    UIManager:OpenWnd(UIDef.UI_SCHEDULE_NOOB_LOGIN, {szFrom = UIDef.UI_SCHEDULE, nId = self.nId})
    UIManager:CloseWnd(UIDef.UI_SCHEDULE)
end

function UPScheduleTabNoobLogin:Activate()
    UPScheduleTabNoobLogin.super.Activate(self)
end

function UPScheduleTabNoobLogin:Deactivate()
    UPScheduleTabNoobLogin.super.Deactivate(self)
end

function UPScheduleTabNoobLogin:OnLoad()
end

function UPScheduleTabNoobLogin:OnBindEvent(EventHelper)
    EventHelper:RegisterCppDelegate(self.pWidgetRef.btnGo.OnClicked,  self, OnClickedGo)
end

return UPScheduleTabNoobLogin
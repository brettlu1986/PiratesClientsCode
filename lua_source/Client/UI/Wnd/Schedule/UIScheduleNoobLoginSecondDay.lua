local luaclass = require ("luaclass")
local WndBase = require("WndBase")
local UIScheduleNoobLoginSecondDay = luaclass("UIScheduleNoobLoginSecondDay", WndBase)

local function OnClickClose(self)
    self:CloseSelf()
end

function UIScheduleNoobLoginSecondDay:OnLoad()
end

function UIScheduleNoobLoginSecondDay:OnUnload()
end

function UIScheduleNoobLoginSecondDay:OnBindEvent(EventHelper)
    local pWidgetRef = self.pWidgetRef
    EventHelper:RegisterCppDelegate(pWidgetRef.btnClose.OnClicked, self, OnClickClose)
end

function UIScheduleNoobLoginSecondDay:OnShow()
end

return UIScheduleNoobLoginSecondDay

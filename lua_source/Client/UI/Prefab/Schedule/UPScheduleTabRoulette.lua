local luaclass = require("luaclass")
local UPScheduleTabBase = require("UPScheduleTabBase")
local UPScheduleTabRoulette = luaclass("UPScheduleTabRoulette", UPScheduleTabBase)
local UIDef = require("UIDef")
local ScheduleSystem = require("ScheduleSystem")
local ScheduleTypeDef = require("ScheduleTypeDef")
local UIUtils = require("UIUtils")
local UITextDef = require("UITextDef")
local UIManager = require("UIManager")

UPScheduleTabRoulette.tbInstance = nil

local function RefreshUI(self)
    self.pWidgetRef.txtRouletteTime:SetText(self.tbInstance:GetTimeStr())
end

local function OnClickedGo(self)
    if self.tbInstance == nil then
        UIUtils.ShowToast(UITextDef.LOBBY_NET_WORK_WEAKNESS)
        return
    end
    local tbData = self.tbInstance:GetData() 
    if tbData == nil then
        UIUtils.ShowToast(UITextDef.LOBBY_NET_WORK_WEAKNESS)
        return
    end

    UIManager:OpenWnd(UIDef.UI_SCHEDULE_ROULETTE, {szFrom = UIDef.UI_SCHEDULE, nId = self.nId})
    UIManager:CloseWnd(UIDef.UI_SCHEDULE)
end


function UPScheduleTabRoulette:Activate()
    UPScheduleTabRoulette.super.Activate(self)
    RefreshUI(self)
end

function UPScheduleTabRoulette:Deactivate()
    UPScheduleTabRoulette.super.Deactivate(self)
end

function UPScheduleTabRoulette:OnLoad()
    self.tbInstance = ScheduleSystem:GetInstance(ScheduleTypeDef.ROULETTE)
end

function UPScheduleTabRoulette:OnBindEvent(EventHelper)
    EventHelper:RegisterCppDelegate(self.pWidgetRef.btnRouletteGo.OnClicked,  self, OnClickedGo)
end

return UPScheduleTabRoulette
local luaclass = require("luaclass")
local UILogicBase = require("UILogicBase")
local ULScheduleRoulette = luaclass("ULScheduleRoulette", UILogicBase)
local UIDef = require("UIDef")
local ScheduleSystem = require("ScheduleSystem")
local ScheduleTypeDef = require("ScheduleTypeDef")
local UIUtils = require("UIUtils")
local UITextDef = require("UITextDef")
local UIManager = require("UIManager")

local SHOW_WIDGETS = {
    ["vbRoulette"] = true,
}

ULScheduleRoulette.tbInstance = nil

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

function ULScheduleRoulette:Activate(tbAllWidget)
    local pWidgetRef = self.pWidgetRef

    for i, v in ipairs(tbAllWidget) do
        pWidgetRef[v]:SetVisibility(SHOW_WIDGETS[v] and ESlateVisibility_SelfHitTestInvisible or ESlateVisibility_Collapsed)
    end

    RefreshUI(self)
end

function ULScheduleRoulette:Deactivate()
end

function ULScheduleRoulette:OnLoad()
    self.tbInstance = ScheduleSystem:GetInstance(ScheduleTypeDef.ROULETTE)
end

function ULScheduleRoulette:OnBindEvent(EventHelper)
    EventHelper:RegisterCppDelegate(self.pWidgetRef.btnRouletteGo.OnClicked,  self, OnClickedGo)
end

function ULScheduleRoulette:OnDestroy()
end

return ULScheduleRoulette
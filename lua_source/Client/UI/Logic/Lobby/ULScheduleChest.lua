local luaclass = require("luaclass")
local UILogicBase = require("UILogicBase")
local ULScheduleChest = luaclass("ULScheduleChest", UILogicBase)
local UIDef = require("UIDef")
local ScheduleSystem = require("ScheduleSystem")
local ScheduleTypeDef = require("ScheduleTypeDef")
-- local UIUtils = require("UIUtils")
-- local UITextDef = require("UITextDef")
-- local UIManager = require("UIManager")
-- local UISetUtils = require("UISetUtils")
-- local UIResourceDef = require("UIResourceDef")
local ClientEventDef = require("ClientEventDef")
local LobbySystem = require("LobbySystem")
local LobbySubTypeDef = require("LobbySubTypeDef")

local SHOW_WIDGETS = {
    ["vbChest"] = true,
}
-- local TASK_STATUS_STR = {
--     UISetUtils.GetL10NTextByKey("TASK_STAUTS_UNCOMPLETE"),
--     UISetUtils.GetL10NTextByKey("TASK_STATUS_COMPLETE"),    
--     UISetUtils.GetL10NTextByKey("TASK_STATUS_COMPLETE")    
-- }

-- local TASK_STATUS_COLOR = {
--     UIResourceDef.COLOR.GREY.SLATE_COLOR,
--     UIResourceDef.COLOR.WHITE.SLATE_COLOR,
--     UIResourceDef.COLOR.WHITE.SLATE_COLOR    
-- }

local CHEST_COUNT = 6

ULScheduleChest.tbInstance = nil
ULScheduleChest.tbChest = nil

local function RefreshTask(self)
    local tbTaskProgresses = self.tbInstance:GetTaskProgress()
    local tbTaskProgress = tbTaskProgresses[1]
    local pWidgetRef = self.pWidgetRef

    pWidgetRef["txtTaskDesc"]:SetText(tbTaskProgress.l10nDesc or "")
    -- pWidgetRef["txtTaskProgress"]:SetText(string.format("%d/%d", tbTaskProgress.nCurProgress, tbTaskProgress.nMaxProgress))
    -- pWidgetRef["txtTaskStatus"]:SetColorAndOpacity(TASK_STATUS_COLOR[tbTaskProgress.nStatus])
    -- pWidgetRef["txtTaskStatus"]:SetText(TASK_STATUS_STR[tbTaskProgress.nStatus])
    pWidgetRef["txtTaskProgress"]:SetText("+1")
    pWidgetRef["txtTaskStatus"]:SetText(string.format("%d/%d", tbTaskProgress.nFinishTimes, tbTaskProgress.nMaxProgress))
end

local function RefreshKey(self)
    self.pWidgetRef.txtKeyCount:SetText(self.tbInstance:GetKeyCount())
end

local function RefreshUI(self)
    self.pWidgetRef.txtSevenTime_2:SetText(self.tbInstance:GetTimeStr())
    RefreshTask(self)
    RefreshKey(self)
end

local function OnRefreshTask(self, nId)
    if nId ~= self.tbInstance.tbTemplate.nId then
        return
    end
    RefreshTask(self)
end

local function OnRefreshKeyCount(self, szType, bAdd)
    if szType == ScheduleTypeDef.CHEST then
        RefreshKey(self)
    end
end

local function OnRefreshChest(self, _, _, bResult)
    if bResult then
        self.EventHelper:FireEvent(ClientEventDef.EV_ON_PAUSE_POP)
        if self.Owner.tbOpenArgs.szForm == UIDef.UI_SCHEDULE_CHEST_POP then
            LobbySystem:Activate(LobbySubTypeDef.SCHEDULE, self.Owner.tbOpenArgs)
        else
            LobbySystem:Activate(LobbySubTypeDef.SCHEDULE, {nId = self.nId})
        end    
    end
end

local function OnClickedTask(self)
    local brChest = self.pWidgetRef.brChest
    -- logerror("////", brChest:IsVisible())
    if brChest:IsVisible() then
        brChest:SetVisibility(ESlateVisibility_Collapsed)
    else
        brChest:SetVisibility(ESlateVisibility_Visible)
    end
end

local function OnMouseButtonDown(self)
    self.pWidgetRef.brChest:SetVisibility(ESlateVisibility_Collapsed)
    return WidgetBlueprintLibrary.Handled()
end

function ULScheduleChest:Activate(tbAllWidget)
    self.EventHelper:FireEvent(ClientEventDef.EV_ON_RESUME_POP)

    local pWidgetRef = self.pWidgetRef

    for i, v in ipairs(tbAllWidget) do
        pWidgetRef[v]:SetVisibility(SHOW_WIDGETS[v] and ESlateVisibility_SelfHitTestInvisible or ESlateVisibility_Collapsed)
    end

    pWidgetRef.imgBg1:SetVisibility(ESlateVisibility_Visible)
    pWidgetRef.imgBg2:SetVisibility(ESlateVisibility_Visible)
    pWidgetRef.brChest:SetVisibility(ESlateVisibility_Collapsed)
    RefreshUI(self)
end

function ULScheduleChest:Deactivate()
    local pWidgetRef = self.pWidgetRef
    pWidgetRef.imgBg1:SetVisibility(ESlateVisibility_HitTestInvisible)
    pWidgetRef.imgBg2:SetVisibility(ESlateVisibility_HitTestInvisible)
end

function ULScheduleChest:OnLoad()
    self.tbInstance = ScheduleSystem:GetInstance(ScheduleTypeDef.CHEST)

    local PrefabHelper = self.PrefabHelper
    local pWidgetRef = self.pWidgetRef

    self.tbChest = {}
    for i = 1, CHEST_COUNT do
        local pbChest = PrefabHelper:BindPrefab(pWidgetRef["upChest"..i])
        pbChest:SetInfo(self.tbInstance, i)
        table.insert(self.tbChest, pbChest)
    end
end

function ULScheduleChest:OnBindEvent(EventHelper)
    local pWidgetRef = self.pWidgetRef
    EventHelper:RegisterCppDelegate(pWidgetRef.btnChestTask.OnClicked,  self, OnClickedTask)
    EventHelper:RegisterCppDelegate(pWidgetRef.imgBg1.OnMouseButtonDownEvent, self, OnMouseButtonDown)
    EventHelper:RegisterCppDelegate(pWidgetRef.imgBg2.OnMouseButtonDownEvent, self, OnMouseButtonDown)
    EventHelper:RegisterEvent(ClientEventDef.EV_SCHEDULE_TASK_REFRESH, self, OnRefreshTask)
    EventHelper:RegisterEvent(ClientEventDef.EV_SCHEDULE_ITEM_UPDATE, self, OnRefreshKeyCount)
    EventHelper:RegisterEvent(ClientEventDef.EV_SCHEDULE_CHEST_REFRESH, self, OnRefreshChest)
end

function ULScheduleChest:OnDestroy()
end

return ULScheduleChest
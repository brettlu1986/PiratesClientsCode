local luaclass = require("luaclass")
local UPScheduleTabBase = require("UPScheduleTabBase")
local UPScheduleTabChest = luaclass("UPScheduleTabChest", UPScheduleTabBase)
local ScheduleSystem = require("ScheduleSystem")
local ScheduleTypeDef = require("ScheduleTypeDef")
local ClientEventDef = require("ClientEventDef")
local LobbySystem = require("LobbySystem")
local LobbySubTypeDef = require("LobbySubTypeDef")

local CHEST_COUNT = 6


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

local function OnRefreshChest(self, _, _, bResult)
    if bResult then
        self.EventHelper:FireEvent(ClientEventDef.EV_ON_PAUSE_POP)
        LobbySystem:Activate(LobbySubTypeDef.SCHEDULE, self.Owner.tbOpenArgs)    
    end
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

local function OnClickedTask(self)
    local brChest = self.pWidgetRef.brChest
    -- logerror("////", brChest:IsVisible())
    if brChest:IsVisible() then
        brChest:SetVisibility(ESlateVisibility_Collapsed)
    else
        brChest:SetVisibility(ESlateVisibility_Visible)
    end
end

function UPScheduleTabChest:Activate()
    UPScheduleTabChest.super.Activate(self)
    RefreshUI(self)
end

function UPScheduleTabChest:Deactivate()
    UPScheduleTabChest.super.Deactivate(self)
end

function UPScheduleTabChest:OnLoad()
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

function UPScheduleTabChest:OnBindEvent(EventHelper)
    EventHelper:RegisterCppDelegate(self.pWidgetRef.btnChestTask.OnClicked,  self, OnClickedTask)
    EventHelper:RegisterEvent(ClientEventDef.EV_SCHEDULE_TASK_REFRESH, self, OnRefreshTask)
    EventHelper:RegisterEvent(ClientEventDef.EV_SCHEDULE_ITEM_UPDATE, self, OnRefreshKeyCount)
    EventHelper:RegisterEvent(ClientEventDef.EV_SCHEDULE_CHEST_REFRESH, self, OnRefreshChest)
end

return UPScheduleTabChest
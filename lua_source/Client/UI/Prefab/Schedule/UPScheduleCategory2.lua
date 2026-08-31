-----------------------------------------------------
--File Name    : UPScheduleCategory2.lua
--Author       : li pengyang
--Create Time  : 2019-05-20
--Description  : 活动目录
-----------------------------------------------------

local luaclass = require ("luaclass")
local ListItemBase = require("ListItemBase")
local UPScheduleCategory2 = luaclass("UPScheduleCategory2", ListItemBase)
local ClientEventDef = require("ClientEventDef")
local UISetUtils = require("UISetUtils")
local ScheduleUITable = require("ScheduleUITable")
local ScheduleHelper = require("ScheduleHelper")
local ScheduleSystem = require("ScheduleSystem")
local UIResourceDef = require("UIResourceDef")

UPScheduleCategory2.tbData = nil

local COLOR = UIResourceDef.COLOR
local TYPE_COLOR = {
    [0] = COLOR.BLUE,
    [1] = COLOR.GREEN,
    [2] = COLOR.RED,
    [3] = COLOR.PURPLE,
    [4] = COLOR.BLUE,
    [5] = COLOR.YELLOW
}
local SCHEDULE_BATTLE_STAR = 4

local function OnClickSelect(self)
    if self.tbData.nId == SCHEDULE_BATTLE_STAR then
        local tbTemp = ScheduleUITable:GetTemplate(self.tbData.nId)
        local Component = ScheduleSystem:GetComponent()
        local bTip = ScheduleHelper[tbTemp.szIsTip](self, Component, true)
        self.pWidgetRef.btnSelect:HideTipIcon(not bTip)

        self.Owner:RefreshTip()
    end
    
    local nIndex = self.tbData.nIndex
    local nId = self.tbData.nId
    if nIndex ~= nil and nId ~= nil then
        self.Owner:OnSelect(nId, nIndex)
    end
end

local function OnRefreshSelect(self)
    local nIndex = self.ListHelper.nSelectedIdx
    local pWidgetRef = self.pWidgetRef
    local SelfHitTestInvisible, Hidden = ESlateVisibility_SelfHitTestInvisible, ESlateVisibility_Hidden
    pWidgetRef.imgSelect:SetVisibility(self.nIndex == nIndex and SelfHitTestInvisible or Hidden)
    pWidgetRef.imgSelect2:SetVisibility(self.nIndex == nIndex and SelfHitTestInvisible or Hidden)
end

-- local function OnHideTip(self, nId)
--     if nId == self.tbData.nId then
--         self.pWidgetRef.btnSelect:HideTipIcon(true)
--     end
-- end

local function OnRefreshTip(self)
    if self.tbData then
        local tbTemp = ScheduleUITable:GetTemplate(self.tbData.nId)
        local btnSelect = self.pWidgetRef.btnSelect
        if tbTemp == nil then
            btnSelect:HideTipIcon(true)
            return
        end
        local bTip = ScheduleSystem:HasTipsById(self.tbData.nId)
        btnSelect:HideTipIcon(not bTip)
    end
end

function UPScheduleCategory2:OnRefresh(tbData)
    self.tbData = tbData
    local pWidgetRef = self.pWidgetRef
    pWidgetRef.kmtxtName:SetText(tbData.kmtxtName)
    OnRefreshTip(self)
    if TYPE_COLOR[tbData.nType] ~= nil then
        pWidgetRef.txtTitle:SetText(UISetUtils.GetL10NTextByKey("UI_SCHEDULE_TYPE_"..tbData.nType))
        UISetUtils.SetBorderBrushColor(pWidgetRef.bdrTitle, TYPE_COLOR[tbData.nType])
    else
        logerror("schedule type is invalid ", tbData.nId, tbData.nType)
    end
    OnRefreshSelect(self)
end

function UPScheduleCategory2:OnBindEvent(EventHelper)
    EventHelper:RegisterCppDelegate(self.pWidgetRef.btnSelect.OnClicked, self, OnClickSelect)
    -- EventHelper:RegisterEvent(ClientEventDef.EV_SCHEDULE_BATTLE_STAR_TIP_HIDE, self, OnHideTip)
    EventHelper:RegisterEvent(ClientEventDef.EV_SCHEDULE_NOOB_LOGIN_REFRESH, self, OnRefreshTip)
    EventHelper:RegisterEvent(ClientEventDef.EV_ACTIVIEY_SEVENDAY_GETREWARD, self, OnRefreshTip)
    EventHelper:RegisterEvent(ClientEventDef.EV_SCHEDULE_FIXED_TIME_AWARD_REFRESH, self, OnRefreshTip)
    EventHelper:RegisterEvent(ClientEventDef.EV_SCHEDULE_CONTINUOUS_REFRESH, self, OnRefreshTip)
    EventHelper:RegisterEvent(ClientEventDef.EV_SCHEDULE_ITEM_UPDATE, self, OnRefreshTip)
    EventHelper:RegisterEvent(ClientEventDef.EV_SCHEDULE_CHEST_REFRESH, self, OnRefreshTip)
    EventHelper:RegisterEvent(ClientEventDef.EV_QUESTION_REFRESH, self, OnRefreshTip)
    EventHelper:RegisterEvent(ClientEventDef.EV_SEA_ADVENTURE_REFRESH, self, OnRefreshTip)
    
end

return UPScheduleCategory2

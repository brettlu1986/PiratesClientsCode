local luaclass = require("luaclass")
local WndBase = require("WndBase")
local UISchedule2 = luaclass("UISchedule2", WndBase)

local SelfVerticalListHelper = require("SelfVerticalListHelper")
local UITextDef = require("UITextDef")
local ScheduleUITable = require("ScheduleUITable")
local ScheduleSystem = require("ScheduleSystem")
local UIUtils = require("UIUtils")
local UISetUtils = require("UISetUtils")
local ClientEventDef = require("ClientEventDef")
local SelfTabBarHelper = require("SelfTabBarHelper")
local LobbySystem = require("LobbySystem")
local LobbySubTypeDef = require("LobbySubTypeDef")

local Collapsed, SelfHitTestInvisible = ESlateVisibility_Collapsed, ESlateVisibility_SelfHitTestInvisible

local ULANNOUNCEMENT = "ULScheduleAnnouncement"

local DEFAULT_SELECT = 1
local ANNOUNCEMENT_ID = 0
local BG_IMAGE_COUNT = 2

local UP_OFFSET = Margin{Left = 0, Top = 0, Right = 0, Bottom = 0}
local UP_ANCHOR = Anchors{Minimum=Vector2D{X = 0, Y = 0}, Maximum=Vector2D{X = 1, Y = 1}}


local TABS = {
    {
        fnGetDatas = function(self, Component, tbDatas)
            for i, v in ipairs(self.tbActivateSchedules) do
                local tbTemp = v.tbTemplate
                local tbData = {}
                tbData.kmtxtName = tbTemp.l10nName
                tbData.nType = tbTemp.nType
                tbData.nId = tbTemp.nId
                tbData.nIndex = i
                table.insert(tbDatas, tbData)                 
            end
        end,
    },
    {
        fnGetDatas = function(self, Component, tbDatas)
            local tbData = {}
            tbData.nId = 0
            tbData.kmtxtName = UITextDef.ANNOUNCEMENT_LABEL
            tbData.nType = 0
            tbData.nIndex = 1
            table.insert(tbDatas, tbData)
        end,
    },
}

UISchedule2.ListHelper = nil
UISchedule2.tbActivateSchedules = nil
UISchedule2.nCurIndex = nil
UISchedule2.tbTabBarHelper = nil
UISchedule2.ulAnnouncement = nil

local function SetCurSchedule(self, nId, nIndex)
    self.ListHelper:SetSelectedIndex(nIndex)

    local tbCurSchedule = self.tbActivateSchedules[self.nCurIndex]
    if tbCurSchedule ~= nil then
        logerror("///Deactivate", tbCurSchedule.nId)
        tbCurSchedule:Deactivate()
    else
        logerror("///announcement Deactivate")
        self.ulAnnouncement:Deactivate()
    end
    self.nCurIndex = nIndex

    local pWidgetRef = self.pWidgetRef
    if nId ~= ANNOUNCEMENT_ID then
        local tbTemp = ScheduleUITable:GetTemplate(nId)
        for i = 1, BG_IMAGE_COUNT do
            local szImg = tbTemp["szImgPath"..i]
            if szImg ~= nil then
                pWidgetRef["imgBg"..i]:SetVisibility(SelfHitTestInvisible)
                UISetUtils.SetImageBrushRes(pWidgetRef["imgBg"..i], szImg:load())
            else
                pWidgetRef["imgBg"..i]:SetVisibility(Collapsed)
            end 
        end
    
        tbCurSchedule = self.tbActivateSchedules[self.nCurIndex]
        if tbCurSchedule ~= nil then
            logerror("///Activate", tbCurSchedule.nId)
            tbCurSchedule:Activate()
        end
    else
        self.ulAnnouncement:Activate()
        logerror("///announcement Activate")
    end
    
end

local function SetTab(self, nIndex, nDefaultSelectId)
    self.nCurTab = nIndex

    local Component = ScheduleSystem:GetComponent()
    local tbDatas = {}
    TABS[nIndex].fnGetDatas(self, Component, tbDatas)
    self.ListHelper:SetData(tbDatas)

    if #tbDatas > 0 then
        local nSelIndex = DEFAULT_SELECT
        if nDefaultSelectId ~= nil then
            for i, v in ipairs(tbDatas) do
                if v.nId == nDefaultSelectId then
                    nSelIndex = i
                    break
                end
            end
        end
        SetCurSchedule(self, tbDatas[nSelIndex].nId, nSelIndex)
    end
end

local function OnRefreshTip(self)
    local bTip = ScheduleSystem:HasTips()
    local tbTabBarHelper = self.tbTabBarHelper
    tbTabBarHelper:SetTipIconVisible(1, bTip)
end

local function OnClickedClose(self)
    self:CloseSelf()
    UIUtils.BottomMenuSelect(1, true)
end

local function OnTabSelected(self, nSelectIndex)
    SetTab(self, nSelectIndex)
end

function UISchedule2:OnLoad()
    local pWidgetRef = self.pWidgetRef
    self.ListHelper = SelfVerticalListHelper()
    self.ListHelper:Init(self, pWidgetRef.kmlistActivities, {})
    
    local PrefabHelper = self.PrefabHelper 
    PrefabHelper:BindPrefab(self.pWidgetRef.pbCutoutScreenAdapter)

    self.tbActivateSchedules = {}

    local UILogicHelper = self.UILogicHelper
    self.ulAnnouncement = UILogicHelper:CreateUILogic(ULANNOUNCEMENT)
    self.ulAnnouncement.nId = ANNOUNCEMENT_ID
    self.ulAnnouncement:Deactivate()

    local tbContainer = ScheduleUITable:GetContainer()
    for i, v in pairs(tbContainer) do
        if ScheduleSystem:IsOpen(v.nId) and v.szUPName then
            local tbPrefab = PrefabHelper:CreatePrefab(v.szUPName)
            tbPrefab:SetTemplate(v)
            tbPrefab:Deactivate()
            pWidgetRef.cp:AddChild(tbPrefab.pWidgetRef)
            local ObjWidgetSlot = tbPrefab.pWidgetRef.Slot
            ObjWidgetSlot:SetAlignment(Vector2D{X = 0.5, Y = 0.5})
            ObjWidgetSlot:SetAnchors(UP_ANCHOR)
            ObjWidgetSlot:SetOffsets(UP_OFFSET)
            -- ObjWidgetSlot:SetZOrder(UP_ZORDER)

            table.insert(self.tbActivateSchedules, tbPrefab)
        end
    end

    local fnSort = function(a, b)
        if a.tbTemplate.nOrder < b.tbTemplate.nOrder then
            return true
        elseif a.tbTemplate.nOrder > b.tbTemplate.nOrder then
            return false
        else
            return a.nId < b.nId
        end
    end
    table.sort(self.tbActivateSchedules, fnSort)

    self.tbTabBarHelper = SelfTabBarHelper()
    self.tbTabBarHelper:Init(self, self.pWidgetRef.hbTab, 1)
    self.tbTabBarHelper.OnSelectedChangedDelegate:Bind(OnTabSelected, self)
end

function UISchedule2:OnShow()
    local nId = self.tbOpenArgs.nId
    logerror("ddd", nId)
    UIUtils.BottomMenuUnselectAll()
    OnRefreshTip(self)
    self.tbTabBarHelper:SelectByIndex(DEFAULT_SELECT, true)
    SetTab(self, DEFAULT_SELECT, nId)
end

function UISchedule2:OnBindEvent(EventHelper)
    local pWidgetRef = self.pWidgetRef

    EventHelper:RegisterCppDelegate(pWidgetRef.btnClose.OnClicked, self, OnClickedClose)

    EventHelper:RegisterEvent(ClientEventDef.EV_SCHEDULE_NOOB_LOGIN_REFRESH, self, OnRefreshTip)
    EventHelper:RegisterEvent(ClientEventDef.EV_ACTIVIEY_SEVENDAY_GETREWARD, self, OnRefreshTip)
    EventHelper:RegisterEvent(ClientEventDef.EV_SCHEDULE_FIXED_TIME_AWARD_REFRESH, self, OnRefreshTip)
    EventHelper:RegisterEvent(ClientEventDef.EV_SCHEDULE_CONTINUOUS_REFRESH, self, OnRefreshTip)
    EventHelper:RegisterEvent(ClientEventDef.EV_SCHEDULE_ITEM_UPDATE, self, OnRefreshTip)
    EventHelper:RegisterEvent(ClientEventDef.EV_SCHEDULE_CHEST_REFRESH, self, OnRefreshTip)
    EventHelper:RegisterEvent(ClientEventDef.EV_SEA_ADVENTURE_REFRESH, self, OnRefreshTip)
    EventHelper:RegisterEvent(ClientEventDef.EV_QUESTION_REFRESH, self, OnRefreshTip)
    EventHelper:RegisterEvent(ClientEventDef.EV_SCHEDULE_ROULETTE_REFRESH, self, OnRefreshTip)
end

function UISchedule2:OnUnload()
    if self.tbTabBarHelper then
        self.tbTabBarHelper:Uninit()
        self.tbTabBarHelper = nil
    end
    self.ListHelper:Uninit()
    self.ListHelper = nil
end

function UISchedule2:OnSelect(nId, nIndex)
    SetCurSchedule(self, nId, nIndex)
end

function UISchedule2:OnDestroy()
end

function UISchedule2:RefreshTip()
    OnRefreshTip(self)
end

function UISchedule2:OnPause()
    local nSubSystem = LobbySystem:GetActiveSub()
    log("UISchedule2:OnPause:nSubSystem.nSubType=",nSubSystem.nSubType)
    if nSubSystem and (nSubSystem.nSubType == LobbySubTypeDef.AWARD) then
        self.pWidgetRef:SetVisibility(ESlateVisibility_Collapsed)
    end
end

function UISchedule2:OnResume()
    log("UISchedule2:OnResume")
    if not self.pWidgetRef:IsVisible() then
        self.pWidgetRef:SetVisibility(ESlateVisibility_SelfHitTestInvisible)
        UIUtils.BottomMenuUnselectAll()
    end
end

return UISchedule2

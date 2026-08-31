local luaclass = require ("luaclass")
local WndBase = require("WndBase")
local UIScheduleNoobLoginNextDay = luaclass("UIScheduleNoobLoginNextDay", WndBase)
local ScheduleSystem = require("ScheduleSystem")
local NoobLoginDataTable = require("NoobLoginDataTable")
local AwardDataTable = require("AwardDataTable")
local ItemDataTable = require("ItemDataTable")
local UISetUtils = require("UISetUtils")
local AwardGiftBoxDataTable = require("AwardGiftBoxDataTable")
local ItemSystem = require("ItemSystem")
local UIDef = require("UIDef")

local MAX_COUNT = 4
-- UIScheduleNoobLoginNextDay.pbItem = nil
UIScheduleNoobLoginNextDay.tbItems = nil

local function RefreshUI(self, nDay)
    local Component = ScheduleSystem:GetComponent()
    local tbData = Component:GetNoobLogin()
    local nMaxCount = NoobLoginDataTable:GetCount()
    if tbData == nil or nDay == nMaxCount then
        log("UIScheduleNoobLoginNextDay:OnRefresh noob login over")
        self:CloseSelf()
    else
        local tbTemplate = NoobLoginDataTable:GetTemplate(nDay + 1)
        if tbTemplate == nil then
            logwarning("UIScheduleNoobLoginNextDay:OnRefresh invalid day", nDay)
            return
        end
        local tbAwards = AwardDataTable:GetAwardItem(tbTemplate.nAwardId)
        if tbAwards == nil or #tbAwards == 0 then
            logwarning("UIScheduleNoobLoginNextDay:OnRefresh not award", tbTemplate.nAwardId)
            return
        end
        local tbItemTemplate = ItemDataTable:GetTemplate(tbAwards[1].nItemId) 
        if tbItemTemplate == nil then
            logwarning("UIScheduleNoobLoginNextDay:OnRefresh not find item", tbAwards[1].nItemId)
        else
            local pWidgetRef = self.pWidgetRef
            UISetUtils.SetImageBrushRes(pWidgetRef.imgDay, tbTemplate.szDayIcon:load())
            local nAwardId = tbItemTemplate.nGiftBoxRewardId
            local nCurCount = 1
            if nAwardId ~= nil then
                local tbAwardItems = AwardDataTable:GetAwardItem(nAwardId)
                if tbAwardItems == nil then
                    tbAwardItems = AwardGiftBoxDataTable:GetAwardItem(nAwardId)
                end
                local tbItemIds = {}
                for _, v in pairs(tbAwardItems) do
                    local tbTemp = ItemSystem:GetItemTemplate(v.nItemId)
                    if tbTemp then
                        table.insert(tbItemIds, v)
                    end
                end
                nCurCount = math.min(#tbItemIds, MAX_COUNT) 
                for i = 1, nCurCount do
                    self.tbItems[i].pWidgetRef:SetVisibility(ESlateVisibility_Visible)
                    self.tbItems[i]:SetDisplayItemData(tbItemIds[i].nItemId, tbItemIds[i].nCount, true) 
                end
            end
            for i = nCurCount + 1, MAX_COUNT do
                self.tbItems[i].pWidgetRef:SetVisibility(ESlateVisibility_Collapsed)
            end
        end
    end
end

local function OnClickClose(self)
    self:CloseSelf()
end

function UIScheduleNoobLoginNextDay:OnLoad()
    local PrefabHelper = self.PrefabHelper
    local pWidgetRef = self.pWidgetRef

    PrefabHelper:BindPrefab(pWidgetRef.pbCutoutScreenAdapter)

    self.tbItems = {}
    for i = 1, MAX_COUNT do
        local pbItem = PrefabHelper:BindPrefab(pWidgetRef["upItem"..i], UIDef.UP_LOBBY_DISPLAY_ITEM)
        table.insert(self.tbItems, pbItem) 
    end
    -- self.pbItem = self.PrefabHelper:BindPrefab(self.pWidgetRef.pbLobbyItem, UIDef.UP_LOBBY_DISPLAY_ITEM)
end

function UIScheduleNoobLoginNextDay:OnUnload()
end

function UIScheduleNoobLoginNextDay:OnBindEvent(EventHelper)
    local pWidgetRef = self.pWidgetRef
    EventHelper:RegisterCppDelegate(pWidgetRef.btnClose.OnClicked, self, OnClickClose)
end

function UIScheduleNoobLoginNextDay:OnShow()
    RefreshUI(self, self.tbOpenArgs.nDay)
    self:PlayAnimation("animLoginNextDay2In", 0, 1, EUMGSequencePlayMode.Forward, 1)
end

return UIScheduleNoobLoginNextDay

-----------------------------------------------------
--File Name    : UPShortcutMenuItem.lua
--Author       : Song Fuhao
--Create Time  : 2018-09-27
--Description  : FFA主界面快捷菜单Item
-----------------------------------------------------
local luaclass = require ("luaclass")
local PrefabBase = require("PrefabBase")
local UPShortcutMenuItem = luaclass("UPShortcutMenuItem", PrefabBase)

local UISetUtils = require("UISetUtils")
local LuaDelegate = require("LuaDelegate")
local MathUtil = require("MathUtil")
local BattleItemDataTable = require("BattleItemDataTable")
local BattleItemColorGradeHelper = require("BattleItemColorGradeHelper")

UPShortcutMenuItem.bSelected = false
UPShortcutMenuItem.OnClickedButtonDelegate = nil
UPShortcutMenuItem.tbCdRefreshTimer = nil
UPShortcutMenuItem.nCdStartTime = 0
UPShortcutMenuItem.nCdDuration = 0

local CD_REFRESH_INTERVAL = 0.03

local function OnClickedButton(self)
    self.OnClickedButtonDelegate:Fire()
end

local function OnCdFinish(self)
    self.pWidgetRef.pgbCD:SetVisibility(ESlateVisibility.Collapsed)
    self.TimerHelper:ClearTimer(self.tbCdRefreshTimer)
    self.tbCdRefreshTimer = nil
end

local function OnCdTick(self)
    local nPercent = 1 - MathUtil.Clamp((getseconds() - self.nCdStartTime) / self.nCdDuration, 0, 1)
    self.pWidgetRef.pgbCD:SetPercent(nPercent)
    if nPercent <= 0 then
        OnCdFinish(self)
    end
end

local function OnCdStart(self, nDuration)
    self.nCdStartTime = getseconds()
    self.nCdDuration = nDuration
    if not self.tbCdRefreshTimer then
        self.tbCdRefreshTimer = self.TimerHelper:NewTimerMethod(self, OnCdTick, CD_REFRESH_INTERVAL, true)
    end
    self.pWidgetRef.pgbCD:SetPercent(1)
    self.pWidgetRef.pgbCD:SetVisibility(ESlateVisibility.HitTestInvisible)
end

function UPShortcutMenuItem:OnCreate()
    self.OnClickedButtonDelegate = LuaDelegate()
end

function UPShortcutMenuItem:OnBindEvent(EventHelper)
    EventHelper:RegisterCppDelegate(self.pWidgetRef.btnItem.OnClicked, self, OnClickedButton)
end

function UPShortcutMenuItem:SetItemInfo(tbItemInfo)
    if tbItemInfo then
        self:SetItemTemplateId(tbItemInfo.nTemplateId)
        self:SetItemCount(tbItemInfo.nItemCount)
        self.pWidgetRef.imgItem:SetVisibility(ESlateVisibility.HitTestInvisible)
        self.pWidgetRef.imgColour:SetVisibility(ESlateVisibility.HitTestInvisible)
    else
        self.pWidgetRef.imgItem:SetVisibility(ESlateVisibility.Collapsed)
        self.pWidgetRef.imgColour:SetVisibility(ESlateVisibility.Collapsed)
        self.pWidgetRef.txtCount:SetVisibility(ESlateVisibility.Collapsed)
    end
end

function UPShortcutMenuItem:SetItemTemplateId(nTemplateId)
    local tbResTemplate = BattleItemDataTable:GetResTemplate(nTemplateId)
    local pResouceObject = tbResTemplate.szIconPath:load()
    UISetUtils.SetImageBrushRes(self.pWidgetRef.imgItem, pResouceObject)

    local szColorGradeImg = BattleItemColorGradeHelper.GetColorGradeImg(nTemplateId)
    UISetUtils.SetImageBrushRes(self.pWidgetRef.imgColour, szColorGradeImg:load())
end

function UPShortcutMenuItem:SetItemCount(nItemCount)
    local pVisibility = nItemCount > 1 and ESlateVisibility.HitTestInvisible or ESlateVisibility.Collapsed
    self.pWidgetRef.txtCount:SetText(nItemCount)
    self.pWidgetRef.txtCount:SetVisibility(pVisibility)
end

function UPShortcutMenuItem:SetSelected(bSelected)
    self.bSelected = bSelected
    if bSelected then
        self.pWidgetRef.imgSelected:SetVisibility(ESlateVisibility.SelfHitTestInvisible)
    else
        self.pWidgetRef.imgSelected:SetVisibility(ESlateVisibility.Collapsed)
    end
end

function UPShortcutMenuItem:IsSelected()
    return self.bSelected
end

function UPShortcutMenuItem:StartCD(nDuration)
    if nDuration > 0 then
        OnCdStart(self, nDuration)
    else
        OnCdFinish(self)
    end
end

return UPShortcutMenuItem

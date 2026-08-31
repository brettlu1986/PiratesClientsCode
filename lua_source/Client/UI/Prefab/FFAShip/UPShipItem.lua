-----------------------------------------------------
--File Name    : UPShipItem.lua
--Author       : Xu Weihua
--Create Time  : 2018-09-11
--Description  : For each available ship to build.
-----------------------------------------------------
local luaclass = require ("luaclass")
local ListItemBase = require("ListItemBase")
local UPShipItem = luaclass("UPShipItem", ListItemBase)
local UISetUtils = require("UISetUtils")
local UIResourceDef = require("UIResourceDef")
local CheckCanBuildItemHelper = require("CheckCanBuildItemHelper")
local ClientEventDef = require("ClientEventDef")
local GamePlayerSelfHelper = require("GamePlayerSelfHelper")
local ShipResDataTable = require("ShipResDataTable")

UPShipItem.tbBuildShipItemData = nil
UPShipItem.bIsPlayingCanBuildAnim = nil

local ANIM_NAME = "animCanBuild"

local function PlayCanBuildPromptAnim(self)
    local pWidgetRef = self.pWidgetRef
    pWidgetRef.imgCanBuild:SetVisibility(ESlateVisibility.SelfHitTestInvisible)
    if not self.bIsPlayingCanBuildAnim then
        self.bIsPlayingCanBuildAnim = true
        self:PlayAnimation(ANIM_NAME, 0, 0, EUMGSequencePlayMode.Forward, 1)
    end
end

local function StopCanBuildPromptAnim(self)
    local pWidgetRef = self.pWidgetRef
    pWidgetRef.imgCanBuild:SetVisibility(ESlateVisibility.Collapsed)
    if self.bIsPlayingCanBuildAnim then
        self.bIsPlayingCanBuildAnim = false
        self:StopAnimation(ANIM_NAME)
    end
end

local function ShowCanBuildPrompt(self)
    local tbItemTemplate = self.tbBuildShipItemData.tbItemTemplate
    local nCharacterInstanceId = GamePlayerSelfHelper:GetServerInstanceId()
    if CheckCanBuildItemHelper.NeedBuildShipByTemplate(nCharacterInstanceId, tbItemTemplate.nId, true) then
        PlayCanBuildPromptAnim(self)
    else
        StopCanBuildPromptAnim(self)
    end
end

local function OnClickedBtnSelect(self)
    self:SelectItem()
    local tbBuildShipItemData = self.tbBuildShipItemData
    if tbBuildShipItemData and tbBuildShipItemData.OnShipItemPressedDelegate then
        tbBuildShipItemData.OnShipItemPressedDelegate:Fire(tbBuildShipItemData.tbBuildTemplate.nId)
    end
end

local function SetSelected(self, bSelected)
    local imgSelected = self.pWidgetRef.imgSelected
    if bSelected then
        imgSelected:SetVisibility(ESlateVisibility.SelfHitTestInvisible)
    else
        imgSelected:SetVisibility(ESlateVisibility.Collapsed)
    end
end

local function Refresh(self, tbBuildShipItemData)
    local pWidgetRef = self.pWidgetRef
    self.tbBuildShipItemData = tbBuildShipItemData
    local tbItemTemplate = tbBuildShipItemData.tbItemTemplate
    if tbBuildShipItemData then
        -- Set the icon for the ship item.
        local nShipId = tbItemTemplate.nShipId
        local tbShipResTemplate = ShipResDataTable:GetTemplate(nShipId)
        local szIconPath = tbShipResTemplate.szIconPath
        local ResObject = szIconPath:load()
        UISetUtils.SetImageBrushRes(pWidgetRef.imgPackItemBg, ResObject, true)

        -- Update the selected/unselected state.
        if self:IsSelected() then
            SetSelected(self, true)
        else
            SetSelected(self, false)
        end

        local nGrade = tbItemTemplate.nGrade
        local szGradeIcon = UIResourceDef.SHIP_GRADE_ICON[nGrade]
        UISetUtils.SetImageBrushRes(pWidgetRef.imgShipGrade, szGradeIcon:load())

        pWidgetRef.txtDesc:SetText(tbItemTemplate.l10nName)

        ShowCanBuildPrompt(self)
    end
end

local function OnItemChanged(self)
    if self.pWidgetRef:IsVisible() then
        ShowCanBuildPrompt(self)
    end
end

local function OnShipBuildGradeChanged(self, tbPlayer, _)
    if GamePlayerSelfHelper:GetServerInstanceId() == tbPlayer:GetServerInstanceId() then
        OnItemChanged(self)
    end
end

function UPShipItem:OnRefresh(tbBuildShipItemData)
    Refresh(self, tbBuildShipItemData)
end

function UPShipItem:OnBindEvent(EventHelper)
    EventHelper:RegisterCppDelegate(self.pWidgetRef.btnSelect.OnClicked, self, OnClickedBtnSelect)
    EventHelper:RegisterEvent(ClientEventDef.EV_BATTLE_ITEM_ADD_CLIENT, self, OnItemChanged)
    EventHelper:RegisterEvent(ClientEventDef.EV_BATTLE_ITEM_REMOVE_CLIENT, self, OnItemChanged)
    EventHelper:RegisterEvent(ClientEventDef.EV_BATTLE_ITEM_CHANGE_STACKCOUNT_CLIENT, self, OnItemChanged)
    EventHelper:RegisterEvent(ClientEventDef.EV_SHIP_BUILD_FINISH_CLIENT, self, OnItemChanged)
    EventHelper:RegisterEvent(ClientEventDef.EV_SHIP_BUILD_GRADE_CHANGED_CLIENT, self, OnShipBuildGradeChanged)
end

return UPShipItem

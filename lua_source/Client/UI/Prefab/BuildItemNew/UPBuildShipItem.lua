-----------------------------------------------------
--File Name    : UPBuildShipItem.lua
--Author       : zhiyuan
--Create Time  : 2019-03-11
--Description  : 建造界面的船的item的up
-----------------------------------------------------
local luaclass = require ("luaclass")
local ListItemBase = require("ListItemBase")
local UPBuildShipItem = luaclass("UPBuildShipItem", ListItemBase)
local UISetUtils = require("UISetUtils")
local UIResourceDef = require("UIResourceDef")
local CheckCanBuildItemHelper = require("CheckCanBuildItemHelper")
local ClientEventDef = require("ClientEventDef")
local GamePlayerSelfHelper = require("GamePlayerSelfHelper")
local ShipItemHelper = require("ShipItemHelper")

UPBuildShipItem.tbBuildShipItemData = nil
UPBuildShipItem.bIsPlayingCanBuildAnim = nil

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

local function SetDark(self, bDark)
    local imgBlack = self.pWidgetRef.imgBlack
    if bDark then
        imgBlack:SetVisibility(ESlateVisibility.SelfHitTestInvisible)
    else
        imgBlack:SetVisibility(ESlateVisibility.Collapsed)
    end
end

local function SetLock(self, bLock)
    local imgLock = self.pWidgetRef.imgLock
    if bLock then
        imgLock:SetVisibility(ESlateVisibility.SelfHitTestInvisible)
    else
        imgLock:SetVisibility(ESlateVisibility.Collapsed)
    end
end

local function ShowCanBuildPrompt(self, bIsCurrentShip)
    local tbItemTemplate = self.tbBuildShipItemData.tbItemTemplate
    local nCharacterInstanceId = GamePlayerSelfHelper:GetServerInstanceId()
    local nItemTemplateId = tbItemTemplate.nId
    if CheckCanBuildItemHelper.NeedBuildShipByTemplate(nCharacterInstanceId, nItemTemplateId, true) then
        PlayCanBuildPromptAnim(self)
    else
        StopCanBuildPromptAnim(self)
    end

    if CheckCanBuildItemHelper.CanBuildShipByTemplate(nCharacterInstanceId, nItemTemplateId, true) or bIsCurrentShip then
        SetDark(self, false)
    else
        SetDark(self, true)
    end

    if CheckCanBuildItemHelper.IsShipBuildLock(nCharacterInstanceId, nItemTemplateId, true) then
        SetLock(self, true)
    else
        SetLock(self, false)
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

local function SetCurrent(self, bIsCurrentShip)
    local txtCurrent = self.pWidgetRef.txtCurrent
    if bIsCurrentShip then
        txtCurrent:SetVisibility(ESlateVisibility.SelfHitTestInvisible)
    else
        txtCurrent:SetVisibility(ESlateVisibility.Collapsed)
    end
end

local function Refresh(self, tbBuildShipItemData)
    local pWidgetRef = self.pWidgetRef
    self.tbBuildShipItemData = tbBuildShipItemData
    local tbItemTemplate = tbBuildShipItemData.tbItemTemplate
    if tbBuildShipItemData then
        local szIconPath = ShipItemHelper.GetShipIconPath(tbItemTemplate)

        local ResObject = szIconPath:load()
        UISetUtils.SetImageBrushRes(pWidgetRef.imgPackItemBg, ResObject, true)

        if self:IsSelected() then
            SetSelected(self, true)
        else
            SetSelected(self, false)
        end

        SetCurrent(self, tbBuildShipItemData.bIsCurrentShip)

        local nGrade = tbItemTemplate.nGrade
        local szGradeIcon = UIResourceDef.SHIP_GRADE_ICON[nGrade]
        UISetUtils.SetImageBrushRes(pWidgetRef.imgShipGrade, szGradeIcon:load())

        pWidgetRef.txtDesc:SetText(tbItemTemplate.l10nName)

        ShowCanBuildPrompt(self, tbBuildShipItemData.bIsCurrentShip)
    end
end

local function OnItemChanged(self)
    if self.pWidgetRef:IsVisible() then
        local nCurrentShipTemplateId = ShipItemHelper.GetCurrentShipItemTemplateIdOnClient()
        local tbItemTemplate = self.tbBuildShipItemData.tbItemTemplate
        local nItemTemplateId = tbItemTemplate.nId
        local bIsCurrentShip = nCurrentShipTemplateId == nItemTemplateId
        ShowCanBuildPrompt(self, bIsCurrentShip)
    end
end

local function OnShipBuildGradeChanged(self, tbPlayer, _)
    if GamePlayerSelfHelper:GetServerInstanceId() == tbPlayer:GetServerInstanceId() then
        OnItemChanged(self)
    end
end

function UPBuildShipItem:OnRefresh(tbBuildShipItemData)
    Refresh(self, tbBuildShipItemData)
end

function UPBuildShipItem:OnBindEvent(EventHelper)
    EventHelper:RegisterCppDelegate(self.pWidgetRef.btnSelect.OnClicked, self, OnClickedBtnSelect)
    EventHelper:RegisterEvent(ClientEventDef.EV_BATTLE_ITEM_ADD_CLIENT, self, OnItemChanged)
    EventHelper:RegisterEvent(ClientEventDef.EV_BATTLE_ITEM_REMOVE_CLIENT, self, OnItemChanged)
    EventHelper:RegisterEvent(ClientEventDef.EV_BATTLE_ITEM_CHANGE_STACKCOUNT_CLIENT, self, OnItemChanged)
    EventHelper:RegisterEvent(ClientEventDef.EV_SHIP_BUILD_FINISH_CLIENT, self, OnItemChanged)
    EventHelper:RegisterEvent(ClientEventDef.EV_SHIP_BUILD_GRADE_CHANGED_CLIENT, self, OnShipBuildGradeChanged)
end

return UPBuildShipItem

-----------------------------------------------------
--File Name    : UPBuildItem.lua
--Author       : zhiyuan
--Create Time  : 2019-03-11
--Description  : 建造界面的item的up
-----------------------------------------------------
local luaclass = require ("luaclass")
local ListItemBase = require("ListItemBase")
local UPBuildItem = luaclass("UPBuildItem", ListItemBase)
local UISetUtils = require("UISetUtils")
local UIResourceDef = require("UIResourceDef")
local ClientEventDef = require("ClientEventDef")
local BattleItemDataTable = require("BattleItemDataTable")
local BattleItemSystemClient = require("BattleItemSystemClient")
local GamePlayerSelfHelper = require("GamePlayerSelfHelper")
local CheckCanBuildItemHelper = require("CheckCanBuildItemHelper")
local BattleItemCategoryDef = require("BattleItemCategoryDef")
local ShipItemHelper = require("ShipItemHelper")
local ShipWeaponCategoryDataTable = require("ShipWeaponCategoryDataTable")
local BattleItemColorGradeHelper = require("BattleItemColorGradeHelper")

UPBuildItem.tbItemTemplate = nil
UPBuildItem.OnItemPressedDelegate = nil
UPBuildItem.nPos1 = nil
UPBuildItem.nPos2 = nil
UPBuildItem.bIsPlayingCanBuildAnim = nil

local ANIM_NAME = "animCanBuild"

local function PlayCanBuildAnim(self)
    local pWidgetRef = self.pWidgetRef
    pWidgetRef.imgCanBuild:SetVisibility(ESlateVisibility.SelfHitTestInvisible)
    if not self.bIsPlayingCanBuildAnim then
        self.bIsPlayingCanBuildAnim = true
        self:PlayAnimation(ANIM_NAME, 0, 0, EUMGSequencePlayMode.Forward, 1)
    end
end

local function StopCanBuildAnim(self)
    local pWidgetRef = self.pWidgetRef
    pWidgetRef.imgCanBuild:SetVisibility(ESlateVisibility.Collapsed)
    if self.bIsPlayingCanBuildAnim then
        self.bIsPlayingCanBuildAnim = false
        self:StopAnimation(ANIM_NAME)
    end
end

local function SetItemIcon(self)
    local pWidgetRef = self.pWidgetRef
    local tbItemTemplate = self.tbItemTemplate
    local tbResTemplate = BattleItemDataTable:GetResTemplate(tbItemTemplate.nId)
    local szIconPath  = tbResTemplate.szIconPath
    --local ResObject = szIconPath:load()
    --UISetUtils.SetImageBrushRes(pWidgetRef.imgItemIcon, ResObject, true)
    UISetUtils.SetAsyncImageBrushFromSprite(pWidgetRef.imgItemIcon, szIconPath, nil, true)
end

local function SetItemGrade(self)
    local imgGrade = self.pWidgetRef.imgGrade
    local tbItemTemplate = self.tbItemTemplate
    local nGrade = tbItemTemplate.nGrade
    local szGradeIcon = UIResourceDef.BUILD_ITEM_GRADE_ICON[nGrade]
    if szGradeIcon == nil then
        imgGrade:SetVisibility(ESlateVisibility.Collapsed)
    else
        imgGrade:SetVisibility(ESlateVisibility.SelfHitTestInvisible)
        --UISetUtils.SetImageBrushRes(imgGrade, szGradeIcon:load())
        UISetUtils.SetAsyncImageBrushFromSprite(imgGrade, szGradeIcon)
    end
end

local function SetIsCurrent(self, bIsCurrent)
    local txtCurrent = self.pWidgetRef.txtCurrent
    if bIsCurrent then
        txtCurrent:SetVisibility(ESlateVisibility.SelfHitTestInvisible)
    else
        txtCurrent:SetVisibility(ESlateVisibility.Collapsed)
    end
end

local function IsNeedItem(self)
    local tbItemTemplate = self.tbItemTemplate
    local nItemTemplateId = tbItemTemplate.nId
    local nCharacterInstanceId = GamePlayerSelfHelper:GetServerInstanceId()

    local bNeedBuild = false
    local nCategory = tbItemTemplate.nCategory
    if nCategory == BattleItemCategoryDef.SHIP then
        bNeedBuild = CheckCanBuildItemHelper.NeedBuildShipByTemplate(nCharacterInstanceId, nItemTemplateId, true)
    elseif nCategory == BattleItemCategoryDef.SHIP_WEAPON then
        bNeedBuild = CheckCanBuildItemHelper.NeedBuildShipWeaponByTemplate(nCharacterInstanceId, nItemTemplateId, true)
    elseif nCategory == BattleItemCategoryDef.SHIP_PART then
        bNeedBuild = CheckCanBuildItemHelper.NeedBuildShipPartByTemplate(nCharacterInstanceId, nItemTemplateId, true)
    elseif nCategory == BattleItemCategoryDef.HUMAN_WEAPON then
        bNeedBuild = CheckCanBuildItemHelper.NeedBuildHumanWeaponByTemplate(nCharacterInstanceId, nItemTemplateId, self.nPos1, true)
    elseif nCategory == BattleItemCategoryDef.HUMAN_ARMOR then
        bNeedBuild = CheckCanBuildItemHelper.NeedBuildHumanArmorByTemplate(nCharacterInstanceId, nItemTemplateId, true)
    end

    return bNeedBuild
end

local function ShowCanBuild(self, bIsCurrent)
    local bNeed = IsNeedItem(self)
    local imgBlack = self.pWidgetRef.imgBlack
    if bNeed then
        PlayCanBuildAnim(self)
    else
        StopCanBuildAnim(self)
    end
    local nItemTemplateId = self.tbItemTemplate.nId
    local bVerificationResult, _ = BattleItemSystemClient:VerifyItemBuilding(nItemTemplateId, self.nPos1)
    if bIsCurrent or bVerificationResult then
        imgBlack:SetVisibility(ESlateVisibility.Collapsed)
    else
        imgBlack:SetVisibility(ESlateVisibility.SelfHitTestInvisible)
    end
end

local function OnClickedBtnBuild(self)
    if self.OnItemPressedDelegate then
        self.OnItemPressedDelegate:Fire(self)
    end
end

local function ShowRecommonded(self)
    local tbItemTemplate = self.tbItemTemplate
    local nCategory = tbItemTemplate.nCategory
    local bRecommonded = false
    if nCategory == BattleItemCategoryDef.SHIP_WEAPON then
        local nItemTemplateId = tbItemTemplate.nId
        local nWeaponSlot = ShipWeaponCategoryDataTable:GetWeaponSlot(tbItemTemplate.nSubCategory)
        local nCharacterInstanceId = GamePlayerSelfHelper:GetServerInstanceId()
        local tbEquippedItem = BattleItemSystemClient:GetEquippedItem(nCategory, nCharacterInstanceId, nWeaponSlot)
        if not tbEquippedItem then
            local nCurrentShipItemTemplateId = ShipItemHelper.GetCurrentShipItemTemplateIdOnClient()
            if nCurrentShipItemTemplateId ~= nil then
                local tbShipItemTemplate = BattleItemDataTable:GetTemplate(nCurrentShipItemTemplateId)
                local tbRecommendedWeapons = tbShipItemTemplate.tbRecommendedWeapons
                for _, v in pairs(tbRecommendedWeapons) do
                    if nItemTemplateId == v then
                        bRecommonded = true
                        break
                    end
                end
            end
        end
    end
    local txtRecommended = self.pWidgetRef.txtRecommended
    if bRecommonded then
        txtRecommended:SetVisibility(ESlateVisibility.SelfHitTestInvisible)
    else
        txtRecommended:SetVisibility(ESlateVisibility.Collapsed)
    end
end

local function SetItemGradeColor(self)
    local tbItemTemplate = self.tbItemTemplate
    local nItemTemplateId = tbItemTemplate.nId
    local szColorGradeImg = BattleItemColorGradeHelper.GetColorGradeImg(nItemTemplateId)
    --UISetUtils.SetImageBrushRes(self.pWidgetRef.imgColor, szColorGradeImg:load())
    UISetUtils.SetAsyncImageBrushFromSprite(self.pWidgetRef.imgColor, szColorGradeImg)
end

local function Refresh(self, tbItemTemplate, bIsCurrent)
    self.tbItemTemplate = tbItemTemplate
    SetItemIcon(self)
    SetItemGradeColor(self)
    SetItemGrade(self)
    SetIsCurrent(self, bIsCurrent)
    ShowCanBuild(self, bIsCurrent)
    ShowRecommonded(self)
end

local function OnItemChanged(self)
    if self.pWidgetRef:IsVisible() then
        local bIsCurrent = self.pWidgetRef.txtCurrent:IsVisible()
        Refresh(self, self.tbItemTemplate, bIsCurrent)
    end
end

function UPBuildItem:SetOnItemPressedDelegate(OnItemPressedDelegate, nPos1, nPos2)
    self.OnItemPressedDelegate = OnItemPressedDelegate
    self.nPos1 = nPos1
    self.nPos2 = nPos2
end

function UPBuildItem:Refresh(tbItemTemplate, bIsCurrent)
    self.pWidgetRef:SetVisibility(ESlateVisibility.Visible)
    Refresh(self, tbItemTemplate, bIsCurrent)
end

function UPBuildItem:Collaped()
    self.pWidgetRef:SetVisibility(ESlateVisibility.Collapsed)
end

function UPBuildItem:SetSelected(bSelected)
    self.bSelected = bSelected
    self.pWidgetRef.imgSelected:SetVisibility(bSelected and ESlateVisibility.SelfHitTestInvisible or ESlateVisibility.Collapsed)
end

function UPBuildItem:GetTemplateId()
    return self.tbItemTemplate.nId
end

function UPBuildItem:GetPos1()
    return self.nPos1
end

function UPBuildItem:GetPos2()
    return self.nPos2
end

function UPBuildItem:IsSetSelected()
    return self.bSelected
end

function UPBuildItem:OnBindEvent(EventHelper)
    EventHelper:RegisterCppDelegate(self.pWidgetRef.btnPass.OnClicked, self, OnClickedBtnBuild)

    EventHelper:RegisterEvent(ClientEventDef.EV_BATTLE_ITEM_ADD_CLIENT, self, OnItemChanged)
    EventHelper:RegisterEvent(ClientEventDef.EV_BATTLE_ITEM_REMOVE_CLIENT, self, OnItemChanged)
    EventHelper:RegisterEvent(ClientEventDef.EV_BATTLE_ITEM_CHANGE_STACKCOUNT_CLIENT, self, OnItemChanged)
end

return UPBuildItem

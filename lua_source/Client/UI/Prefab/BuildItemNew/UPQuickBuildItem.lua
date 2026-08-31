-----------------------------------------------------
--File Name    : UPQuickBuildItem.lua
--Author       : zhiyuan
--Create Time  : 2019-03-20
--Description  : 快捷建造的item的up
-----------------------------------------------------
local luaclass = require ("luaclass")
local ListItemBase = require("ListItemBase")
local UPQuickBuildItem = luaclass("UPQuickBuildItem", ListItemBase)

local UISetUtils = require("UISetUtils")
local UIResourceDef = require("UIResourceDef")
local BattleItemDataTable = require("BattleItemDataTable")
local GamePlayerSelfHelper = require("GamePlayerSelfHelper")
local BattleItemCategoryDef = require("BattleItemCategoryDef")
local BattleItemSystemClient = require("BattleItemSystemClient")
local BattleItemBuildDataTable = require("BattleItemBuildDataTable")
local BattleItemColorGradeHelper = require("BattleItemColorGradeHelper")


UPQuickBuildItem.nItemTemplateId = nil
UPQuickBuildItem.bIsPlayingQuickBuildAnim = nil

local ANIM_NAME = "animCanBuild"

local function PlayQuickBuildAnim(self)
    local pWidgetRef = self.pWidgetRef
    pWidgetRef.imgCanBuild:SetVisibility(ESlateVisibility.SelfHitTestInvisible)
    if not self.bIsPlayingQuickBuildAnim then
        self.bIsPlayingQuickBuildAnim = true
        self:PlayAnimation(ANIM_NAME, 0, 0, EUMGSequencePlayMode.Forward, 1)
    end
end

local function StopQuickBuildAnim(self)
    local pWidgetRef = self.pWidgetRef
    pWidgetRef.imgCanBuild:SetVisibility(ESlateVisibility.Collapsed)
    if self.bIsPlayingQuickBuildAnim then
        self.bIsPlayingQuickBuildAnim = false
        self:StopAnimation(ANIM_NAME)
    end
end

local function SetItemIcon(self)
    local pWidgetRef = self.pWidgetRef
    local tbResTemplate = BattleItemDataTable:GetResTemplate(self.nItemTemplateId)
    local szIconPath  = tbResTemplate.szIconPath
    local ResObject = szIconPath:load()
    UISetUtils.SetImageBrushRes(pWidgetRef.imgItemIcon, ResObject, true)
end

local function SetItemGrade(self)
    local imgGrade = self.pWidgetRef.imgGrade
    local tbItemTemplate = BattleItemDataTable:GetTemplate(self.nItemTemplateId)
    local nGrade = tbItemTemplate.nGrade
    local szGradeIcon = UIResourceDef.BUILD_ITEM_GRADE_ICON[nGrade]
    if szGradeIcon == nil then
        imgGrade:SetVisibility(ESlateVisibility.Collapsed)
    else
        imgGrade:SetVisibility(ESlateVisibility.SelfHitTestInvisible)
        UISetUtils.SetImageBrushRes(imgGrade, szGradeIcon:load())
    end
end

local function SetItemGradeColor(self)
    local nItemTemplateId = self.nItemTemplateId
    local szColorGradeImg = BattleItemColorGradeHelper.GetColorGradeImg(nItemTemplateId)
    UISetUtils.SetImageBrushRes(self.pWidgetRef.imgColor, szColorGradeImg:load())
end

local function OnClickedBtnBuild(self)
    local nItemTemplateId = self.nItemTemplateId
    local tbItemTemplate = BattleItemDataTable:GetTemplate(nItemTemplateId)
    local nSlotIndex = nil
    if tbItemTemplate.nCategory == BattleItemCategoryDef.HUMAN_WEAPON then
        local tbBuildTemplate = BattleItemBuildDataTable:GetBuildTemplate(nItemTemplateId)
        local nPrerequisiteId = tbBuildTemplate.nPrerequisiteId
        local nCharacterInstanceId = GamePlayerSelfHelper:GetServerInstanceId()
        local tbItems = BattleItemSystemClient:GetEquippedItems(BattleItemCategoryDef.HUMAN_WEAPON, nCharacterInstanceId)
        for _, v in pairs(tbItems) do
            if v:GetTemplateId() == nPrerequisiteId then
                local _, _, nSlot = v:SplitAndGetStorageLocation()
                nSlotIndex = nSlot
                break
            end
        end
        if nSlotIndex == nil then
            log("Cannot find human weapon build slot!"..nItemTemplateId)
            return
        end
    end
    BattleItemSystemClient:RequestBuildItem(self.nItemTemplateId, nSlotIndex)
end

local function Refresh(self, nItemTemplateId)
    self.nItemTemplateId = nItemTemplateId
    SetItemIcon(self)
    SetItemGradeColor(self)
    SetItemGrade(self)
    PlayQuickBuildAnim(self)
end

function UPQuickBuildItem:Refresh(nItemTemplateId)
    self.pWidgetRef:SetVisibility(ESlateVisibility.Visible)
    Refresh(self, nItemTemplateId)
end

function UPQuickBuildItem:Hidden()
    self.pWidgetRef:SetVisibility(ESlateVisibility.Hidden)
    StopQuickBuildAnim(self)
end

function UPQuickBuildItem:OnBindEvent(EventHelper)
    EventHelper:RegisterCppDelegate(self.pWidgetRef.btnPass.OnClicked, self, OnClickedBtnBuild)
end

return UPQuickBuildItem

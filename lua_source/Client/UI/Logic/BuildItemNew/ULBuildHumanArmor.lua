-----------------------------------------------------
--File Name    : ULBuildHumanArmor.lua
--Author       : zhiyuan
--Create Time  : 2019-09-16
--Description  : 建造人的护甲的UI逻辑
-----------------------------------------------------
local luaclass = require("luaclass")
local UILogicBase = require("UILogicBase")
local ULBuildHumanArmor = luaclass("ULBuildHumanArmor", UILogicBase)

local LuaDelegateClass = require("LuaDelegate")
local UIDef = require("UIDef")
local BattleItemCategoryDef = require("BattleItemCategoryDef")
local GamePlayerSelfHelper = require("GamePlayerSelfHelper")
local BattleItemSystemHelper = require("BattleItemSystemHelper")

ULBuildHumanArmor.tbPbBuildHumanArmors = nil
ULBuildHumanArmor.OnBuildHumanArmorPressedDelegate = nil

local SLOT_MAX = 1
local GRADE_MAX = 3

local function SetItemSelected(self, nPos1, nPos2)
    for i, v1 in pairs(self.tbPbBuildHumanArmors) do
        for j, v2 in pairs(v1) do
            if i == nPos1 and j == nPos2 then
                v2:SetSelected(true)
            else
                v2:SetSelected(false)
            end
        end
    end
end

local function SetAllItemUnSelected(self)
    for i, v1 in pairs(self.tbPbBuildHumanArmors) do
        for j, v2 in pairs(v1) do
            v2:SetSelected(false)
        end
    end
end

local function OnHumanArmorSelected(self, pbBuildItem)
    if pbBuildItem:IsSetSelected() then
        self.Owner:CloseTips()
        pbBuildItem:SetSelected(false)
    else
        self.Owner:ShowBuildItemTipsNew(pbBuildItem:GetTemplateId())
        SetItemSelected(self, pbBuildItem:GetPos1(), pbBuildItem:GetPos2())
    end
end

local function AddPbBuildHumanArmor(self, nSubCategory, nGrade, pbBuildHumanArmor)
    local tbPbs = self.tbPbBuildHumanArmors[nSubCategory]
    if tbPbs == nil then
        self.tbPbBuildHumanArmors[nSubCategory] = {}
        tbPbs = self.tbPbBuildHumanArmors[nSubCategory]
    end
    tbPbs[nGrade] = pbBuildHumanArmor
end

local function GetPbBuildHumanArmor(self, nSubCategory, nGrade)
    local tbPbs = self.tbPbBuildHumanArmors[nSubCategory]
    if tbPbs == nil then
        error("Cannot find prefab!", nSubCategory, nGrade)
    end
    local tbPb = tbPbs[nGrade]
    if tbPb == nil then
        error("Cannot find prefab!", nSubCategory, nGrade)
    end
    return tbPb
end

local function NoBuildItem(self, nSlot)
    local pWidgetRef = self.pWidgetRef
    pWidgetRef["sboxHumanArmor"..nSlot]:SetVisibility(ESlateVisibility.Collapsed)
    pWidgetRef["ovlLackArmor"..nSlot]:SetVisibility(ESlateVisibility.SelfHitTestInvisible)
end

local function RefreshBuildHumanArmorOnOneSlot(self, nSlot, EquippedArmor, tbBuildDatas)
    local pWidgetRef = self.pWidgetRef
    pWidgetRef["sboxHumanArmor"..nSlot]:SetVisibility(ESlateVisibility.SelfHitTestInvisible)
    pWidgetRef["ovlLackArmor"..nSlot]:SetVisibility(ESlateVisibility.Collapsed)

    for _, v in pairs(tbBuildDatas) do
        local tbItemTemplate = v.tbBattleItemTemplate
        local pbBuildHumanArmor = GetPbBuildHumanArmor(self, nSlot, tbItemTemplate.nGrade)

        local bIsCurrent = false
        if EquippedArmor and EquippedArmor:GetTemplateId() == tbItemTemplate.nId then
            bIsCurrent = true
        end

        pbBuildHumanArmor:Refresh(tbItemTemplate, bIsCurrent)
    end
end

local function RefreshHumanArmorNote(self, bHasEmptySlot)
    local txtHumanArmorNote = self.pWidgetRef.txtHumanArmorNote
    if bHasEmptySlot then
        txtHumanArmorNote:SetVisibility(ESlateVisibility.SelfHitTestInvisible)
    else
        txtHumanArmorNote:SetVisibility(ESlateVisibility.Collapsed)
    end
end

local function RefreshHumanArmor(self)
    local nCharacterInstanceId = GamePlayerSelfHelper:GetServerInstanceId()

    local bHasEmptySlot = false
    for i = 1, SLOT_MAX do
        local tbBuildDatas, EquippedArmor = BattleItemSystemHelper:GetAvailableHumanBuildTemplatesBySlot(nCharacterInstanceId, BattleItemCategoryDef.HUMAN_ARMOR, i, true)
        if tbBuildDatas == nil or #tbBuildDatas == 0 then
            bHasEmptySlot = true
            NoBuildItem(self, i)
        else
            RefreshBuildHumanArmorOnOneSlot(self, i, EquippedArmor, tbBuildDatas)
        end
    end
    RefreshHumanArmorNote(self, bHasEmptySlot)
end

function ULBuildHumanArmor:OnLoad()
    self.tbPbBuildHumanArmors = {}
    self.OnBuildHumanArmorPressedDelegate = LuaDelegateClass()

    local pWidgetRef = self.pWidgetRef

    for i = 1, SLOT_MAX do
        for j = 1, GRADE_MAX do
            local pbBuildHumanArmor = self.PrefabHelper:BindPrefab(pWidgetRef["pbHumanArmor"..i.."_"..j], UIDef.UP_BUILD_ITEM)
            pbBuildHumanArmor:SetOnItemPressedDelegate(self.OnBuildHumanArmorPressedDelegate, i, j)
            pbBuildHumanArmor:Collaped()
            AddPbBuildHumanArmor(self, i, j, pbBuildHumanArmor)
        end
    end
end

function ULBuildHumanArmor:OnUnload()
end

function ULBuildHumanArmor:OnBindEvent(EventHelper)
    EventHelper:RegisterLuaDelegate(self.OnBuildHumanArmorPressedDelegate, OnHumanArmorSelected, self)
end

function ULBuildHumanArmor:Refresh()
    self.Owner:CloseTips()
    RefreshHumanArmor(self)
    SetAllItemUnSelected(self)
end

return ULBuildHumanArmor
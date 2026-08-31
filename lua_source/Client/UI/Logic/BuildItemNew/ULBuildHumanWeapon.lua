-----------------------------------------------------
--File Name    : ULBuildHumanWeapon.lua
--Author       : zhiyuan
--Create Time  : 2019-09-16
--Description  : 建造人的武器的UI逻辑
-----------------------------------------------------
local luaclass = require("luaclass")
local UILogicBase = require("UILogicBase")
local ULBuildHumanWeapon = luaclass("ULBuildHumanWeapon", UILogicBase)

local UIDef = require("UIDef")
local LuaDelegateClass = require("LuaDelegate")
local GamePlayerSelfHelper = require("GamePlayerSelfHelper")
local BattleItemCategoryDef = require("BattleItemCategoryDef")
local BattleItemSystemHelper = require("BattleItemSystemHelper")

ULBuildHumanWeapon.tbPbBuildHumanWeapons = nil
ULBuildHumanWeapon.OnBuildHumanWeaponPressedDelegate = nil

local SLOT_MAX = 2
local GRADE_MAX = 3

local function SetItemSelected(self, nPos1, nPos2)
    for i, v1 in pairs(self.tbPbBuildHumanWeapons) do
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
    for i, v1 in pairs(self.tbPbBuildHumanWeapons) do
        for j, v2 in pairs(v1) do
            v2:SetSelected(false)
        end
    end
end

local function OnHumanWeaponSelected(self, pbBuildItem)
    if pbBuildItem:IsSetSelected() then
        self.Owner:CloseTips()
        pbBuildItem:SetSelected(false)
    else
        self.Owner:ShowBuildItemTipsNew(pbBuildItem:GetTemplateId(), pbBuildItem:GetPos1())
        SetItemSelected(self, pbBuildItem:GetPos1(), pbBuildItem:GetPos2())
    end
end

local function AddPbBuildHumanWeapon(self, nSubCategory, nGrade, pbBuildHumanWeapon)
    local tbPbs = self.tbPbBuildHumanWeapons[nSubCategory]
    if tbPbs == nil then
        self.tbPbBuildHumanWeapons[nSubCategory] = {}
        tbPbs = self.tbPbBuildHumanWeapons[nSubCategory]
    end
    tbPbs[nGrade] = pbBuildHumanWeapon
end

local function GetPbBuildHumanWeapon(self, nSubCategory, nGrade)
    local tbPbs = self.tbPbBuildHumanWeapons[nSubCategory]
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
    pWidgetRef["sboxHumanWeapon"..nSlot]:SetVisibility(ESlateVisibility.Collapsed)
    pWidgetRef["ovlLackWeapon"..nSlot]:SetVisibility(ESlateVisibility.SelfHitTestInvisible)
end

local function RefreshBuildHumanWeaponOnOneSlot(self, nSlot, tbBuildDatas, EquippedWeapon)
    local pWidgetRef = self.pWidgetRef
    pWidgetRef["ovlLackWeapon"..nSlot]:SetVisibility(ESlateVisibility.Collapsed)
    pWidgetRef["sboxHumanWeapon"..nSlot]:SetVisibility(ESlateVisibility.SelfHitTestInvisible)
    for _, v in pairs(tbBuildDatas) do
        local tbItemTemplate = v.tbBattleItemTemplate
        local pbBuildHumanWeapon = GetPbBuildHumanWeapon(self, nSlot, tbItemTemplate.nGrade)

        local bIsCurrent = false
        if EquippedWeapon and EquippedWeapon:GetTemplateId() == tbItemTemplate.nId then
            bIsCurrent = true
        end

        pbBuildHumanWeapon:Refresh(tbItemTemplate, bIsCurrent)
    end
end

local function RefreshHumanWeaponNote(self, bHasEmptySlot)
    local txtHumanWeaponNote = self.pWidgetRef.txtHumanWeaponNote
    if bHasEmptySlot then
        txtHumanWeaponNote:SetVisibility(ESlateVisibility.SelfHitTestInvisible)
    else
        txtHumanWeaponNote:SetVisibility(ESlateVisibility.Collapsed)
    end
end

local function RefreshHumanWeapon(self)
    local nCharacterInstanceId = GamePlayerSelfHelper:GetServerInstanceId()
    local bHasEmptySlot = false
    for i = 1, SLOT_MAX do
        local tbBuildDatas, EquippedWeapon = BattleItemSystemHelper:GetAvailableHumanBuildTemplatesBySlot(nCharacterInstanceId, BattleItemCategoryDef.HUMAN_WEAPON, i, true)
        if tbBuildDatas == nil or #tbBuildDatas == 0 then
            bHasEmptySlot = true
            NoBuildItem(self, i)
        else
            RefreshBuildHumanWeaponOnOneSlot(self, i, tbBuildDatas, EquippedWeapon)
        end
    end
    RefreshHumanWeaponNote(self, bHasEmptySlot)
end

function ULBuildHumanWeapon:OnLoad()
    self.tbPbBuildHumanWeapons = {}
    self.OnBuildHumanWeaponPressedDelegate = LuaDelegateClass()

    local pWidgetRef = self.pWidgetRef

    for i = 1, SLOT_MAX do
        for j = 1, GRADE_MAX do
            local pbBuildHumanWeapon = self.PrefabHelper:BindPrefab(pWidgetRef["pbHumanWeapon"..i.."_"..j], UIDef.UP_BUILD_ITEM)
            pbBuildHumanWeapon:SetOnItemPressedDelegate(self.OnBuildHumanWeaponPressedDelegate, i, j)
            pbBuildHumanWeapon:Collaped()
            AddPbBuildHumanWeapon(self, i, j, pbBuildHumanWeapon)
        end
    end
end

function ULBuildHumanWeapon:OnUnload()
end

function ULBuildHumanWeapon:OnBindEvent(EventHelper)
    EventHelper:RegisterLuaDelegate(self.OnBuildHumanWeaponPressedDelegate, OnHumanWeaponSelected, self)
end

function ULBuildHumanWeapon:Refresh()
    self.Owner:CloseTips()
    RefreshHumanWeapon(self)
    SetAllItemUnSelected(self)
end

return ULBuildHumanWeapon
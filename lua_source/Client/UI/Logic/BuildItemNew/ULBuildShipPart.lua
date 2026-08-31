-----------------------------------------------------
--File Name    : ULBuildShipPartNew.lua
--Author       : zhiyuan
--Create Time  : 2019-03-12
--Description  : 建造船零件的UI逻辑
-----------------------------------------------------
local luaclass = require("luaclass")
local UILogicBase = require("UILogicBase")
local ULBuildShipPartNew = luaclass("ULBuildShipPartNew", UILogicBase)

local LuaDelegateClass = require("LuaDelegate")
local UIDef = require("UIDef")
local ShipPartTypeDef = require("ShipPartTypeDef")
local BattleItemSystemHelper = require("BattleItemSystemHelper")
local BattleItemCategoryDef = require("BattleItemCategoryDef")
local GamePlayerSelfHelper = require("GamePlayerSelfHelper")
local BattleItemSystemClient = require("BattleItemSystemClient")

local SUB_CATEGORY_MAX = ShipPartTypeDef.Max
local GRADE_MAX = 3

ULBuildShipPartNew.tbPbBuildShipParts = nil
ULBuildShipPartNew.OnBuildShipPartPressedDelegate = nil

local function SetItemSelected(self, nPos1, nPos2)
    for i, v1 in pairs(self.tbPbBuildShipParts) do
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
    for i, v1 in pairs(self.tbPbBuildShipParts) do
        for j, v2 in pairs(v1) do
            v2:SetSelected(false)
        end
    end
end

local function GetEquippedPart(nSlotIndex)
    local nCharacterInstanceId = GamePlayerSelfHelper:GetServerInstanceId()
    return BattleItemSystemClient:GetEquippedItem(BattleItemCategoryDef.SHIP_PART, nCharacterInstanceId, nSlotIndex)
end

local function OnShipPartSelected(self, pbBuildItem)
    if pbBuildItem:IsSetSelected() then
        self.Owner:CloseTips()
        pbBuildItem:SetSelected(false)
    else
        self.Owner:ShowBuildItemTips(pbBuildItem:GetTemplateId())
        SetItemSelected(self, pbBuildItem:GetPos1(), pbBuildItem:GetPos2())
    end
end

local function AddPbBuildShipPart(self, nSubCategory, nGrade, pbBuildShipPart)
    local tbPbs = self.tbPbBuildShipParts[nSubCategory]
    if tbPbs == nil then
        self.tbPbBuildShipParts[nSubCategory] = {}
        tbPbs = self.tbPbBuildShipParts[nSubCategory]
    end
    tbPbs[nGrade] = pbBuildShipPart
end

local function GetPbBuildShipPart(self, nSubCategory, nGrade)
    local tbPbs = self.tbPbBuildShipParts[nSubCategory]
    if tbPbs == nil then
        error("Cannot find prefab!", nSubCategory, nGrade)
    end
    local tbPb = tbPbs[nGrade]
    if tbPb == nil then
        error("Cannot find prefab!", nSubCategory, nGrade)
    end
    return tbPb
end

local function RefreshShipParts(self)
    local nCharacterInstanceId = GamePlayerSelfHelper:GetServerInstanceId()
    local tbBuildDatas = BattleItemSystemHelper.GetAvailableBuildTemplatesByCategory(nCharacterInstanceId, BattleItemCategoryDef.SHIP_PART, true)
    if tbBuildDatas == nil then
        return
    end
    for _, v in pairs(tbBuildDatas) do
        local tbItemTemplate = v.tbBattleItemTemplate
        local nSubCategory = tbItemTemplate.nSubCategory
        local pbBuildShipPart = GetPbBuildShipPart(self, nSubCategory, tbItemTemplate.nGrade)

        local EquippedPart = GetEquippedPart(nSubCategory)
        local bIsCurrent = false
        if EquippedPart and EquippedPart:GetTemplateId() == tbItemTemplate.nId then
            bIsCurrent = true
        end

        pbBuildShipPart:Refresh(tbItemTemplate, bIsCurrent)
    end
end

function ULBuildShipPartNew:OnLoad()
    self.tbPbBuildShipParts = {}
    self.OnBuildShipPartPressedDelegate = LuaDelegateClass()

    local pWidgetRef = self.pWidgetRef

    for i = 1, SUB_CATEGORY_MAX do
        for j = 1, GRADE_MAX do
            local pbBuildShipPart = self.PrefabHelper:BindPrefab(pWidgetRef["pbShipPart"..i.."_"..j], UIDef.UP_BUILD_ITEM)
            pbBuildShipPart:SetOnItemPressedDelegate(self.OnBuildShipPartPressedDelegate, i, j)
            pbBuildShipPart:Collaped()
            AddPbBuildShipPart(self, i, j, pbBuildShipPart)
        end
    end
end

function ULBuildShipPartNew:OnUnload()

end

function ULBuildShipPartNew:OnBindEvent(EventHelper)
    EventHelper:RegisterLuaDelegate(self.OnBuildShipPartPressedDelegate, OnShipPartSelected, self)
end

function ULBuildShipPartNew:Refresh()
    self.Owner:CloseTips()
    RefreshShipParts(self)
    SetAllItemUnSelected(self)
end

return ULBuildShipPartNew
-----------------------------------------------------
--File Name    : UPBuildingCostMaterials.lua
--Author       : zhiyuan
--Create Time  : 2018-09-29
--Description  : 物品建造消耗的up
-----------------------------------------------------
local luaclass = require ("luaclass")
local PrefabBase = require("PrefabBase")
local UPBuildingCostMaterials = luaclass("UPBuildingCostMaterials", PrefabBase)
local UIDef = require("UIDef")
local FFAItemIni = require("FFAItemIni")
local GamePlayerSelfHelper = require("GamePlayerSelfHelper")
local BattleItemSystemHelper = require("BattleItemSystemHelper")
local BattleItemSystemClient = require("BattleItemSystemClient")
local MaterialItemHelper = require("MaterialItemHelper")
local UIResourceDef = require("UIResourceDef")

UPBuildingCostMaterials.tbPbMaterials = nil

UPBuildingCostMaterials.OnItemButtonPressedDelegate = nil
UPBuildingCostMaterials.OnItemButtonReleasedDelegate = nil

function UPBuildingCostMaterials:OnLoad()
    -- Bind material cost prefabs.
    local pWidgetRef =self.pWidgetRef
    self.tbPbMaterials = {}
    local tbPbMaterials = self.tbPbMaterials
    for i = 1, FFAItemIni.tbMaterial.nMaxMaterialType do
        local pbMaterial = self.PrefabHelper:BindPrefab(pWidgetRef["pbBuildMaterial0"..i], UIDef.UP_BUILDING_MATERIAL)
        tbPbMaterials[i] = pbMaterial
    end
end

function UPBuildingCostMaterials:Refresh(tbItemBuildTemplate)
    local pWidgetRef = self.pWidgetRef
    if not tbItemBuildTemplate then
        pWidgetRef:SetVisibility(ESlateVisibility.Collapsed)
        return
    end

    pWidgetRef:SetVisibility(ESlateVisibility.Visible)
    local tbPlayer = GamePlayerSelfHelper:Get()
    local tbCosts, _ = BattleItemSystemHelper:GetBuildMaterialCost(tbPlayer.nServerInstanceId, tbItemBuildTemplate.nId, true)
    for i, v in ipairs(self.tbPbMaterials) do
        local nNeedCount = tbCosts[i]
        local nMaterialTemplateId = MaterialItemHelper:GetMaterialTemplateId(i)
        local nMaterialCount = BattleItemSystemClient:GetUnequippedItemCount(nMaterialTemplateId)
        if nMaterialCount >= nNeedCount then
            v:Refresh(i, nNeedCount)
        else
            v:Refresh(i, nNeedCount, UIResourceDef.COLOR.RED.LINEAR_COLOR)
        end
    end
end

function UPBuildingCostMaterials:SetOnItemButtonPressedDelegate(OnItemButtonPressedDelegate)
    self.OnItemButtonPressedDelegate = OnItemButtonPressedDelegate
    for _, v in ipairs(self.tbPbMaterials) do
        v:SetOnItemButtonPressedDelegate(OnItemButtonPressedDelegate)
    end
end

function UPBuildingCostMaterials:SetOnItemButtonReleasedDelegate(OnItemButtonReleasedDelegate)
    self.OnItemButtonReleasedDelegate = OnItemButtonReleasedDelegate
    for _, v in ipairs(self.tbPbMaterials) do
        v:SetOnItemButtonReleasedDelegate(OnItemButtonReleasedDelegate)
    end
end

return UPBuildingCostMaterials

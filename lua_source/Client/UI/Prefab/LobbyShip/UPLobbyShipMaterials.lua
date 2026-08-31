-----------------------------------------------------
--File Name    : UPLobbyShipMaterials.lua
--Author       : Song Fuhao
--Create Time  : 2019-03-20
--Description  : 舰船零件建造材料
-----------------------------------------------------
local luaclass = require("luaclass")
local PrefabBase = require("PrefabBase")
local UPLobbyShipMaterials = luaclass("UPLobbyShipMaterials", PrefabBase)

local UISetUtils = require("UISetUtils")
local MaterialItemHelper = require("MaterialItemHelper")
local BattleItemDataTable = require("BattleItemDataTable")
local BattleItemBuildDataTable = require("BattleItemBuildDataTable")

local MATERIAL_COUNT = 4

local function UpdateKeyItem(self, tbKeyItemIds)
    if tbKeyItemIds then
        self.pWidgetRef.cvsKeyItem:SetVisibility(ESlateVisibility.SelfHitTestInvisible)
    else
        self.pWidgetRef.cvsKeyItem:SetVisibility(ESlateVisibility.Collapsed)
    end
end

local function UpdateMaterialCount(self, tbCosts)
    for i, v in ipairs(tbCosts) do
        self.pWidgetRef["txtMaterialCount_"..i]:SetText(tbCosts[i])
    end
end

local function InitMaterialIcon(self)
    for i = 1, MATERIAL_COUNT do
        local nTemplateId = MaterialItemHelper:GetMaterialTemplateId(i)
        local tbItemTemplate = BattleItemDataTable:GetTemplate(nTemplateId)
        UISetUtils.SetButtonBrushRes(self.pWidgetRef["btnMaterial_"..i], tbItemTemplate.szMaterialBarUiIcon:load())
    end
end

function UPLobbyShipMaterials:OnLoad()
    InitMaterialIcon(self)
end

function UPLobbyShipMaterials:SetBuildId(nBuildId)
    local tbTemplate = BattleItemBuildDataTable:GetBuildTemplate(nBuildId)
    if not tbTemplate then
        tbTemplate = {
            tbCosts = {0,0,0,0}
        }
    end
    UpdateKeyItem(self, tbTemplate.tbKeyItemIds)
    UpdateMaterialCount(self, tbTemplate.tbCosts)
end

return UPLobbyShipMaterials
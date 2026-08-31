-----------------------------------------------------
--File Name    : UPBuildingMaterial.lua
--Author       : Xu Weihua
--Create Time  : 2018-09-18
--Description  : The ship building material UI element.
-----------------------------------------------------
local luaclass = require ("luaclass")
local PrefabBase = require("PrefabBase")
local UPBuildingMaterial = luaclass("UPBuildingMaterial", PrefabBase)

local MaterialItemHelper = require("MaterialItemHelper")
local BattleItemDataTable = require("BattleItemDataTable")
local UISetUtils = require("UISetUtils")
local UIResourceDef = require("UIResourceDef")

UPBuildingMaterial.OnItemButtonPressedDelegate = nil
UPBuildingMaterial.OnItemButtonReleasedDelegate = nil

UPBuildingMaterial.nItemTemplateId = nil

function UPBuildingMaterial:RefreshCount(nCount)
    local pWidgetRef = self.pWidgetRef
    local txtCount = pWidgetRef.txtCount
    txtCount:SetText(nCount)
end


function UPBuildingMaterial:Refresh(nMaterialIndex, nCount, Color)
    local pWidgetRef = self.pWidgetRef
    assert(nMaterialIndex > 0, "Invalid material type index!")

    local nTemplateId = MaterialItemHelper:GetMaterialTemplateId(nMaterialIndex)
    self.nItemTemplateId = nTemplateId
    local tbItemTemplate = BattleItemDataTable:GetTemplate(nTemplateId)

    pWidgetRef:SetVisibility(ESlateVisibility.Visible)
    local txtCount = pWidgetRef.txtCount
    txtCount:SetText(nCount)
    if Color then
        txtCount:SetColorAndOpacity(Color)
    else
        txtCount:SetColorAndOpacity(UIResourceDef.COLOR.WHITE.LINEAR_COLOR)
    end
    UISetUtils.SetButtonBrushRes(pWidgetRef.btnMaterial, tbItemTemplate.szMaterialBarUiIcon:load())
end

function UPBuildingMaterial:SetOnItemButtonPressedDelegate(OnItemButtonPressedDelegate)
    self.OnItemButtonPressedDelegate = OnItemButtonPressedDelegate
end

function UPBuildingMaterial:SetOnItemButtonReleasedDelegate(OnItemButtonReleasedDelegate)
    self.OnItemButtonReleasedDelegate = OnItemButtonReleasedDelegate
end

local function OnItemButtonPressed(self)
    if self.OnItemButtonPressedDelegate then
        self.OnItemButtonPressedDelegate:Fire(self.nItemTemplateId, self.pWidgetRef.btnMaterial)
    end
end

local function OnItemButtonReleased(self)
    if self.OnItemButtonReleasedDelegate then
        self.OnItemButtonReleasedDelegate:Fire()
    end
end

function UPBuildingMaterial:OnBindEvent(EventHelper)
    local pWidgetRef =self.pWidgetRef
    EventHelper:RegisterCppDelegate(pWidgetRef.btnMaterial.OnPressed, self, OnItemButtonPressed)
    EventHelper:RegisterCppDelegate(pWidgetRef.btnMaterial.OnReleased, self, OnItemButtonReleased)
end

return UPBuildingMaterial

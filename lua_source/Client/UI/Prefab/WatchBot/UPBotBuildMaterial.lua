local luaclass = require ("luaclass")
local PrefabBase = require("PrefabBase")
local UPBotBuildMaterial = luaclass("UPBotBuildMaterial", PrefabBase)

local MaterialItemHelper = require("MaterialItemHelper")
local BattleItemDataTable = require("BattleItemDataTable")
local UISetUtils = require("UISetUtils")
local UIResourceDef = require("UIResourceDef")

UPBotBuildMaterial.OnItemButtonPressedDelegate = nil
UPBotBuildMaterial.OnItemButtonReleasedDelegate = nil

UPBotBuildMaterial.nItemTemplateId = nil

function UPBotBuildMaterial:Refresh(nMaterialIndex, nCount, Color)
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

function UPBotBuildMaterial:OnBindEvent(EventHelper)
end

return UPBotBuildMaterial

local luaclass = require ("luaclass")
local PrefabBase = require("PrefabBase")
local UPBotBuildingMaterials = luaclass("UPBotBuildingMaterials", PrefabBase)
local UIDef = require("UIDef")
local MaterialItemHelper = require("MaterialItemHelper")
local FFAItemIni = require("FFAItemIni")

UPBotBuildingMaterials.tbPbMaterials = nil

function UPBotBuildingMaterials:OnLoad()
    local pWidgetRef =self.pWidgetRef
    self.tbPbMaterials = {}
    local tbPbMaterials = self.tbPbMaterials
    for i = 1, FFAItemIni.tbMaterial.nMaxMaterialType do
        local pbMaterial = self.PrefabHelper:BindPrefab(pWidgetRef["pbBuildMaterial0"..i], UIDef.UP_BOT_BUILD_MATERIAL)
        tbPbMaterials[i] = pbMaterial
    end
    pWidgetRef:SetVisibility(ESlateVisibility.Visible)
end

function UPBotBuildingMaterials:OnShow()
end

function UPBotBuildingMaterials:OnBindEvent(EventHelper)
end

function UPBotBuildingMaterials:RefreshMaterials(tbBackPacks)
    local tbItems = tbBackPacks.items  
    if tbItems ~= nil then   
        for i = 1, FFAItemIni.tbMaterial.nMaxMaterialType do
            local nTemplateId = MaterialItemHelper:GetMaterialTemplateId(i)
            local nCount = 0  
            for _, v in pairs(tbItems) do  
                if nTemplateId == v.templateid then   
                    nCount = v.count
                end
            end
            self.tbPbMaterials[i]:Refresh(i, nCount)
        end
    end
end

return UPBotBuildingMaterials

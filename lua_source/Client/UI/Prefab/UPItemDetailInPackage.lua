-----------------------------------------------------
--File Name    : UPItemDetailInPackage.lua
--Author       : WuJizhou
--Create Time  : 9/14/2018, 2:51:42 PM
--Description  : UPItemDetailInPackage
-----------------------------------------------------
local luaclass = require("luaclass")
local PrefabBase = require("PrefabBase")

local UPItemDetailInPackage = luaclass("UPItemDetailInPackage", PrefabBase)
local BattleItemResDataTable = require("BattleItemResDataTable")
local BattleResultServerIni = require("BattleResultServerIni")
local UISetUtils = require("UISetUtils")
local L10N = require("L10N")
local GlobalVariableSystem = dynamic_require("GlobalVariableSystem")

----------public------------

function UPItemDetailInPackage:ShowDetail(tbTemplate, nCount)
    local pWidgetRef = self.pWidgetRef

    local tbResTemplate = BattleItemResDataTable:GetTemplate(tbTemplate.nResId)
    local szRes = tbResTemplate.szIconPath
    local pRes = szRes:load()
    UISetUtils.SetButtonBrushRes(pWidgetRef.btnBlueprintItem, pRes)

    pWidgetRef.txtName:SetText(tbTemplate.l10nName)
    if tbTemplate.nId == BattleResultServerIni.nRusultEquipLevelupItem then  
        pWidgetRef.txtDesc:SetText(L10N:Format(tbTemplate.l10nDesc, string.format("%.0f", BattleResultServerIni.nDeadLossPercent * 100)))
    else  
        pWidgetRef.txtDesc:SetText(tbTemplate.l10nDetailedDesc)
    end

    if GlobalVariableSystem:IsFFAPackageUseWeight() then 
        local nWeight = tbTemplate.nWeight
        local nTotoalCapacity = nCount * nWeight
        local nFloorValue = math.floor(nTotoalCapacity)
        nTotoalCapacity = nTotoalCapacity == nFloorValue and nFloorValue or nTotoalCapacity
        pWidgetRef.txtCapacity:SetText(L10N:Format(UISetUtils.GetL10NTextByKey("UI_CAPACITY"), nTotoalCapacity, nWeight, nCount))
        pWidgetRef.txtCapacity:SetVisibility(ESlateVisibility.SelfHitTestInvisible)
    else
        pWidgetRef.txtCapacity:SetVisibility(ESlateVisibility.Hidden)
    end
    pWidgetRef:SetVisibility(ESlateVisibility.Visible)
end

function UPItemDetailInPackage:HideDetail()
    self.pWidgetRef:SetVisibility(ESlateVisibility.Collapsed)
end


----------life cycle----------
-- function UPItemDetailInPackage:OnCreate()
-- end

-- function UPItemDetailInPackage:OnDestroy()
-- end

-- function UPItemDetailInPackage:OnLoad()
-- end

-- function UPItemDetailInPackage:OnUnload()
-- end

-- function UPItemDetailInPackage:OnEnter()
-- end

-- function UPItemDetailInPackage:OnShow()
-- end

-- function UPItemDetailInPackage:OnHide()
-- end

-- function UPItemDetailInPackage:OnExit()
-- end

-- function UPItemDetailInPackage:OnBindEvent( EventHelper )
-- end

-- function UPItemDetailInPackage:OnUnbindEvent( EventHelper )
-- end

return UPItemDetailInPackage
local luaclass = require ("luaclass")
local PrefabBase = require("PrefabBase")
local UPFiveDimensionalGraph = luaclass("UPFiveDimensionalGraph", PrefabBase)
local UISetUtils = require("UISetUtils")

local DIMENSIONAL_COUNT = 5
local SINGLE_MODE = 1

local SCALAR_PARAMETER = {
    "a",
    "e",
    "b",
    "d",
    "c",
}

-- 生存，伤害，击败，支援，物资
function UPFiveDimensionalGraph:OnRefresh(tbDimensionalUnit, nMode)
    if tbDimensionalUnit == nil or #tbDimensionalUnit ~= DIMENSIONAL_COUNT then
        logwarning("UPFiveDimensionalGraph:OnRefresh failed: ", tbDimensionalUnit and #tbDimensionalUnit)
        return
    end
    local pWidgetRef = self.pWidgetRef
    local DynMaterial = pWidgetRef.imgFiveDim:GetDynamicMaterial()
    for i = 1, DIMENSIONAL_COUNT do
        pWidgetRef["txt0"..i]:SetText(string.format("%.1f", tbDimensionalUnit[i]))
        DynMaterial:SetScalarParameterValue(SCALAR_PARAMETER[i], tbDimensionalUnit[i] / 100)
    end

    nMode = nMode or SINGLE_MODE
    local l10n
    
    if nMode > SINGLE_MODE then
        l10n = UISetUtils.GetL10NTextByKey("UI_MULTIPLE_ASSIST")
    else
        l10n = UISetUtils.GetL10NTextByKey("UI_SINGLE_ASSIST")
    end
    pWidgetRef.txtTitle04:SetText(l10n)
end

return UPFiveDimensionalGraph
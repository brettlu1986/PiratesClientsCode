-----------------------------------------------------
--File Name    : AbilityAction_MaterialCollector.lua
--Author       : Song Fuhao
--Create Time  : 2018-10-10
--Description  :
-----------------------------------------------------
local luaclass = require("luaclass")
local AbilityActionPropBase = require("AbilityActionPropBase")
local AbilityAction_MaterialCollector = luaclass("AbilityAction_MaterialCollector", AbilityActionPropBase)

local PropName = require("PropName")
local PropertyWrapperType = require("PropertyWrapperType")

function AbilityAction_MaterialCollector:GetWrapperName()
    return PropName.tbMaterialCollector
end

function AbilityAction_MaterialCollector:GetOverlapType()
    return PropertyWrapperType.TYPE_OVERRIDE
end

function AbilityAction_MaterialCollector:GetValue()
    local tbMaterialCollector = {}
    local tbInitParams = self.tbInitParams
    for i,v in ipairs(tbInitParams.IdList) do
        tbMaterialCollector[v] = {
            nCount = tbInitParams.CountList[i],
            nMaxCount = tbInitParams.MaxCountList[i]
        }
    end
    return tbMaterialCollector
end

return AbilityAction_MaterialCollector
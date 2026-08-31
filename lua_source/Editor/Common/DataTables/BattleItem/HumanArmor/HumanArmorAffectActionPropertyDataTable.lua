-----------------------------------------------------
--File Name    : HumanArmorAffectActionPropertyDataTable.lua
--Author       : WuJizhou
--Create Time  : 3/26/2020, 5:38:01 PM
--Description  : HumanArmorAffectActionPropertyDataTable
-----------------------------------------------------
local HumanArmorAffectActionPropertyDataTable = {}

local HumanArmorDef = require("HumanArmorDef")
local ArmorAffectHumanActionPropertyDef = HumanArmorDef.ArmorAffectHumanActionPropertyDef
local ArmorAffectActionDef = HumanArmorDef.ArmorAffectActionDef

HumanArmorAffectActionPropertyDataTable.szFileName = "common/ffa/item/human_armor/affect_action_property.tab"

local MAX_AFFECT_PROPERTY_COUNT = 5

function HumanArmorAffectActionPropertyDataTable:OnEditorDefine(Parser)
    Parser:SetKey("nId")
    Parser:Define("nId", "id", -1, Parser.TypeInt)

end

function HumanArmorAffectActionPropertyDataTable:OnEditorParseLine(Parser, tbContainer, tbNewTemplate)
    local tbProperty = tbNewTemplate.tbProperty
    if tbProperty == nil then
        tbProperty = {}
        tbNewTemplate.tbProperty = tbProperty
    end

    for i = 1, MAX_AFFECT_PROPERTY_COUNT do
        local szProperty = Parser:Get("prop_" .. i, "", Parser.TypeString)
        if szProperty ~= "" then
            local szPropName = ArmorAffectHumanActionPropertyDef[szProperty]
            if not szPropName then
                error("Property invalid, value : ".. szProperty)
            end
            local szAction = Parser:Get("action_" .. i, "", Parser.TypeString)
            local nAction = ArmorAffectActionDef[szAction]
            if not nAction then
                error("Action invalid, value : ".. szAction)
            end
            local nValue = Parser:Get("value_" .. i, "", Parser.TypeFloat)
            local tbAfffect = {szPropName, nAction, nValue}
            table.insert(tbProperty, tbAfffect)
        end
    end

    return true
end

-- [EXPORT BEGIN]
--return list
function HumanArmorAffectActionPropertyDataTable:GetAffectProperties(nId)
    local tbTemplate = self.tbContainer[nId]
    return tbTemplate.tbProperty
end
-- [EXPORT END]

return HumanArmorAffectActionPropertyDataTable
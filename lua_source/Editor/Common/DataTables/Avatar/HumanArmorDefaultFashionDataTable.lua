-----------------------------------------------------
--File Name    : HumanArmorDefaultFashionDataTable.lua
--Author       : WuJizhou
--Create Time  : 4/1/2020, 8:57:33 PM
--Description  : HumanArmorDefaultFashionDataTable
-----------------------------------------------------
local HumanArmorDefaultFashionDataTable = {}

local HumanAvatarDef = require("HumanAvatarDef")
local FashionSlotCategoryToConfigName = HumanAvatarDef.FashionSlotCategoryToConfigName

HumanArmorDefaultFashionDataTable.szFileName = "common/avatar/human/human_armor_default_fashion.tab"


function HumanArmorDefaultFashionDataTable:OnEditorDefine(Parser)
    Parser:Define("nArmorType",       "armor_type",          -1,  Parser.TypeInt)
end

function HumanArmorDefaultFashionDataTable:OnEditorParseLine(Parser, tbContainer, tbNewTemplate)
    local tbData = {}
    local nArmorType = tbNewTemplate.nArmorType
    tbContainer[nArmorType] = tbData
    for nSlotType, szConfigName in pairs(FashionSlotCategoryToConfigName) do
        local nValue = Parser:Get(szConfigName, nil, Parser.TypeInt, false)
        if nValue then
            tbData[nSlotType] = nValue
        end
    end
    return true
end

-- [EXPORT BEGIN]
--return table, {key: HumanAvatarDef.SlotType, value : fashion id}
function HumanArmorDefaultFashionDataTable:GetFashions(nArmorType)
    local tbRet = self.tbContainer[nArmorType]
    return tbRet == nil and {} or tbRet
end
-- [EXPORT END]

return HumanArmorDefaultFashionDataTable
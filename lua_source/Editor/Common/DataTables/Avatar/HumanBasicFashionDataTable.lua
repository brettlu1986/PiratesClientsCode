-----------------------------------------------------
--File Name    : HumanBasicFashionDataTable.lua
--Author       : WuJizhou
--Create Time  : 4/1/2020, 8:57:33 PM
--Description  : HumanBasicFashionDataTable
-----------------------------------------------------
local HumanBasicFashionDataTable = {}

local HumanAvatarDef = require("HumanAvatarDef")
local PartTypeToConfigName = HumanAvatarDef.PartTypeToConfigName

HumanBasicFashionDataTable.szFileName = "common/avatar/human/human_basic_fashions.tab"


function HumanBasicFashionDataTable:OnEditorDefine(Parser)
    Parser:Define("nFashionId",       "fashion_id",          -1,  Parser.TypeInt)
end

function HumanBasicFashionDataTable:OnEditorParseLine(Parser, tbContainer, tbNewTemplate)
    local nFashionId = tbNewTemplate.nFashionId
    local tbPartMap = tbContainer[nFashionId]
    if not tbPartMap then
        tbPartMap = {}
        tbContainer[nFashionId] = tbPartMap
    end

    for nPartType, szConfigName in pairs(PartTypeToConfigName) do
        local nValue = Parser:Get(szConfigName, -1, Parser.TypeInt, false)
        if nValue then
            tbPartMap[nPartType] = nValue   -- 除了颜色的，这个值为partid，颜色的是colorid
        end
    end
    return true
end

-- [EXPORT BEGIN]
--return table, {key: HumanAvatarDef.PartType, value : part id/ color id}
function HumanBasicFashionDataTable:GetFashionDatas(nFashionId)
    local tbRet = self.tbContainer[nFashionId]
    if tbRet then
        return tbRet
    end
    return {}
end
-- [EXPORT END]

return HumanBasicFashionDataTable
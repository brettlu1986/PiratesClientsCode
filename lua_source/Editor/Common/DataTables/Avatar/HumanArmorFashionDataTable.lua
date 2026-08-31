-----------------------------------------------------
--File Name    : HumanArmorFashionDataTable.lua
--Author       : WuJizhou
--Create Time  : 4/1/2020, 8:57:33 PM
--Description  : HumanArmorFashionDataTable
-----------------------------------------------------
local HumanArmorFashionDataTable = {}

local HumanAvatarDef = require("HumanAvatarDef")
local PartTypeToConfigName = HumanAvatarDef.PartTypeToConfigName

HumanArmorFashionDataTable.szFileName = "common/avatar/human/human_armor_fashions.tab"


function HumanArmorFashionDataTable:OnEditorDefine(Parser)
    Parser:Define("nFashionId",       "fashion_id",          -1,  Parser.TypeInt)
    Parser:Define("nLevel",           "level", -1,  Parser.TypeInt)
end

function HumanArmorFashionDataTable:OnEditorParseLine(Parser, tbContainer, tbNewTemplate)
    local nFashionId = tbNewTemplate.nFashionId
    local tbLevelMap = tbContainer[nFashionId]
    if not tbLevelMap then
        tbLevelMap = {}
        tbContainer[nFashionId] = tbLevelMap
    end
    local nLevel = tbNewTemplate.nLevel
    if tbLevelMap[nLevel] then
        error(string.format("level already exist! the fashion id is %d, level is %d", nFashionId, nLevel))
        return
    end
    local tbPartMap = {}
    tbLevelMap[nLevel] = tbPartMap
    for nPartType, szConfigName in pairs(PartTypeToConfigName) do
        local nValue = Parser:Get(szConfigName, -1, Parser.TypeInt, false)
        if nValue then
            tbPartMap[nPartType] = nValue   -- 除了颜色的，这个值为partid; 颜色的是colorid; 0表示占位，占位对初新装层不生效
        end
    end
    return true
end

-- [EXPORT BEGIN]
--return table, {key: HumanAvatarDef.PartType, value : part id/ color id}
function HumanArmorFashionDataTable:GetFashions(nFashionId, nLevel)
    local tbLevelMap = self.tbContainer[nFashionId]
    if tbLevelMap and nLevel then
        return tbLevelMap[nLevel] == nil and {} or tbLevelMap[nLevel]
    end
    return {}
end

function HumanArmorFashionDataTable:GetFashionDatas(nFashionId)
    local tbLevelMap = self.tbContainer[nFashionId]
    if tbLevelMap  then
        return tbLevelMap
    end
    return {}
end
-- [EXPORT END]

return HumanArmorFashionDataTable
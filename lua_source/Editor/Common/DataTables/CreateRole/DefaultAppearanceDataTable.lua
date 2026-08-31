-----------------------------------------------------
--File Name    : DefaultAppearanceDataTable.lua
--Author       : WuJizhou
--Create Time  : 4/1/2020, 8:57:33 PM
--Description  : DefaultAppearanceDataTable
-----------------------------------------------------
local DefaultAppearanceDataTable = {}

local HumanAvatarDef = require("HumanAvatarDef")
local PartTypeToConfigName = HumanAvatarDef.PartTypeToConfigName

DefaultAppearanceDataTable.szFileName = "common/createrole/default_appearance.tab"


function DefaultAppearanceDataTable:OnEditorDefine(Parser)
    Parser:SetKey("nId")

    Parser:Define("nId",          "id",          -1,  Parser.TypeInt)
    Parser:Define("nGender",      "gender",      -1,  Parser.TypeInt)
    Parser:Define("nType",        "type",        -1,  Parser.TypeInt)
    Parser:Define("szMaleIcon",   "icon_male",   "",  Parser.TypeString)
    Parser:Define("szFemaleIcon", "icon_female", "",  Parser.TypeString)
end

function DefaultAppearanceDataTable:OnEditorParseLine(Parser, tbContainer, tbNewTemplate)
    local tbData = {}
    for nPartType, szConfigName in pairs(PartTypeToConfigName) do
        local nValue = Parser:Get(szConfigName, nil, Parser.TypeInt, false)
        if nValue then
            tbData[nPartType] = nValue
        end
    end
    tbNewTemplate.tbData = tbData
    local tbTypeMap = tbContainer.tbTypeMap
    if not tbTypeMap then
        tbTypeMap = {}
        tbContainer.tbTypeMap = tbTypeMap
    end
    local nType = tbNewTemplate.nType
    local tbIds = tbTypeMap[nType]
    if not tbIds then
        tbIds = {}
        tbTypeMap[nType] = tbIds
    end
    table.insert(tbIds, tbNewTemplate.nId)
    local tbDefaultData = tbContainer.tbDefaultData
    if not tbDefaultData then
        tbDefaultData = {}
        tbContainer.tbDefaultData = tbDefaultData
    end
    if not tbDefaultData[nType] then
        tbDefaultData[nType] = tbNewTemplate.nId
    end
    return true
end

-- [EXPORT BEGIN]
function DefaultAppearanceDataTable:GetData(nId)
    local tbRet = self.tbContainer[nId]
    return tbRet
end

function DefaultAppearanceDataTable:GetPartDatas(nId)
    local tbRet = self.tbContainer[nId]
    if tbRet then
        return tbRet.tbData
    end
    return {}
end

function DefaultAppearanceDataTable:GetIdsByType(nType, nGender)
    local tbTypeMap = self.tbContainer.tbTypeMap
    if tbTypeMap then
        local tbResult = {}
        local tbIds = tbTypeMap[nType]
        for _, nId in ipairs(tbIds) do
            local tbTemplate = self:GetData(nId)
            if (tbTemplate.nGender & nGender) > 0 then
                table.insert(tbResult, nId)
            end
        end
        return tbResult
    end
    return nil
end



-- 针对如果出现缺失值的情况，使用该值，以确保显示正确
-- function DefaultAppearanceDataTable:GetDefaultDatas()
--     local tbResult = {}
--     local tbDefault = self.tbContainer.tbDefaultData
--     for nSlotType, nId in pairs(tbDefault) do
--         table.insert(tbResult, nId)
--     end
--     return tbResult
-- end
-- [EXPORT END]

return DefaultAppearanceDataTable
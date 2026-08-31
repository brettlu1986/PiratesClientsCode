local PropertyComboDataTable = {}

local DataTableExporter = require("DataTableExporter")
local PropertyComboDefineDataTable = require("PropertyComboDefineDataTable")
local PropertyComboOperationTypeDef = require("PropertyComboOperationTypeDef")

local MAX_PROPERTY_COUNT    = 6
local PREFIX_KEY            = "key_"
local PREFIX_VALUE          = "value_"
local nCurrentMinId         = -1
local nCurrentMaxId         = -1

PropertyComboDataTable.szFileName = "common/property_combo/property_combo_category.tab"
PropertyComboDataTable.tbSubTableTemplates = {}

local function GetValueByOperationSymbol(szSymbol, szValue)
    local bPercent = string.sub(szValue, -1,-1) == "%"
    local nValue = 0
    if bPercent then
        nValue = tonumber(string.sub(szValue, 2, -2)) / 100
    else
        nValue = tonumber(string.sub(szValue, 2))
    end
    if szSymbol == "-" or szSymbol == "/" then
        nValue = nValue * -1
    end
    return nValue
end

local function OnEditorSubTableParseLine(SubDataTable, Parser, tbContainer, tbNewTemplate)
    local nComboId = Parser:Get("combo_id", -1, Parser.TypeInt)
    assert((nComboId < nCurrentMaxId) and (nComboId > nCurrentMinId), string.format("combo_id不在范围区间内，正确范围为(%d,%d)，当前配置Id为%d", nCurrentMinId, nCurrentMaxId, nComboId))
    
    local tbProperties = {}
    for i = 1, MAX_PROPERTY_COUNT do
        local szKey = Parser:Get(PREFIX_KEY .. i, nil, Parser.TypeString, false)
        if szKey then
            assert(PropertyComboDefineDataTable:IsValidKey(szKey), string.format("key无效，请对应Define表进行检查，当前配置的key为%s", szKey))
            local szValue = Parser:Get(PREFIX_VALUE .. i, "", Parser.TypeString)
            local szSymbol = string.sub(szValue, 1, 1)

            assert(PropertyComboDefineDataTable:IsValidOperation(szKey, szSymbol), string.format("运算符无效，请对照Define中Key对应已开放的运算符进行配置，当前配置的key为%s，value为%s", szKey, szValue))
            local nOperationType = PropertyComboOperationTypeDef:GetOperationByString(szSymbol)
            tbProperties[szKey] = {
                [nOperationType] = GetValueByOperationSymbol(szSymbol, szValue)
            }
        end
    end
    tbNewTemplate.tbProperties = tbProperties
    SubDataTable.tbOwnerContainer[nComboId] = tbNewTemplate
    return true
end

function PropertyComboDataTable:OnEditorDefine(Parser)
    Parser:Define("nCategory"   , "category", -1    , Parser.TypeInt)
    Parser:Define("szPath"      , "path"    , nil   , Parser.TypeString)
    Parser:Define("nMinId"      , "min_id"  , -1    , Parser.TypeInt)
    Parser:Define("nMaxId"      , "max_id"  , -1    , Parser.TypeInt)
end

function PropertyComboDataTable:OnEditorParseLine(Parser, tbContainer, tbNewTemplate)
    table.insert(self.tbSubTableTemplates, tbNewTemplate)
    return true
end

function PropertyComboDataTable:OnEditorParseFinished()
    for i, tbTemplate in ipairs(self.tbSubTableTemplates) do
        local SubDataTable = {}
        SubDataTable.szFileName = tbTemplate.szPath
        SubDataTable.OnEditorParseLine = OnEditorSubTableParseLine
        SubDataTable.tbOwnerContainer = self.tbContainer
        nCurrentMinId = tbTemplate.nMinId
        nCurrentMaxId = tbTemplate.nMaxId
        if not DataTableExporter:Load(SubDataTable) then
            error("PropertyComboDataTable读取子表失败，子表路径：" .. tbTemplate.szPath)
        end
    end
end

-- [EXPORT BEGIN]
function PropertyComboDataTable:GetTemplate(nComboId)
    return self.tbContainer[nComboId]
end
-- [EXPORT END]

return PropertyComboDataTable

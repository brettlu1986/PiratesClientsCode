local PropertyComboDefineDataTable = {}

local L10N = require("L10N")

PropertyComboDefineDataTable.szFileName = "common/property_combo/property_combo_define.tab"

function PropertyComboDefineDataTable:OnEditorDefine(Parser)
    Parser:SetKey("szKey")
    Parser:Define("szKey"           , "key"             , ""                , Parser.TypeString)
    Parser:Define("nIndex"          , "index"           , -1                , Parser.TypeInt)
    Parser:Define("l10nDisplayName" , "display_name"    , L10N.NullString   , Parser.TypeL10N)
    Parser:Define("tbValidOperation", "valid_operation" , {}                , Parser.TypeArrayString)
end

-- [EXPORT BEGIN]
function PropertyComboDefineDataTable:GetPropertyDisplayName(szPropertyName)
    return self.tbContainer[szPropertyName].l10nDisplayName
end

function PropertyComboDefineDataTable:GetPropertyIndex(szPropertyName)
    return self.tbContainer[szPropertyName].nIndex
end

function PropertyComboDefineDataTable:IsValidKey(szPropertyName)
    return self.tbContainer[szPropertyName] ~= nil
end

function PropertyComboDefineDataTable:IsValidOperation(szPropertyName, szSymbol)
    for _, v in ipairs(self.tbContainer[szPropertyName].tbValidOperation) do
        if v == szSymbol then
            return true
        end
    end
    return false
end
-- [EXPORT END]

return PropertyComboDefineDataTable

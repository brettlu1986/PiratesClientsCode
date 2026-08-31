local GMSearchablePropDataTable = {}

GMSearchablePropDataTable.szFileName = "common/debug/gm_searchable_prop.tab"
GMSearchablePropDataTable.bEnableIterateKey = true

function GMSearchablePropDataTable:OnEditorDefine(Parser)
    Parser:SetKey("szKey")
    Parser:Define("szKey", "key", "", Parser.TypeString)
    Parser:Define("szDesc", "desc", "", Parser.TypeString)
    Parser:Define("bDataFromServer", "data_from_server", true, Parser.TypeBool)
    Parser:Define("bDungeonProp", "dungeon_prop", true, Parser.TypeBool)
end

-- [EXPORT BEGIN]
function GMSearchablePropDataTable:GetTemplateList()
    local tbRet = {}
    for k, v in pairs(self.tbContainer) do
        table.insert(tbRet, v)
    end
    table.sort(tbRet, function(A, B)
        return A.szKey > B.szKey
    end)
    return tbRet
end

function GMSearchablePropDataTable:GetTemplate(szKey)
    return self.tbContainer[szKey]
end

-- [EXPORT END]

return GMSearchablePropDataTable

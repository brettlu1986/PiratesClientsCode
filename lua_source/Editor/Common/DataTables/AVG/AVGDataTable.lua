


local AVGDataTable = {}

AVGDataTable.szFileName = "common/avg/avg.tab"

function AVGDataTable:OnEditorDefine(Parser)
    Parser:SetKey("nId")
    Parser:Define("nId", "id", -1, Parser.TypeInt)
    Parser:Define("nDungeonId", "dungeon_id", -1, Parser.TypeInt)
end

-- [EXPORT BEGIN]
function AVGDataTable:GetTemplate(nID)
    return self.tbContainer[nID]
end
-- [EXPORT END]

return AVGDataTable



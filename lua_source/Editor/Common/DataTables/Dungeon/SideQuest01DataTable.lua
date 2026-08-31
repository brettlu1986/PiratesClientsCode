local SideQuest01DataTable = {}

SideQuest01DataTable.szFileName = "common/dungeon/side_quest_01.tab"

function SideQuest01DataTable:OnEditorDefine(Parser)
    Parser:SetKey("nId")
    Parser:Define("nId", "id", -1, Parser.TypeInt)
    Parser:Define("nTimeout", "timeout", -1, Parser.TypeInt)
    Parser:Define("nShowResultTime", "show_result_time", -1, Parser.TypeInt)
end

-- [EXPORT BEGIN]
function SideQuest01DataTable:GetTemplate(nID)
    return self.tbContainer[nID]
end
-- [EXPORT END]

return SideQuest01DataTable
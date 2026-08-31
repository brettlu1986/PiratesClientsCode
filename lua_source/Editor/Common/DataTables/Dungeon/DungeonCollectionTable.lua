--副本采集表格

local DungeonCollectionTable = {}

DungeonCollectionTable.szFileName = "common/dungeon/dungeon_collection.tab"

function DungeonCollectionTable:OnEditorDefine(Parser)
    Parser:SetKey("nTemplateID")
    Parser:Define("nTemplateID", "template_id", -1, Parser.TypeInt)
    Parser:Define("nProgressID", "progressid", -1, Parser.TypeInt)
    Parser:Define("nshowAllDistance", "showall_distance", -1, Parser.TypeFloat)
    Parser:Define("nshowiconDistance", "showicon_distance", -1, Parser.TypeFloat)
end

-- [EXPORT BEGIN]
function DungeonCollectionTable:GetTemplate(nID)
    return self.tbContainer[nID]
end
-- [EXPORT END]

return DungeonCollectionTable
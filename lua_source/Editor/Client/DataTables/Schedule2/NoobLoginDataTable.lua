local NoobLoginDataTable = {}
local L10N = require("L10N")

NoobLoginDataTable.szFileName = "common/schedule2/noob_login.tab"
-- [EXPORT]
NoobLoginDataTable.tbAll = {}

function NoobLoginDataTable:OnEditorDefine(Parser)
    Parser:SetKey("nDays")
    Parser:Define("nDays", "days", -1, Parser.TypeInt)
    Parser:Define("nAwardId", "award_id", -1, Parser.TypeInt)
    Parser:Define("tbGameCount", "game_count", nil,   Parser.TypeArrayInt)
    Parser:Define("szDayIcon", "day_icon", "", Parser.TypeString)    
    Parser:Define("nNextDay", "next_day", -1, Parser.TypeInt)
    -- Parser:Define("szNameIcon", "name_icon", "", Parser.TypeString)    
    -- Parser:Define("szDayIcon", "day_icon", "", Parser.TypeString)    
    Parser:Define("l10nItemDesc", "item_desc", L10N.NullString, Parser.TypeL10N)
    Parser:Define("l10nName", "name", L10N.NullString, Parser.TypeL10N)    
end

function NoobLoginDataTable:OnEditorParseLine(Parser, tbContainer, tbNewTemplate)
    table.insert(self.tbAll, tbNewTemplate)
    return true
end

-- [EXPORT BEGIN]
function NoobLoginDataTable:GetTemplate(nDays)
    return self.tbContainer[nDays]
end
-- [EXPORT END]

-- [EXPORT BEGIN]
function NoobLoginDataTable:GetCount()
    return #self.tbAll
end
-- [EXPORT END]

-- [EXPORT BEGIN]
function NoobLoginDataTable:GetContainer()
    return self.tbAll
end
-- [EXPORT END]

return NoobLoginDataTable
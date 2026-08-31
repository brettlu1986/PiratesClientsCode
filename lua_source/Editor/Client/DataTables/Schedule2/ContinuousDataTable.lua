local ContinuousDataTable = {}

ContinuousDataTable.szFileName = "common/schedule2/continuous.tab"
-- [EXPORT]
ContinuousDataTable.tbAll = {}

function ContinuousDataTable:OnEditorDefine(Parser)
    Parser:SetKey("nDays")
    Parser:Define("nDays", "days", -1, Parser.TypeInt)
    Parser:Define("nIconType", "award_icon_type", 1, Parser.TypeInt)
    Parser:Define("nAwardId", "award_id", -1, Parser.TypeInt)
end

function ContinuousDataTable:OnEditorParseLine(Parser, tbContainer, tbNewTemplate)
    table.insert(self.tbAll, tbNewTemplate)
    return true
end

-- [EXPORT BEGIN]
function ContinuousDataTable:GetTemplate(nDays)
    return self.tbContainer[nDays]
end
-- [EXPORT END]

-- [EXPORT BEGIN]
function ContinuousDataTable:GetCount()
    return #self.tbAll
end
-- [EXPORT END]

-- [EXPORT BEGIN]
function ContinuousDataTable:GetContainer()
    return self.tbAll
end
-- [EXPORT END]

return ContinuousDataTable
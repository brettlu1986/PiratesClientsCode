local CheckInTable = {}

CheckInTable.szFileName = "common/schedule2/checkin.tab"

function CheckInTable:OnEditorDefine(Parser)
    Parser:SetKey("nCheckinNumber")
    Parser:Define("nCheckinNumber",  "checkin_number", -1, Parser.TypeInt)
    Parser:Define("nAwardId", "award_id", -1, Parser.TypeInt)
end

-- [EXPORT BEGIN]
function CheckInTable:GetTemplate(nCheckinNumber)
    return self.tbContainer[nCheckinNumber]
end
-- [EXPORT END]

return CheckInTable
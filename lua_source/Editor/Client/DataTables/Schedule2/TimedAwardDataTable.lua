local TimedAwardDataTable = {}
local L10N = require("L10N")

TimedAwardDataTable.szFileName = "common/schedule2/timed_award.tab"
-- [EXPORT]
TimedAwardDataTable.tbAll = {}

local function ParseHMSStrToHMSNumber(szTime)
    local _, _, hour, min, sec = string.find(szTime, "(%d+):(%d+):(%d+)")
    return tonumber(hour), tonumber(min), tonumber(sec)
end

function TimedAwardDataTable:OnEditorDefine(Parser)
    Parser:SetKey("nId")
    Parser:Define("nId",            "id",           -1,     Parser.TypeInt)
    Parser:Define("nAwardId",       "award_id",     -1,     Parser.TypeInt)
    Parser:Define("szStartTime",    "start_time",   nil,    Parser.TypeString)
    Parser:Define("szStopTime",     "stop_time",    nil,    Parser.TypeString)
    Parser:Define("l10nDesc",       "desc",         L10N.NullString, Parser.TypeL10N)
end

function TimedAwardDataTable:OnEditorParseLine(Parser, tbContainer, tbNewTemplate)
    local nHour, nMin, nSec = ParseHMSStrToHMSNumber(tbNewTemplate.szStartTime)
    if nHour >= 24 or nMin >= 60 or nSec >= 60 then
        error("TimedAwardDataTable start time is invalid")
    end
    tbNewTemplate.nStartHour = nHour
    tbNewTemplate.nStartMin  = nMin
    tbNewTemplate.nStartSec  = nSec

    nHour, nMin, nSec = ParseHMSStrToHMSNumber(tbNewTemplate.szStopTime)
    if nHour >= 24 or nMin >= 60 or nSec >= 60 then
        error("TimedAwardDataTable stop time is invalid")
    end
    tbNewTemplate.nStopHour = nHour
    tbNewTemplate.nStopMin  = nMin
    tbNewTemplate.nStopSec  = nSec

    table.insert(self.tbAll, tbNewTemplate)

    return true
end 

-- [EXPORT BEGIN]
function TimedAwardDataTable:GetTemplate(nId)
    return self.tbContainer[nId]
end
-- [EXPORT END]

-- [EXPORT BEGIN]
function TimedAwardDataTable:GetContainer()
    return self.tbAll
end
-- [EXPORT END]

return TimedAwardDataTable
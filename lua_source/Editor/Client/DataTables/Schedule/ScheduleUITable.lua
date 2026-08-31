local ScheduleUITable = {}

local L10N = require("L10N")

ScheduleUITable.szFileName = "client/schedule2/schedule_ui.tab"
-- [EXPORT]
ScheduleUITable.tbAll = {}

function ScheduleUITable:OnEditorDefine(Parser)
    Parser:SetKey("nId")
    Parser:Define("nId", "id", -1, Parser.TypeInt)
    Parser:Define("nOrder", "order", -1, Parser.TypeInt)
    Parser:Define("l10nName", "name", L10N.NullString, Parser.TypeL10N)
    -- Parser:Define("l10nDesc", "desc", L10N.NullString, Parser.TypeL10N)
    Parser:Define("bLimit", "is_limit", false, Parser.TypeBool)
    Parser:Define("nType", "type", 1, Parser.TypeInt)
    Parser:Define("szImgPath1",     "img_path1",      nil, Parser.TypeString)
    Parser:Define("szImgPath2",     "img_path2",      nil, Parser.TypeString)
    -- Parser:Define("szImgPath3",     "img_path3",      nil, Parser.TypeString)
    Parser:Define("szLobbyImgPath", "lobby_img_path", nil, Parser.TypeString)
    Parser:Define("nLobbyTime",     "lobby_time",     -1,  Parser.TypeInt)
    Parser:Define("nLobbyOrder",    "lobby_order",    -1,  Parser.TypeInt)
    Parser:Define("szTimerProcess", "timer_process", nil, Parser.TypeString)
    Parser:Define("szIsOpen", "is_open", nil, Parser.TypeString)
    Parser:Define("szIsTip",  "is_tip",  nil, Parser.TypeString)
    Parser:Define("szULName", "ul_name", nil, Parser.TypeString)
    Parser:Define("szUPName", "up_name", nil, Parser.TypeString)
    Parser:Define("szNextDayProcess", "next_day_process", nil, Parser.TypeString)
    Parser:Define("szTimerProcess", "timer_process", nil, Parser.TypeString)
    Parser:Define("szWndName", "wnd_name", nil, Parser.TypeString)
    Parser:Define("tbGoPos", "go_pos", nil, Parser.TypeArrayInt)
end

function ScheduleUITable:OnEditorParseLine(Parser, tbContainer, tbNewTemplate)
    table.insert(self.tbAll, tbNewTemplate)
    return true
end

-- [EXPORT BEGIN]
function ScheduleUITable:GetTemplate(nId)
    return self.tbContainer[nId]
end
-- [EXPORT END]

-- [EXPORT BEGIN]
function ScheduleUITable:GetContainer()
    return self.tbContainer
end
-- [EXPORT END]

return ScheduleUITable
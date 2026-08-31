local MatchmakingTeamModeDataTable = {}

local L10N = require("L10N")


MatchmakingTeamModeDataTable.szFileName = "common/dungeon/matchmaking_team_mode.tab"

-- [EXPORT]
MatchmakingTeamModeDataTable.tbAllMode = {}

function MatchmakingTeamModeDataTable:OnEditorDefine(Parser)
    Parser:SetKey("nId")
    Parser:Define("nId", "id", -1, Parser.TypeInt)
    Parser:Define("nPlayersPerTeam", "players_per_team", -1, Parser.TypeInt)
    Parser:Define("l10nDesc", "desc", L10N.NullString, Parser.TypeL10N)
    Parser:Define("szIcon", "icon", "", Parser.TypeString)
end

function MatchmakingTeamModeDataTable:OnEditorParseLine(Parser, tbContainer, tbNewTemplate)
    table.insert(self.tbAllMode, tbNewTemplate)
    return true
end

-- [EXPORT BEGIN]
function MatchmakingTeamModeDataTable:GetTemplate(nID)
    return self.tbContainer[nID]
end
-- [EXPORT END]

-- [EXPORT BEGIN]
function MatchmakingTeamModeDataTable:GetAllMode()
    return self.tbAllMode
end
-- [EXPORT END]

return MatchmakingTeamModeDataTable
local GameInitDataDataTable = {}

GameInitDataDataTable.szFileName = "common/matchmaker/game_init_data.tab"

function GameInitDataDataTable:OnEditorDefine(Parser)
    Parser:SetKey("nId")
    Parser:Define("nId", "id", -1, Parser.TypeInt)
    Parser:Define("nBotCount", "bot_count", -1, Parser.TypeInt)
    Parser:Define("nBotId", "bot_id", -1, Parser.TypeInt)
    Parser:Define("nDungeonNpcGrade", "npc_grade", -1, Parser.TypeInt)
    Parser:Define("nCountDownRealPlayerCount", "count_down_real_player_count", -1, Parser.TypeInt)
    Parser:Define("nCountDownTotalPlayerCount", "count_down_total_player_count", -1, Parser.TypeInt)
    Parser:Define("nCountDownMaxWaitTime", "count_down_max_wait_time", -1, Parser.TypeInt)
    Parser:Define("nCountDownTime", "count_down_time", -1, Parser.TypeInt)
    Parser:Define("nSelectionPointLockTime", "selection_point_lock_time", -1, Parser.TypeInt)
    Parser:Define("nSelectionPointPopTime", "selection_point_pop_time", -1, Parser.TypeInt)
    Parser:Define("nStopAcceptingPlayerTime", "stop_accepting_player_time", -1, Parser.TypeInt)
    Parser:Define("nTeamModeId", "team_mode_id", -1, Parser.TypeInt)
    Parser:Define("bNoob", "noob", false, Parser.TypeBool)
    Parser:Define("nWaitTimeRandom", "wait_time_random", 0, Parser.TypeInt)
    Parser:Define("nCountDownTimeRandom", "count_down_time_random", 0, Parser.TypeInt)
end

-- [EXPORT BEGIN]
function GameInitDataDataTable:GetTemplate(nId)
    return self.tbContainer[nId]
end
-- [EXPORT END]

return GameInitDataDataTable
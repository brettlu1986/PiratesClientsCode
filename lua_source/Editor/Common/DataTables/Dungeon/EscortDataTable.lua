local EscortDataTable = {}

EscortDataTable.szFileName = "common/dungeon/escort_game_mode.tab"

function EscortDataTable:OnEditorDefine(Parser)
    Parser:SetKey("nId")
    Parser:Define("nId", "id", -1, Parser.TypeInt)
    Parser:Define("szBossIds", "boss_ids", "", Parser.TypeString)
    Parser:Define("szOrdinaryMobIds", "ordinary_mob_ids", "", Parser.TypeString)
    Parser:Define("nShowResultTime", "show_result_time", -1, Parser.TypeInt)
    Parser:Define("nDialogId", "dialog_id", -1, Parser.TypeInt)
end

-- [EXPORT BEGIN]
function EscortDataTable:GetTemplate(nID)
    return self.tbContainer[nID]
end
-- [EXPORT END]

return EscortDataTable
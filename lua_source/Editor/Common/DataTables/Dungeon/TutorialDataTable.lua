local TutorialDataTable = {}

TutorialDataTable.szFileName = "common/dungeon/tutorial_game_mode.tab"

function TutorialDataTable:OnEditorDefine(Parser)
    Parser:SetKey("nId")
    Parser:Define("nId", "id", -1, Parser.TypeInt)
    Parser:Define("nEnterStartGroupId", "enter_start_group_id", -1, Parser.TypeInt)
    Parser:Define("nSelfShipTypeId", "self_ship_type_id", -1, Parser.TypeInt)
    Parser:Define("szSelfName", "self_name", "", Parser.TypeString)
    Parser:Define("nShipGroupIdJack", "ship_group_id_jack", -1, Parser.TypeInt)
    Parser:Define("nShipGroupId1", "ship_group_id_1", -1, Parser.TypeInt)
    Parser:Define("nAttackOcotpusStartGroupId", "attack_octopus_start_group_id", -1, Parser.TypeInt)
    Parser:Define("nOctopusGroupId", "octopus_group_id", -1, Parser.TypeInt)
    Parser:Define("nSameCampGroupId", "same_camp_group_id", -1, Parser.TypeInt)
    Parser:Define("nJackStartGroupId", "jack_start_group_id", -1, Parser.TypeInt)
end

-- [EXPORT BEGIN]
function TutorialDataTable:GetTemplate(nID)
    return self.tbContainer[nID]
end
-- [EXPORT END]

return TutorialDataTable
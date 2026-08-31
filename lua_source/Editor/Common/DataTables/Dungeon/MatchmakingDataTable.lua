local MatchmakingDataTable = {}

MatchmakingDataTable.szFileName = "common/dungeon/matchmaking.tab"

function MatchmakingDataTable:OnEditorDefine(Parser)
    Parser:Define("nDungeonId", "dungeon_id", -1, Parser.TypeInt)
    Parser:Define("nTeamModeId", "team_mode_id", -1, Parser.TypeInt)
end

function MatchmakingDataTable:OnEditorParseLine(Parser, tbContainer, tbNewTemplate)
    local nDungeonId = tbNewTemplate.nDungeonId
    local nTeamModeId = tbNewTemplate.nTeamModeId
    tbContainer[nDungeonId] = tbContainer[nDungeonId] or {}
    local tbDungeon = tbContainer[nDungeonId]
    tbDungeon[nTeamModeId] = tbNewTemplate
    return true
end

-- [EXPORT BEGIN]
function MatchmakingDataTable:GetTemplate(nDungeonId, nTeamModeId)
    if self.tbContainer[nDungeonId] == nil then
        return nil
    end

    local tbDungeon = self.tbContainer[nDungeonId]
    return tbDungeon[nTeamModeId]
end
-- [EXPORT END]

return MatchmakingDataTable
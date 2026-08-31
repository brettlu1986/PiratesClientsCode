--[[
    IniConfig类中必须有的成员变量与函数
    szFileName : 文件名，不包含路径
    Container: table
    OnParse： 解析函数，参数Parser
--]]

local SeasonIni = {}
SeasonIni.szFileName = "common/season2/season.ini"

function SeasonIni:OnParse(Parser)
    local tbRank = {}
    tbRank.nDefaultStarRankPoint = Parser:Get("rank", "default_start_rank_point", -1, Parser.TypeNumber)
    self.tbRank = tbRank

    local tbBattlePass = {}
    tbBattlePass.nDefaultTier = Parser:Get("battle_pass", "default_battle_tier", -1, Parser.TypeNumber)
    tbBattlePass.nDefaultStar = Parser:Get("battle_pass", "default_battle_star", -1, Parser.TypeNumber)
    tbBattlePass.nBattleTierInterval = Parser:Get("battle_pass", "battle_tier_interval", -1, Parser.TypeNumber)
    self.tbBattlePass = tbBattlePass

    local tbRanking = {}
    tbRanking.nSeasonRanking = Parser:Get("ranking", "season_ranking", -1, Parser.TypeNumber)
    self.tbRanking = tbRanking
end

return SeasonIni

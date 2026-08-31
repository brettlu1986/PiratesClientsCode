--[[
    IniConfig类中必须有的成员变量与函数
    szFileName : 文件名，不包含路径
    Container: table
    OnParse： 解析函数，参数Parser
--]]

local TeamIni = {}
TeamIni.szFileName = "common/team2/team.ini"

function TeamIni:OnParse(Parser)
    self.nValidTimeForApplyJoinTeam = Parser:Get("team", "invite_join_valid_time", -1, Parser.TypeNumber)
    self.nTeamRecruitCoolDown = Parser:Get("cooldown", "team_recruit_cooldown", 0, Parser.TypeNumber)
end

return TeamIni

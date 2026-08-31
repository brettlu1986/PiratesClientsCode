--[[
    IniConfig类中必须有的成员变量与函数
    szFileName : 文件名，不包含路径
    Container: table
    OnParse： 解析函数，参数Parser
--]]

local ScheduleIni = {}
ScheduleIni.szFileName = "common/schedule2/schedule.ini"

function ScheduleIni:OnParse(Parser)
    local tbBattleStar = {}
    tbBattleStar.nMultiple = Parser:Get("battle_star", "multiple", 1, Parser.TypeNumber)
    tbBattleStar.nTemplateId = Parser:Get("battle_star", "template", -1, Parser.TypeNumber)
    self.tbBattleStar = tbBattleStar

    local tbNoobLogin = {}
    tbNoobLogin.nAwardMode = Parser:Get("noob_login", "award_mode", 1, Parser.TypeNumber)
    self.tbNoobLogin = tbNoobLogin
    
end

return ScheduleIni

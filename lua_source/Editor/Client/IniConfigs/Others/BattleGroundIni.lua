--[[
    IniConfig类中必须有的成员变量与函数
    szFileName : 文件名，不包含路径
    Container: table
    OnParse： 解析函数，参数Parser
--]]

local BattleGroundIni = {}
BattleGroundIni.szFileName = "common/battleground/battleground.ini"

function BattleGroundIni:OnParse(Parser)
    local tbDailyFirstWin = {}
    tbDailyFirstWin.nAwardId    = Parser:Get("daily_first_win", "level_award_id"      , -1, Parser.TypeNumber)
    tbDailyFirstWin.nResetHour  = Parser:Get("daily_first_win", "reset_hour"          , -1, Parser.TypeNumber)
    self.tbDailyFirstWin = tbDailyFirstWin
end

return BattleGroundIni

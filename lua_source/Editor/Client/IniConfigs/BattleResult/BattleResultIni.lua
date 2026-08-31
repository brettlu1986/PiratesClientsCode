--[[
    IniConfig类中必须有的成员变量与函数
    szFileName : 文件名，不包含路径
    Container: table
    OnParse： 解析函数，参数Parser
--]]

local BattleResultIni = {}
BattleResultIni.szFileName = "client/battleresult/battle_result.ini"

function BattleResultIni:OnParse(Parser)
    local tbBattleResult = {}
    self.tbBattleResult = tbBattleResult
    
    tbBattleResult.nWinDelay       = Parser:Get("battle_result"      , "win_delay"      ,  0.1    , Parser.TypeNumber)
    tbBattleResult.nLoseDelay      = Parser:Get("battle_result"      , "lose_delay"     ,  0.1    , Parser.TypeNumber)
    tbBattleResult.nWatchDelay     = Parser:Get("battle_result"      , "watch_delay"    ,  0.1    , Parser.TypeNumber)
    tbBattleResult.nResultCountdown = Parser:Get("battle_result"      , "result_countdown"    ,  90    , Parser.TypeNumber)
    tbBattleResult.nStatisticsCountdown = Parser:Get("battle_result"      , "statistics_countdown"    ,  100    , Parser.TypeNumber)
    
    
end

return BattleResultIni

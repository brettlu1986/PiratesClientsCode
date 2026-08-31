--[[
    IniConfig类中必须有的成员变量与函数
    szFileName : 文件名，不包含路径
    Container: table
    OnParse： 解析函数，参数Parser
--]]

local BattleResultServerIni = {}
BattleResultServerIni.szFileName = "common/battleresult/battle_result_server.ini"

function BattleResultServerIni:OnParse(Parser)
    
    self.nRusultEquipLevelupItem  = Parser:Get("battle_result"      , "equip_levelup_item"     ,  0    , Parser.TypeNumber)
    self.nDeadLossPercent         = Parser:Get("battle_result"      , "dead_loss_percent"      ,  100  , Parser.TypeNumber)
    self.nDeadLossPercent = self.nDeadLossPercent * 0.01
    self.nRewardMax               = Parser:Get("battle_result"      , "reward_max"             ,  0    , Parser.TypeNumber)
end

return BattleResultServerIni

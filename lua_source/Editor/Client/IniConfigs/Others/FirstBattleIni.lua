--[[
    IniConfig类中必须有的成员变量与函数
    szFileName : 文件名，不包含路径
    Container: table
    OnParse： 解析函数，参数Parser
--]]

local FirstBattleIni = {}
FirstBattleIni.szFileName = "common/battle/battle.ini"

function FirstBattleIni:OnParse(Parser)
    local nAwardId = Parser:Get("battle", "first_battle_award_id"      , -1, Parser.TypeNumber)
    self.nAwardId  = nAwardId
end

return FirstBattleIni

--[[
    IniConfig类中必须有的成员变量与函数
    szFileName : 文件名，不包含路径
    Container: table
    OnParse： 解析函数，参数Parser
--]]

local HumanMoraleIni = {}
HumanMoraleIni.szFileName = "common/ffa/human/human_morale.ini"

function HumanMoraleIni:OnParse(Parser)
    local tbHumanMorale = {}
    tbHumanMorale.nDecreaseInterval = Parser:Get("human_morale", "decrease_interval", -1, Parser.TypeNumber)
    tbHumanMorale.nDecreaseValue = Parser:Get("human_morale", "decrease_value", -1, Parser.TypeNumber)
    tbHumanMorale.bDecreaseToShip = Parser:Get("human_morale" , "isdecrease_toship"   , false, Parser.TypeBool)    
    self.tbHumanMorale = tbHumanMorale
end

return HumanMoraleIni

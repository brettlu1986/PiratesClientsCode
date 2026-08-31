--[[
    IniConfig类中必须有的成员变量与函数
    szFileName : 文件名，不包含路径
    Container: table
    OnParse： 解析函数，参数Parser
--]]

local HumanFallingDamageIni = {}
HumanFallingDamageIni.szFileName = "common/ffa/human/human_falling_damage.ini"

function HumanFallingDamageIni:OnParse(Parser)
    local tbHumanFallingDamage = {}
    tbHumanFallingDamage.nFallingHeight = Parser:Get("human_falling_damage", "ingore_falling_height", -1, Parser.TypeNumber)
    tbHumanFallingDamage.nDamageFactor = Parser:Get("human_falling_damage", "falling_damage_factor", -1, Parser.TypeNumber)
    self.tbHumanFallingDamage = tbHumanFallingDamage
end

return HumanFallingDamageIni

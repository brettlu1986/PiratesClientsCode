--[[
    IniConfig类中必须有的成员变量与函数
    szFileName : 文件名，不包含路径
    Container: table
    OnParse： 解析函数，参数Parser
--]]

local ShipMoraleIni = {}
ShipMoraleIni.szFileName = "common/ffa/ship/ship_morale.ini"

function ShipMoraleIni:OnParse(Parser)
    local tbShipMorale = {}
    tbShipMorale.bDecreaseToHuman = Parser:Get("ship_morale" , "isdecrease_tohuman"   , false, Parser.TypeBool)
    self.tbShipMorale = tbShipMorale
end

return ShipMoraleIni

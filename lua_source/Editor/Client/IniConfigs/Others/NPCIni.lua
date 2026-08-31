--[[
    IniConfig类中必须有的成员变量与函数
    szFileName : 文件名，不包含路径
    Container: table
--]]

local NPCIni = {}
NPCIni.szFileName = "common/npc/npc.ini"

function NPCIni:OnParse(Parser)
    self.nDistanceShip              = Parser:Get("dialog", "distance_ship"            , -1, Parser.TypeNumber)
    self.nDistanceHuman             = Parser:Get("dialog", "distance_non_ship"        , -1, Parser.TypeNumber)
end

return NPCIni

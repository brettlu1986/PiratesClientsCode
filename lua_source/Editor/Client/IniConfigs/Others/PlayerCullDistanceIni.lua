--[[
    IniConfig类中必须有的成员变量与函数
    szFileName : 文件名，不包含路径
    Container: table
--]]

local PlayerCullDistanceIni = {}
PlayerCullDistanceIni.szFileName = "client/player/cull_distance.ini"

function PlayerCullDistanceIni:OnParse(Parser)
    self.nDistanceShip              = Parser:Get("player_aoi", "distance_ship"            , -1, Parser.TypeNumber)
    self.nDistanceHuman             = Parser:Get("player_aoi", "distance_human"        , -1, Parser.TypeNumber)
end

return PlayerCullDistanceIni

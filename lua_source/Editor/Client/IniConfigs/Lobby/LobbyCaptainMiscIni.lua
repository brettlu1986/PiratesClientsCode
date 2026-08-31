--[[
    IniConfig类中必须有的成员变量与函数
    szFileName : 文件名，不包含路径
    Container: table
--]]

local LobbyCaptainMiscIni = {}
LobbyCaptainMiscIni.szFileName = "client/lobbycaptain/lobby_captain_misc.ini"

function LobbyCaptainMiscIni:OnParse(Parser)
    self.nBasicFashionAnimKey   = Parser:Get("armor",     "basic_fashion_anim"          ,  "", Parser.TypeString)
    self.szEmptyHandNameKey     = Parser:Get("weapon",    "empty_hand_name_key"           ,  "", Parser.TypeString)
    self.nEmptyHandDamage       = Parser:Get("weapon",    "empty_hand_damage"           ,   0, Parser.TypeNumber)
    self.nEmptyHandRange        = Parser:Get("weapon",    "empty_hand_range"            ,   0, Parser.TypeNumber)
    self.nEmptyHandSpeedLevel   = Parser:Get("weapon",    "empty_hand_speed_level"      ,   1, Parser.TypeNumber)
end

return LobbyCaptainMiscIni

--[[
    IniConfig类中必须有的成员变量与函数
    szFileName : 文件名，不包含路径
    Container: table
--]]

local PlayerNameIni = {}
PlayerNameIni.szFileName = "common/name/name.ini"
PlayerNameIni.nMinCodePoint = 0
PlayerNameIni.nMaxCodePoint = 0
PlayerNameIni.nMinDisplayWidth = 0
PlayerNameIni.nMaxDisplayWidth = 0

function PlayerNameIni:OnParse(Parser)
    self.nMinCodePoint              = Parser:Get("player", "min_code_point", -1, Parser.TypeNumber)
    self.nMaxCodePoint             = Parser:Get("player", "max_code_point", -1, Parser.TypeNumber)

    self.nMinDisplayWidth              = Parser:Get("player", "min_display_width", -1, Parser.TypeNumber)
    self.nMaxDisplayWidth             = Parser:Get("player", "max_display_width", -1, Parser.TypeNumber)
    
end

return PlayerNameIni

--[[
    IniConfig类中必须有的成员变量与函数
    szFileName : 文件名，不包含路径
    Container: table
--]]

local GuildNameIni = {}
GuildNameIni.szFileName = "common/guild/guild_name.ini"
GuildNameIni.nMinCodePoint = 0
GuildNameIni.nMaxCodePoint = 0
GuildNameIni.nMinDisplayWidth = 0
GuildNameIni.nMaxDisplayWidth = 0

function GuildNameIni:OnParse(Parser)
    local tbName = {}
    tbName.nMinCodePoint             = Parser:Get("name", "min_code_point", -1, Parser.TypeNumber)
    tbName.nMaxCodePoint             = Parser:Get("name", "max_code_point", -1, Parser.TypeNumber)
    tbName.nMinDisplayWidth          = Parser:Get("name", "min_display_width", -1, Parser.TypeNumber)
    tbName.nMaxDisplayWidth          = Parser:Get("name", "max_display_width", -1, Parser.TypeNumber)
    self.tbName = tbName

    local tbAnnouncement = {}
    tbAnnouncement.nMinCodePoint     = Parser:Get("announcement", "min_code_point", -1, Parser.TypeNumber)
    tbAnnouncement.nMaxCodePoint     = Parser:Get("announcement", "max_code_point", -1, Parser.TypeNumber)
    tbAnnouncement.nMinDisplayWidth  = Parser:Get("announcement", "min_display_width", -1, Parser.TypeNumber)
    tbAnnouncement.nMaxDisplayWidth  = Parser:Get("announcement", "max_display_width", -1, Parser.TypeNumber)
    self.tbAnnouncement = tbAnnouncement 
end

return GuildNameIni

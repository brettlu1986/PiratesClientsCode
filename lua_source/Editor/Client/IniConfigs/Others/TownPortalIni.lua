--[[
    IniConfig类中必须有的成员变量与函数
    szFileName : 文件名，不包含路径
    Container: table
--]]

local TownPortalIni = {}
TownPortalIni.szFileName = "client/ui/town_portal.ini"

function TownPortalIni:OnParse(Parser)
    self.tbSceneId = Parser:Get("town_portal", "scene_id", -1, Parser.TypeArrayNumber)
end

return TownPortalIni

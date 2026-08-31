--[[
    IniConfig类中必须有的成员变量与函数
    szFileName : 文件名，不包含路径
    Container: table
    OnParse： 解析函数，参数Parser
--]]

local UIMapIni = {}
UIMapIni.szFileName = "client/ui/map/ui_map.ini"

function UIMapIni:OnParse(Parser)
    local tbMMap = {}
    tbMMap.nNavOtherSceneLv = Parser:Get("MMap", "nav_other_scene_level", 1, Parser.TypeNumber)
    tbMMap.nLandWeight = Parser:Get("MMap", "land_weight", 1, Parser.TypeNumber)
    tbMMap.nOceanWeight = Parser:Get("MMap", "ocean_weight", 1, Parser.TypeNumber)
    tbMMap.nPortMarkShowTime = Parser:Get("MMap", "port_mark_show_time", 1, Parser.TypeNumber)
    tbMMap.nPortMarkScopeChangeTime = Parser:Get("MMap", "port_mark_scope_change_time", 1, Parser.TypeNumber)
    self.tbMMap = tbMMap
end

return UIMapIni

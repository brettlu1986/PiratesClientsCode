--[[
    IniConfig类中必须有的成员变量与函数
    szFileName : 文件名，不包含路径
    Container: table
--]]

local MapSoundIni = {}
MapSoundIni.szFileName = "client/ui/map_sound.ini"

function MapSoundIni:OnParse(Parser)

    local tbSoundIni = {}
    tbSoundIni.nShowTime = Parser:Get("radar_map", "show_time", 0, Parser.TypeNumber)
    tbSoundIni.nShowRadius = Parser:Get("radar_map", "show_radius", 0, Parser.TypeNumber)
    tbSoundIni.tbIntensity = Parser:Get("radar_map", "sound_intensity", 1, Parser.TypeArrayNumber)
    self.tbSoundIni = tbSoundIni
end

return MapSoundIni

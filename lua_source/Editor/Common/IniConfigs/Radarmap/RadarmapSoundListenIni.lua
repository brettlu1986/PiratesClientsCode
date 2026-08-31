--[[
    IniConfig类中必须有的成员变量与函数
    szFileName : 文件名，不包含路径
    Container: table
    OnParse： 解析函数，参数Parser
--]]

local RadarmapSoundListenIni = {}
RadarmapSoundListenIni.szFileName = "common/ffa/radarmap_sound_listen.ini"

function RadarmapSoundListenIni:OnParse(Parser)
    self.nHumanListenRange      = Parser:Get("human_listen_range", "range",  35000,  Parser.TypeNumber)
    self.nFootStepSpreadRange   = Parser:Get("spread", "footstep",      5000,   Parser.TypeNumber)
    self.nHumanFireSpreadRange  = Parser:Get("spread", "human_fire",    35000,  Parser.TypeNumber)
    self.nShipFireSpreadRange   = Parser:Get("spread", "ship_fire",     35000,  Parser.TypeNumber)
    self.nCarrierSpreadRange    = Parser:Get("spread", "carrier",       35000,  Parser.TypeNumber)
end

return RadarmapSoundListenIni

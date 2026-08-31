--[[
    IniConfig类中必须有的成员变量与函数
    szFileName : 文件名，不包含路径
    Container: table
    OnParse： 解析函数，参数Parser
--]]

local ReconnectIni = {}
ReconnectIni.szFileName = "common/reconnect/reconnect.ini"

function ReconnectIni:OnParse(Parser)
    self.nAutoReconnectTime      = Parser:Get("Reconnect", "auto_reconnect_time",            10, Parser.TypeNumber)
    self.nManualReconnectCount   = Parser:Get("Reconnect", "manual_reconnect_count",         5,  Parser.TypeNumber)
    self.nManualReconnectTime    = Parser:Get("Reconnect", "manual_reconnect_time",          5,  Parser.TypeNumber)

    self.nWildWorldReconnectTime = Parser:Get("Reconnect", "wildworld_reconnect_Time",       60, Parser.TypeNumber)
    -- self.nLocalDungeonReconnectTime= Parser:Get("Reconnect", "localdungeon_reconnect_Time",    60, Parser.TypeNumber)
    -- self.nDungeonReconnectTime   = Parser:Get("Reconnect", "dungeon_reconnect_time",         60, Parser.TypeNumber)

    -- self.nDungeonParachutingStepTimeout = Parser:Get("Reconnect", "dungeon_parachuting_step_time_out", 5, Parser.TypeNumber)
    self.nDungeonWaitReconnectTime = Parser:Get("Reconnect", "dungeon_wait_reconnect_time", 10, Parser.TypeNumber)
    self.nDungeonDefaultSendReconnectInfoTime = Parser:Get("Reconnect", "dungeon_default_send_reconnect_info_time", 5, Parser.TypeNumber)
    self.nDungeonLoadingSendReconnectInfoTime = Parser:Get("Reconnect", "dungeon_loading_send_reconnect_info_time", 60, Parser.TypeNumber)
end

return ReconnectIni

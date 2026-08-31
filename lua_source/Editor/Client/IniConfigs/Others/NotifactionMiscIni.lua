--[[
    IniConfig类中必须有的成员变量与函数
    szFileName : 文件名，不包含路径
    Container: table
    OnParse： 解析函数，参数Parser
--]]

local NotifactionMiscIni = {}
NotifactionMiscIni.szFileName = "client/notifaction/NotifactionMisc.ini"

function NotifactionMiscIni:OnParse(Parser)
    local tbNotifaction = {}
    tbNotifaction.nSystemNotifySpeed = Parser:Get("System", "speed", -1, Parser.TypeNumber)
    tbNotifaction.nTopMsgSpeed = Parser:Get("TopMsg", "speed", -1, Parser.TypeNumber)
    self.tbNotifaction = tbNotifaction
end

return NotifactionMiscIni

--[[
    IniConfig类中必须有的成员变量与函数
    szFileName : 文件名，不包含路径
    Container: table
    OnParse： 解析函数，参数Parser
--]]

local ChangeDisplayIni = {}
ChangeDisplayIni.szFileName = "client/changedisplay/changedisplay.ini"

function ChangeDisplayIni:OnParse(Parser)
    local nPreChangeShipDistance = Parser:Get("change_display", "pre_change_ship_distance"      , -1, Parser.TypeNumber)
    self.nPreChangeShipDistance  = nPreChangeShipDistance * 100
    local nPreChangeHumanDistance = Parser:Get("change_display", "pre_change_human_distance"      , -1, Parser.TypeNumber)
    self.nPreChangeHumanDistance  = nPreChangeHumanDistance * 100
end

return ChangeDisplayIni

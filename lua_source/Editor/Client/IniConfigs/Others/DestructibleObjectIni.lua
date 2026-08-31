--[[
    IniConfig类中必须有的成员变量与函数
    szFileName : 文件名，不包含路径
    Container: table
    OnParse： 解析函数，参数Parser
--]]

local DestructibleObjectIni = {}

DestructibleObjectIni.szFileName = "client/destructibleobject/destructibleobject.ini"

function DestructibleObjectIni:OnParse(Parser)
    local tbInteractional = {}
    tbInteractional.nManualSwitchDoorDistance = Parser:Get("interactional", "manual_switch_door_distance", 1, Parser.TypeNumber)
    tbInteractional.nAutoSwitchDoorDistance = Parser:Get("interactional", "auto_switch_door_distance", 1, Parser.TypeNumber)
    if tbInteractional.nAutoSwitchDoorDistance >= tbInteractional.nManualSwitchDoorDistance then
        error("DestructibleObject auto interactional distance <= manual interactional distance")
    end
    self.tbInteractional = tbInteractional
end

return DestructibleObjectIni

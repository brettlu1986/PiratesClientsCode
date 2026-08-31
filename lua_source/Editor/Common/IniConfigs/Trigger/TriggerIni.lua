--[[
    IniConfig类中必须有的成员变量与函数
    szFileName : 文件名，不包含路径
    Container: table
    OnParse： 解析函数，参数Parser
--]]

local TriggerIni = {}
TriggerIni.szFileName = "common/ffa/trigger/trigger.ini"

function TriggerIni:OnParse(Parser)
    local tbPickTrigger = {}
    tbPickTrigger.nLandTriggerRadius =  Parser:Get("pick_trigger", "human_trigger_radius", -1, Parser.TypeNumber)
    tbPickTrigger.nOceanTriggerRadius =  Parser:Get("pick_trigger", "ship_trigger_radius", -1, Parser.TypeNumber)
    tbPickTrigger.nItemTriggerBaseRadius =  Parser:Get("pick_trigger", "item_trigger_base_radius", -1, Parser.TypeNumber)
    self.tbPickTrigger = tbPickTrigger
end

return TriggerIni

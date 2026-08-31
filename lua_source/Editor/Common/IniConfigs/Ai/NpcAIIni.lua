--[[
    IniConfig类中必须有的成员变量与函数
    szFileName : 文件名，不包含路径
    Container: table
    OnParse： 解析函数，参数Parser
--]]

local NpcAIIni = {}
NpcAIIni.szFileName = "common/ffa/ai/npc/npcai.ini"

function NpcAIIni:OnParse(Parser)
    self.nTriggerEnmity = Parser:Get("Enmity", "trigger_enmity",   -1, Parser.TypeNumber)
    self.nDamageEnmityScale = Parser:Get("Enmity", "damage_enmity_scale",  -1, Parser.TypeNumber)
    self.nHumanSwitchWeaponCD = Parser:Get("SwitchWeaponCD", "human",   -1, Parser.TypeNumber)
    self.nShipSwitchWeaponCD = Parser:Get("SwitchWeaponCD", "ship",   -1, Parser.TypeNumber)
end

return NpcAIIni

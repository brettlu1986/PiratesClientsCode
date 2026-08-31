--[[
    IniConfig类中必须有的成员变量与函数
    szFileName : 文件名，不包含路径
    Container: table
    OnParse： 解析函数，参数Parser
--]]

local BattlePickupIni = {}
BattlePickupIni.szFileName = "client/battlepickup/battle_pickup.ini"

function BattlePickupIni:OnParse(Parser)
    local tbBattlePickup = {}
    self.tbBattlePickup = tbBattlePickup
    
    tbBattlePickup.nSoundDistance = Parser:Get("battle_pickup", "sound_distance", 1000, Parser.TypeNumber)
    tbBattlePickup.nAutoPickupDelay = Parser:Get("battle_pickup", "auto_pickup_delay", 1000, Parser.TypeNumber)
    tbBattlePickup.nFirstAutoPickupDelay = Parser:Get("battle_pickup", "first_auto_pickup_delay", 1000, Parser.TypeNumber)
end

return BattlePickupIni

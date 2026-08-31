local SAILogicDef = require("SAILogicDef")

local SAILogicConfigDef = {
    [SAILogicDef.Bot] = "SAILogicConfigBot",
    [SAILogicDef.NpcBattle] = "SAILogicConfigNpcBattle",
 }

 function SAILogicConfigDef:GetConfig(nID)
    local tbConfig = SAILogicConfigDef[nID]
    assert(tbConfig, "get ai config error")
    return require(tbConfig)
 end

return SAILogicConfigDef
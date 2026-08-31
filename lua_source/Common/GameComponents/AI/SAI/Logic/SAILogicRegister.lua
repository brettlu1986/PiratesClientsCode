local SAILogicRegister = {}

local SAILogicDef = require("SAILogicDef")

local function Define(AIComponent, nID, szLogic)
    AIComponent:AddLogic(nID, szLogic)
end

function SAILogicRegister:RegisterLogic(AIComponent)
    Define(AIComponent, SAILogicDef.Bot, "SAILogicBot")
    Define(AIComponent, SAILogicDef.NpcBattle, "SAILogicNpcBattle")
end


return SAILogicRegister

local luaclass = require("luaclass")
local SAIThreatStrategyBase = require("SAIThreatStrategyBase")
local SAIThreatStrategyEnmity = luaclass("SAIThreatStrategyEnmity", SAIThreatStrategyBase)
local SAIPerceptionDef = require("SAIPerceptionDef")
local GameObjectSystem = dynamic_require("GameObjectSystem")

-- luacheck: push ignore
local function LOG(...)
    log("CJ->SAIThreatStrategyEnmity:", ...)
end
-- luacheck: pop


function SAIThreatStrategyEnmity:SelectTreat()
    local tbPerceptionSystem = self.tbPerceptionSystem
    local tbPerceptionEnmity = tbPerceptionSystem:GetPerception(SAIPerceptionDef.Enmity)
    local tbThreatObject = nil
    if tbPerceptionEnmity then
        local nInstanceId = tbPerceptionEnmity:GetHighestEnmityTarget()
        tbThreatObject = GameObjectSystem:FindByInstanceId(nInstanceId)
    end
    return tbThreatObject
end

return SAIThreatStrategyEnmity


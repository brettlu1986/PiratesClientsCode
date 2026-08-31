local luaclass = require("luaclass")
local SAIThreatStrategyBase = require("SAIThreatStrategyBase")
local SAIThreatStrategyRealPlayer = luaclass("SAIThreatStrategyRealPlayer", SAIThreatStrategyBase)

-- luacheck: push ignore
local function LOG(...)
    log("CJ->SAIThreatStrategyRealPlayer:", ...)
end
-- luacheck: pop


function SAIThreatStrategyRealPlayer:IsThreat(OtherAIEntityComponent)
    if not OtherAIEntityComponent:IsRealPlayer() then
        return false
    end
    return SAIThreatStrategyRealPlayer.super.IsThreat(self, OtherAIEntityComponent)
end





return SAIThreatStrategyRealPlayer
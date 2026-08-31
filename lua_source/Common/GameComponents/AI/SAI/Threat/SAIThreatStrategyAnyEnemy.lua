local luaclass = require("luaclass")
local SAIThreatStrategyBase = require("SAIThreatStrategyBase")
local SAIThreatStrategyAnyEnemy = luaclass("SAIThreatStrategyAnyEnemy", SAIThreatStrategyBase)

-- luacheck: push ignore
local function LOG(...)
    log("CJ->SAIThreatStrategyAnyEnemy:", ...)
end
-- luacheck: pop


return SAIThreatStrategyAnyEnemy
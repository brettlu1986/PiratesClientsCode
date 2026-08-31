local SAIThreatStrategyRegister = {}

local SAIThreatStrategyDef = require("SAIThreatStrategyDef")

function SAIThreatStrategyRegister:RegisterStrategy(tbThreatSystem)
    tbThreatSystem:AddStrategy(SAIThreatStrategyDef.AnyEnemy, "SAIThreatStrategyAnyEnemy")
    tbThreatSystem:AddStrategy(SAIThreatStrategyDef.RealPlayer, "SAIThreatStrategyRealPlayer")
    tbThreatSystem:AddStrategy(SAIThreatStrategyDef.Enmity, "SAIThreatStrategyEnmity")

end


return SAIThreatStrategyRegister
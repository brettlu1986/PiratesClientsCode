local SAIPerceptionDef = require("SAIPerceptionDef")

local SAIPerceptionFactory = { }

local tbPerceptionList = {
    [SAIPerceptionDef.Sight]        = "SAIPerceptionSight",
    [SAIPerceptionDef.Hearing]      = "SAIPerceptionHearing",
    [SAIPerceptionDef.Damage]       = "SAIPerceptionDamage",
    [SAIPerceptionDef.Alert]        = "SAIPerceptionAlert",
    [SAIPerceptionDef.Enmity]       = "SAIPerceptionEnmity",
}

function SAIPerceptionFactory:CreatePerception(nPerception)
    if tbPerceptionList[nPerception] then
        return require(tbPerceptionList[nPerception])()
    end
end


return SAIPerceptionFactory
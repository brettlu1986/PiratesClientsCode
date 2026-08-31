local luaclass = require("luaclass")
local BattleConditionBase = luaclass("BattleConditionBase")

function BattleConditionBase:Init()
end

function BattleConditionBase:Parse(tbJsonData)
    return false
end

function BattleConditionBase:Execute()
    return false
end

function BattleConditionBase:Uninit()
end

return BattleConditionBase
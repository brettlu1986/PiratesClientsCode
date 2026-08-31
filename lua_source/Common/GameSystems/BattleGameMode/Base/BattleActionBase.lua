local luaclass = require("luaclass")
local BattleActionBase = luaclass("BattleActionBase")

function BattleActionBase:Init()
end

function BattleActionBase:Parse(tbJsonData)
    return false
end

function BattleActionBase:Execute()
    return false
end

function BattleActionBase:Uninit()
end

function BattleActionBase:ForceStop()
end

return BattleActionBase
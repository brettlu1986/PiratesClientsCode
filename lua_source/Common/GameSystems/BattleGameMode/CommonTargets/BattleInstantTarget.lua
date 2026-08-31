-- 直接结束的Target

local luaclass = require("luaclass")
local BattleTargetBaseClass = require("BattleTargetBase")
local BattleInstantTarget = luaclass("BattleInstantTarget", BattleTargetBaseClass)

function BattleInstantTarget:Init()
    BattleInstantTarget.super.Init(self)
    self.szName = "BattleInstantTarget"
end

function BattleInstantTarget:Start()
    BattleInstantTarget.super.Start(self)
    self:Complete()
end

function BattleInstantTarget:Parse(tbJsonData)
    return true
end

return BattleInstantTarget
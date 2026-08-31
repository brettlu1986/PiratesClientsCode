-- 黑板int值比较

local luaclass = require("luaclass")
local BattleBlackboardTargetBase = require("BattleBlackboardTargetBase")
local BattleBlackboardIntTarget = luaclass("BattleBlackboardIntTarget", BattleBlackboardTargetBase)

local BattleCheckIntCondition = require("BattleCheckIntCondition")

function BattleBlackboardIntTarget:Init()
    BattleBlackboardIntTarget.super.Init(self)
    self.szName = "BattleBlackboardIntTarget"    
end

function BattleBlackboardIntTarget:Check()
    return BattleCheckIntCondition.StaticCheck(self.szOperator, 
        self.szKey1, self.szKey2, self.Value2)
end

return BattleBlackboardIntTarget

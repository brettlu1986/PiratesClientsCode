-- 黑板string值比较

local luaclass = require("luaclass")
local BattleBlackboardTargetBase = require("BattleBlackboardTargetBase")
local BattleBlackboardStringTarget = luaclass("BattleBlackboardStringTarget", BattleBlackboardTargetBase)

local BattleCheckStringCondition = require("BattleCheckStringCondition")

function BattleBlackboardStringTarget:Init()
    BattleBlackboardStringTarget.super.Init(self)
    self.szName = "BattleBlackboardStringTarget"    
end

function BattleBlackboardStringTarget:Check()
    return BattleCheckStringCondition.StaticCheck(self.szOperator, 
        self.szKey1, self.szKey2, self.Value2)
end

return BattleBlackboardStringTarget

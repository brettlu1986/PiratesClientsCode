-- 黑板bool值比较

local luaclass = require("luaclass")
local BattleBlackboardTargetBase = require("BattleBlackboardTargetBase")
local BattleBlackboardBoolTarget = luaclass("BattleBlackboardBoolTarget", BattleBlackboardTargetBase)

local BattleCheckBoolCondition = require("BattleCheckBoolCondition")

function BattleBlackboardBoolTarget:Init()
    BattleBlackboardBoolTarget.super.Init(self)
    self.szName = "BattleBlackboardBoolTarget"    
end

function BattleBlackboardBoolTarget:Check()
    return BattleCheckBoolCondition.StaticCheck(self.szOperator, 
        self.szKey1, self.szKey2, self.Value2)
end

return BattleBlackboardBoolTarget

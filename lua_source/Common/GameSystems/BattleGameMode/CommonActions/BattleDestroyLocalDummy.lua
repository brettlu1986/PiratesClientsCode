local luaclass                = require("luaclass")
local BattleActionBase        = require("BattleActionBase")
local BattleDestroyLocalDummy = luaclass("BattleDestroyLocalDummy", BattleActionBase)
local BattleDummyHelper       = require("BattleDummyHelper")
local GameObjectSystem        = dynamic_require("GameObjectSystem")

BattleDestroyLocalDummy.nGroupId    = 0

function BattleDestroyLocalDummy:Parse(tbJsonData)    
    BattleDestroyLocalDummy.super.Parse(self, tbJsonData)

    self.nGroupId = tbJsonData.GroupId

    return true
end

function BattleDestroyLocalDummy:Execute()
    local nGroupId = self.nGroupId
    local tbDummies = BattleDummyHelper:GetDummiesByGroupId(nGroupId)
    if tbDummies == nil then 
        return true
    end

    for i, tbDummy in pairs(tbDummies) do
        GameObjectSystem:DestroyDummyInGameMode(tbDummy:GetUEActorUniqueId())
    end

    BattleDummyHelper:DeleteDummiesByGroupId(nGroupId)

    return true
end


return BattleDestroyLocalDummy
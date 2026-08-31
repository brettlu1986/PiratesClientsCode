local luaclass = require("luaclass")
local BattleTargetBaseClass = require("BattleTargetBase")
local BattleIntoFightTarget = luaclass("BattleIntoFightTarget", BattleTargetBaseClass)

-- local EventManager = require("EventManager")
-- local CommonEventDef = require("CommonEventDef")


function BattleIntoFightTarget:Init()
    BattleIntoFightTarget.super.Init(self)
    self.szName = "BattleIntoFightTarget"
end

function BattleIntoFightTarget:RegisterEvent()
    BattleIntoFightTarget.super.RegisterEvent(self)
    -- EventManager:BindEventMethod(CommonEventDef.EV_BATTLE_IntoFight, self, self.OnIntoFight)
end

function BattleIntoFightTarget:Parse(tbJsonData)
   return true
end

function BattleIntoFightTarget:OnIntoFight()
    self:Complete()
end

function BattleIntoFightTarget:UnregisterEvent()
    -- EventManager:UnBindEventMethod(CommonEventDef.EV_BATTLE_IntoFight, self, self.OnIntoFight)
end

return BattleIntoFightTarget
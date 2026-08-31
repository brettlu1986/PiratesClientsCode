--Matinee播放完成

local luaclass = require("luaclass")
local BattleTargetBaseClass = require("BattleTargetBase")
local BattlePlayMatineeEndTarget = luaclass("BattlePlayMatineeEndTarget", BattleTargetBaseClass)

local EventManager = require("EventManager")
local CommonEventDef = require("CommonEventDef")


function BattlePlayMatineeEndTarget:Init()
    BattlePlayMatineeEndTarget.super.Init(self)
    self.szName = "BattlePlayMatineeEndTarget"
end

function BattlePlayMatineeEndTarget:RegisterEvent()
    BattlePlayMatineeEndTarget.super.RegisterEvent(self)
    EventManager:BindEventMethod(CommonEventDef.EV_BATTLE_MATINEE_END, self, self.OnPlayMatineEnd)
end


function BattlePlayMatineeEndTarget:Parse(tbJsonData)
    return true
end

function BattlePlayMatineeEndTarget:UnregisterEvent()
    EventManager:UnBindEventMethod(CommonEventDef.EV_BATTLE_MATINEE_END, self, self.OnPlayMatineEnd)
end

function BattlePlayMatineeEndTarget:OnPlayMatineEnd()
    self:Complete()
end


return BattlePlayMatineeEndTarget
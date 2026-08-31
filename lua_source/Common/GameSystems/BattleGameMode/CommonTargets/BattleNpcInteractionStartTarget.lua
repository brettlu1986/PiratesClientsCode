--副本开始与npc交互

local luaclass = require("luaclass")
local BattleTargetBaseClass = require("BattleTargetBase")
local BattleNpcInteractionStartTarget = luaclass("BattleNpcInteractionStartTarget", BattleTargetBaseClass)

local EventManager = require("EventManager")
local CommonEventDef = require("CommonEventDef")

function BattleNpcInteractionStartTarget:Init()
    BattleNpcInteractionStartTarget.super.Init(self)
    
    self.szName = "BattleNpcInteractionStartTarget"
end

function BattleNpcInteractionStartTarget:RegisterEvent()
    BattleNpcInteractionStartTarget.super.RegisterEvent(self)
    EventManager:BindEventMethod(CommonEventDef.EV_BATTLE_INTERACTIONDLG_START_NPC, self, self.OnStartInteraction)
end


function BattleNpcInteractionStartTarget:Parse(tbJsonData)
   return true
end

function BattleNpcInteractionStartTarget:OnStartInteraction(nNpcServerInstanceId, nPlayerServerInstanceId)
    self:Complete()
end

function BattleNpcInteractionStartTarget:UnregisterEvent()
    EventManager:UnBindEventMethod(CommonEventDef.EV_BATTLE_INTERACTIONDLG_START_NPC, self, self.OnStartInteraction)
end

return BattleNpcInteractionStartTarget
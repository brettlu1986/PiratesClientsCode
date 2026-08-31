--副本开始与npc交互

local luaclass = require("luaclass")
local BattleTargetBaseClass = require("BattleTargetBase")
local BattleTariggerNpcInteractionTarget = luaclass("BattleTariggerNpcInteractionTarget", BattleTargetBaseClass)

local EventManager = require("EventManager")
local CommonEventDef = require("CommonEventDef")
local GameObjectSystem =  dynamic_require("GameObjectSystem")
local BattleNpcHelper = require("BattleNpcHelper")


function BattleTariggerNpcInteractionTarget:Init()
    BattleTariggerNpcInteractionTarget.super.Init(self)
    
    self.szName = "BattleTariggerNpcInteractionTarget"
end

function BattleTariggerNpcInteractionTarget:RegisterEvent()
    BattleTariggerNpcInteractionTarget.super.RegisterEvent(self)
    EventManager:BindEventMethod(CommonEventDef.EV_BATTLE_TARIGGER_INTERACTION,self,self.OnTariggerInteraction)
end


function BattleTariggerNpcInteractionTarget:OnTariggerInteraction(nNpcServerInstanceId)
    local tbNpc = GameObjectSystem:FindByInstanceId(nNpcServerInstanceId)
    if tbNpc ~= nil then
        if( BattleNpcHelper:CheckIdentifier(self, tbNpc))  then
            self:Complete()
        end
    end
end

function BattleTariggerNpcInteractionTarget:UnregisterEvent()
    EventManager:UnBindEventMethod(CommonEventDef.EV_BATTLE_TARIGGER_INTERACTION,self,self.OnTariggerInteraction)
end

function BattleTariggerNpcInteractionTarget:Parse(tbJsonData)
    BattleNpcHelper:ParseIdentifier(self, tbJsonData)
    return true
end

return BattleTariggerNpcInteractionTarget
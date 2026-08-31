local luaclass = require("luaclass")
local AIVariableSystem = luaclass("AIVariableSystem")
local SelfEventHelperClass  = require("SelfEventHelper")
local CommonEventDef        = require("CommonEventDef")
local AIHelper              = require("AIHelper")
local GlobalVariableSystem  = dynamic_require("GlobalVariableSystem")
local GameObjectTypeDef     = require("GameObjectTypeDef")
local RadarmapSoundListenIni = require("RadarmapSoundListenIni")
local RadarMapSoundDataTable = require("RadarMapSoundDataTable")
local GameObjectSystem       = dynamic_require("GameObjectSystem")
local BattleShipWeaponSystem = dynamic_require("BattleShipWeaponSystem")

AIVariableSystem.bBattleStarted = false
AIVariableSystem.SelfEventHelper = nil
AIVariableSystem.nReplicatesLimitCount = 30

local function LOG(...)
     log("CJ->AIVariableSystem:", ...)
 end


function AIVariableSystem:Init()
     self.bBattleStarted = false
     local SelfEventHelper = SelfEventHelperClass()
     self.SelfEventHelper = SelfEventHelper
     SelfEventHelper:RegisterEvent(CommonEventDef.EV_PERCEPTION_WEAPON_FIRE_SOUND,  self, self.OnWeaponFired)
     SelfEventHelper:RegisterEvent(CommonEventDef.EV_GAME_OBJECT_POST_ACTOR_CREATE,  self, self.OnActorCreated)
     SelfEventHelper:RegisterEvent(CommonEventDef.EV_GAME_OBJECT_ON_PAWN_DEAD,      self, self.OnDead)
     SelfEventHelper:RegisterEvent(CommonEventDef.EV_GAME_OBJECT_PRE_UNBIND_UEACTOR_DESTROY,  self, self.OnActorPreDestroy)
     return true
end

function AIVariableSystem:OnWeaponFired(nServerInstanceId, tbLocation)
     local tbObject = GameObjectSystem:FindByInstanceId(nServerInstanceId)
     if tbObject and tbObject:IsAlive() then
         if tbObject:IsHuman() then
             local nHumanWeaponTemplateId = tbObject.HumanWeaponComponent:GetCurrentWeaponTemplateId()
             local nRange = RadarMapSoundDataTable:GetWeaponRadius(nHumanWeaponTemplateId) or RadarmapSoundListenIni.nHumanFireSpreadRange
             AIHelper.ReportSoundEvent(nil, tbObject, 1, nRange, "Fire")
         else
             local nShipWeaponTemplateId = BattleShipWeaponSystem:GetActiveWeaponItem(tbObject):GetTemplateId()
             local nRange = RadarMapSoundDataTable:GetWeaponRadius(nShipWeaponTemplateId) or RadarmapSoundListenIni.nShipFireSpreadRange
             AIHelper.ReportSoundEvent(nil, tbObject, 1, nRange, "Fire")
         end
     end
 end


function AIVariableSystem:OnActorCreated(tbGameObject)
     if GlobalVariableSystem:IsServerLogic() and tbGameObject.ObjectType == GameObjectTypeDef.PlayerSelf then
         local pUEActor = tbGameObject.pUEActor
         AIHelper.RegisterWithPerceptionSystem(pUEActor)
         LOG("registered PerceptionSystem", tbGameObject.szName)
     end
 end

 function AIVariableSystem:OnActorPreDestroy(tbGameObject)
     if GlobalVariableSystem:IsServerLogic() and tbGameObject.ObjectType == GameObjectTypeDef.PlayerSelf then
         local pUEActor = tbGameObject.pUEActor
         AIHelper.UnregisterFromPerceptionSystem(pUEActor)
         LOG("unregister PerceptionSystem", tbGameObject.szName)
     end
 end

 function AIVariableSystem:OnDead(tbGameObject)
     if GlobalVariableSystem:IsServerLogic() and tbGameObject.ObjectType == GameObjectTypeDef.PlayerSelf then
         local pUEActor = tbGameObject.pUEActor
         AIHelper.UnregisterFromPerceptionSystem(pUEActor)
         LOG("unregister PerceptionSystem", tbGameObject.szName)
     end
end

function AIVariableSystem:SetBattleStart(bStarted)
     self.bBattleStarted = bStarted
end

function AIVariableSystem:IsBattleStarted()
     return self.bBattleStarted
end


function AIVariableSystem:Uninit()
     self.SelfEventHelper:UnregisterAll()
end


return AIVariableSystem()

local luaclass = require("luaclass")
local HumanMovementStateSwimming = require("HumanMovementStateSwimming")
local HumanMovementStateSwimming_C = luaclass("HumanMovementStateSwimming_C", HumanMovementStateSwimming)
local ClientEventDef = require("ClientEventDef")
local EventManager = require("EventManager")
local HumanWeaponStateDef = require("HumanWeaponStateDef")

function HumanMovementStateSwimming_C:Active(tbParams)
    if self.bServer then  
        HumanMovementStateSwimming_C.super.Active(self, tbParams)
        return
    end 
    self:ChangeCapsule()
    if self.bSelf then  
        EventManager:OnFireEvent(ClientEventDef.EV_EXIT_OPEN_AIM_CAMERA)
    end
    
    local HumanWeaponComponent = self.GamePlayer.HumanWeaponComponent
    local StateHelper = HumanWeaponComponent.StateHelper
    if not HumanWeaponComponent or not StateHelper then  
        return 
    end
    HumanWeaponComponent:CancelAttack()
    StateHelper:ChangeState(HumanWeaponStateDef.UNHOLDED, true)
    EngineExtActorShell.SetActorMeshTranslucency(self.pOwnerActor, -2)
end

function HumanMovementStateSwimming_C:UnActive(tbParams)
    if self.bServer then  
        HumanMovementStateSwimming_C.super.UnActive(self, tbParams)
        return
    end 
    self.pOwnerActor:AbortNavMove()
    EngineExtActorShell.SetActorMeshTranslucency(self.pOwnerActor, 0)
end

return HumanMovementStateSwimming_C
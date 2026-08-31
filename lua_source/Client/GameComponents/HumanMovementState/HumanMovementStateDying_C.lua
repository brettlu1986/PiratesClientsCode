local luaclass = require("luaclass")
local HumanMovementStateDying = require("HumanMovementStateDying")
local HumanMovementStateDying_C = luaclass("HumanMovementStateDying_C", HumanMovementStateDying)
local ClientEventDef = require("ClientEventDef")
local EventManager = require("EventManager")
local BattleHumanWeaponSystemNew = dynamic_require("BattleHumanWeaponSystemNew")
local HumanWeaponHelper = require("HumanWeaponHelper")

function HumanMovementStateDying_C:Active(tbParams)
    HumanMovementStateDying_C.super.Active(self, tbParams)
    --停掉Montage, 投掷物拉开引线的montage是个循环动作， 如果不停掉的话 其他人可能看不到montage
    local pUEActor = self.pOwnerActor
    pUEActor:StopAnimMontage(nil)

    if self.bSelf then  
        EventManager:OnFireEvent(ClientEventDef.EV_EXIT_OPEN_AIM_CAMERA)
        BattleHumanWeaponSystemNew:RequestCancelAttack()
    end
end

function HumanMovementStateDying_C:UnActive(tbParams)
    HumanMovementStateDying_C.super.UnActive(self, tbParams)
    local GamePlayer = self.Owner.Owner
    local WeaponComponent = GamePlayer.HumanWeaponComponent
    if(WeaponComponent and WeaponComponent.bPlayerSelf ) then
        local HumanWeaponComponent = self.GamePlayer.HumanWeaponComponent
        HumanWeaponHelper.TryReload(HumanWeaponComponent)
    end
end

return HumanMovementStateDying_C
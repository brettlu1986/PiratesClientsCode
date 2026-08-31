local luaclass = require("luaclass")
local HumanMovementStateBase = dynamic_require("HumanMovementStateBase")
local HumanMovementStateDying = luaclass("HumanMovementStateDying", HumanMovementStateBase)

local AIHelper = require("AIHelper")
local BattleHumanWeaponSystemNew = dynamic_require("BattleHumanWeaponSystemNew")

function HumanMovementStateDying:Active(tbParams)
    --停掉Montage, 投掷物拉开引线的montage是个循环动作， 如果不停掉的话 其他人可能看不到montage
    self.pOwnerActor:StopAnimMontage(nil)

    self:ChangeCapsule()
    self:BlendCameraWithTime()

    local GamePlayer = self.Owner.Owner
    if self.bServer and GamePlayer and AIHelper.IsAIControlled(GamePlayer) then
        local HumanWeaponComponent = BattleHumanWeaponSystemNew:GetComponent(GamePlayer)
        if HumanWeaponComponent then
            HumanWeaponComponent:CancelCheatAttack()
        end
    end
end

function HumanMovementStateDying:UnActive(tbParams)

end

return HumanMovementStateDying
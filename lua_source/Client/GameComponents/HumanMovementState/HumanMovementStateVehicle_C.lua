local luaclass = require("luaclass")
local HumanMovementStateVehicle = require("HumanMovementStateVehicle")
local HumanMovementStateVehicle_C = luaclass("HumanMovementStateVehicle_C", HumanMovementStateVehicle)

local HumanWeaponStateDef = require("HumanWeaponStateDef")
local BattleHumanWeaponSystemNew = dynamic_require("BattleHumanWeaponSystemNew")

function HumanMovementStateVehicle_C:Active(tbParams)
    HumanMovementStateVehicle_C.super.Active(self, tbParams)

    local GamePlayer = self.GamePlayer
    local HumanWeaponComponent = GamePlayer.HumanWeaponComponent
    if HumanWeaponComponent:GetCurrentState() == HumanWeaponStateDef.ATTACKING then
        HumanWeaponComponent:CancelAttack()
    end
    HumanWeaponComponent.StateHelper:ChangeState(HumanWeaponStateDef.UNHOLDED, true)
end

function HumanMovementStateVehicle_C:UnActive(tbParams)
    HumanMovementStateVehicle_C.super.UnActive(self, tbParams)

    local GamePlayer = self.GamePlayer
    local GameVehicleComponent = GamePlayer.GameVehicleComponent
    if GameVehicleComponent and GameVehicleComponent:IsInVehicle() then
        return
    end
    local SaveWeapon = BattleHumanWeaponSystemNew:GetSavedCurrentWeaponFromOwner(GamePlayer)
    if SaveWeapon ~= 0 then 
        -- 切一下状态以拿出武器
        BattleHumanWeaponSystemNew:GetComponent(GamePlayer):ChangeState(HumanWeaponStateDef.UNHOLDED, true)
    end
end

return HumanMovementStateVehicle_C
local luaclass = require("luaclass")
local HumanWeaponProjectile = dynamic_require("HumanWeaponProjectile")
local HumanWeaponDualWield = luaclass("HumanWeaponDualWield", HumanWeaponProjectile)
local HumanWeaponMisc = require("HumanWeaponMisc")

local SELF_TYPE = HumanWeaponMisc.Type.DUAL_WIELD

local tbHumanBowPreAttact = {}
function HumanWeaponDualWield:OnCreated(OwnerComponent, nInstanceId, nTemplateId, nSlot)
    HumanWeaponDualWield.super.OnCreated(self, OwnerComponent, nInstanceId, nTemplateId, nSlot)
    self.rHumanDualWieldAttack = OwnerComponent.rHumanDualWieldAttack
end

function HumanWeaponDualWield:GetType()
    return SELF_TYPE
end

function HumanWeaponDualWield:DualWieldAttack(bLeftWeapon)
    tbHumanBowPreAttact.weapon_id = self.nInstanceId
    tbHumanBowPreAttact.left_weapon = bLeftWeapon
    self:RepAttack(self.rHumanDualWieldAttack, tbHumanBowPreAttact)
end

return HumanWeaponDualWield
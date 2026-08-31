local PropUtil = require("PropUtil")
local GameObjectSystem = dynamic_require("GameObjectSystem")
local DamageTypeEx = require("DamageTypeEx")

--local FN_GET_COMPONENT_FROM_HIT_RESULT = ExtendBlueprintFunctions.GetComponentFromHitResult

return function(tbTaker, nActualDamage, pDamageCauser, pHitResult)
    --local pHitComponent = FN_GET_COMPONENT_FROM_HIT_RESULT(pHitResult)
    -- local szHitName = KismetSystemLibrary.GetObjectName(pHitComponent)
    local tbRealCauser = GameObjectSystem:FindByInstanceId(pDamageCauser.OwnerInstanceId)

    local tbDamageExtraData = {}
    tbDamageExtraData.nWeaponTemplateId = pDamageCauser.TemplateId
    PropUtil.ApplyDamage(tbTaker, tbRealCauser, DamageTypeEx.HUMAN_GRENADE, nActualDamage, tbDamageExtraData)
end
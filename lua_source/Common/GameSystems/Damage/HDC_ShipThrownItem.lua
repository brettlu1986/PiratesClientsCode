-----------------------------------------------------
--File Name    : HDC_ShipBullet.lua
--Author       :
--Create Time  :
--Description  : 计算船对人的伤害
-----------------------------------------------------
local DungeonIni = require("DungeonIni")
local DamageTypeEx = require("DamageTypeEx")
local RelationshipSystem = require("RelationshipSystem")
local ShipThrownItemSubCategoryDef = require("ShipThrownItemSubCategoryDef")
local GameObjectSystem = dynamic_require("GameObjectSystem")
local BattleItemDataTable = require("BattleItemDataTable")

-- local MAX_DISTANCE_DAMAGE_RATIO = 1

-- local function CalculatePointY(nX1, nY1, nX2, nY2, nDistance)
--     local nK = (nY2 - nY1) / (nX2 - nX1)
--     return nK * (nDistance - nX1) + nY1
-- end

local function GetCauser(pDamageCauser)
    local nInstigatorInstanceId = pDamageCauser:GetInstigatorInstanceId()
    return GameObjectSystem:FindByInstanceId(nInstigatorInstanceId)
end

return function (tbTaker, nActualDamage, pDamageCauser, pHitResult)
    local tbCauser = GetCauser(pDamageCauser)
    if (not tbCauser) or RelationshipSystem:IsFriendRelation(tbTaker, tbCauser) then
        return
    end

    -- 获取Weapon相关信息
    local nThrownItemTemplateId = pDamageCauser.WeaponId
    local tbThrownItemtemplate = BattleItemDataTable:GetTemplate(nThrownItemTemplateId)
    if not tbThrownItemtemplate then
        logerror("[SDC_ShipThrownItem] Cannot find ThrownItemtemplate, nThrownItemTemplateId =", nThrownItemTemplateId)
        return
    end
    local nThrownItemSubCategory = tbThrownItemtemplate.nSubCategory

    -- 不伤害非游泳状态的人
    if (nThrownItemSubCategory == ShipThrownItemSubCategoryDef.TORPEDO)
    and tbTaker.pUEActor
    and tbTaker.pUEActor.CharacterMovement
    and (tbTaker.pUEActor.CharacterMovement.MovementMode ~= EMovementMode.MOVE_Swimming) then
        return
    end

    -- 人船互打需要进行伤害折算
    local nHumanDamageRatioFromShip = DungeonIni.tbFFA.nHumanDamageRatioFromShip
    nActualDamage = nActualDamage * nHumanDamageRatioFromShip

    ---------------------------------- 伤害逻辑分界线，以上计算与船无关，以下计算与船相关 ----------------------------------------

    -- 人的伤害处理逻辑

    -- 应用伤害
    local tbDamageExtraData = {}
    tbDamageExtraData.nWeaponTemplateId = nThrownItemTemplateId
    local nDamageType = DamageTypeEx.SHIP_THROWN_ITEM_BEGIN + nThrownItemSubCategory
    tbTaker.HumanBattlePropertyComponent:ApplyDamage(tbCauser, nDamageType, nActualDamage, tbDamageExtraData)
end
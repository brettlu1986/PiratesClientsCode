-----------------------------------------------------
--File Name    : SDC_ShipFlamer.lua
--Author       : Song Fuhao
--Create Time  : 2019-01-22
--Description  : 用于处理喷火器伤害（对船）
-----------------------------------------------------
local SDCHelper = require("SDCHelper")
local DamageTypeEx = require("DamageTypeEx")
local RelationshipSystem = require("RelationshipSystem")
local ShipWeaponSubCategoryDef = require("ShipWeaponSubCategoryDef")
local GameObjectSystem = dynamic_require("GameObjectSystem")
local BattleShipWeaponSystem = dynamic_require("BattleShipWeaponSystem")

local FLAMER_BUFF_ID = 31001

local function GetCauser(pDamageCauser)
    local pInstigator = pDamageCauser:GetInstigator()
    if isvalidhandle(pInstigator) then
        return GameObjectSystem:FindByUEActor(pInstigator)
    end
    return nil
end

return function(tbTaker, nActualDamage, pDamageCauser, pHitResult)
    -- 免疫找不到Causer或队友的伤害
    local tbCauser = GetCauser(pDamageCauser)
    if (not tbCauser) or RelationshipSystem:IsFriendRelation(tbTaker, tbCauser) then
        return
    end

    tbTaker.BuffComponentServer:AddBuffWithInstigator(tbCauser, FLAMER_BUFF_ID)

    -- 船基础伤害叠加
    nActualDamage = BattleShipWeaponSystem:GetWeaponAttack(tbCauser, ShipWeaponSubCategoryDef.FLAMER, nActualDamage)

    SDCHelper.LOG("喷火器造成伤害：%f", nActualDamage)

    -- 应用伤害
    local tbDamageExtraData = {}
    local WeaponItem = BattleShipWeaponSystem:GetActiveWeaponItem(tbCauser)
    if WeaponItem then
        tbDamageExtraData.nWeaponId = WeaponItem:GetInstanceId()
        tbDamageExtraData.nWeaponTemplateId = WeaponItem:GetTemplateId()
    end
    tbTaker.ShipBattlePropertyComponent:ApplyDamage(tbCauser, DamageTypeEx.SHIP_FLAMER, nActualDamage, tbDamageExtraData)
end
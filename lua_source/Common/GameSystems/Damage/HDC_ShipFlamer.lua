-----------------------------------------------------
--File Name    : HDC_ShipFlamer.lua
--Author       : Song Fuhao
--Create Time  : 2019-01-22
--Description  : 用于处理喷火器伤害（对人）
-----------------------------------------------------
local GameObjectSystem = dynamic_require("GameObjectSystem")
local RelationshipSystem = require("RelationshipSystem")

local DungeonIni = require("DungeonIni")
local DamageTypeEx = require("DamageTypeEx")
local ShipWeaponSubCategoryDef = require("ShipWeaponSubCategoryDef")
local BattleShipWeaponSystem = dynamic_require("BattleShipWeaponSystem")

local FLAMER_BUFF_ID = 80005

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

    -- 人船互打需要进行伤害折算
    local nHumanDamageRatioFromShip = DungeonIni.tbFFA.nHumanDamageRatioFromShip
    nActualDamage = nActualDamage * nHumanDamageRatioFromShip

    -- 应用伤害
    local tbDamageExtraData = {}
    local WeaponItem = BattleShipWeaponSystem:GetActiveWeaponItem(tbCauser)
    if WeaponItem then
        tbDamageExtraData.nWeaponId = WeaponItem:GetInstanceId()
        tbDamageExtraData.nWeaponTemplateId = WeaponItem:GetTemplateId()
    end
    tbTaker.HumanBattlePropertyComponent:ApplyDamage(tbCauser, DamageTypeEx.SHIP_FLAMER, nActualDamage, tbDamageExtraData)
end
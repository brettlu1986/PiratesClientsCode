-----------------------------------------------------
--File Name    : HDC_ShipEmbolon.lua
--Author       : Song Fuhao
--Create Time  : 2018-08-29
--Description  : 计算船受到的伤害（来自舰船撞角）
-----------------------------------------------------
local DamageTypeEx = require("DamageTypeEx")
-- local BattleItemSystemHelper = require("BattleItemSystemHelper")
local RelationshipSystem = require("RelationshipSystem")
local GameObjectSystem = dynamic_require("GameObjectSystem")

local function GetCauser(pDamageCauser)
    if isvalidhandle(pDamageCauser) then
        return GameObjectSystem:FindByUEActor(pDamageCauser)
    end
    return nil
end

return function (tbTaker, nActualDamage, pDamageCauser, pHitResult)
    local tbCauser = GetCauser(pDamageCauser)
    if RelationshipSystem:IsFriendRelation(tbTaker, tbCauser) then
        return
    end

    -- 获取Weapon相关信息
    -- local pEmbolonComponent = tbCauser.pUEActor.EmbolonComponent
    -- local nWeaponId = pEmbolonComponent:GetWeaponId()
    -- local WeaponItem = BattleItemSystemHelper:GetItem(nWeaponId, false)

    -- 获取受伤的人的血量
    local TakerPropertyComponent = tbTaker.HumanBattlePropertyComponent

    -- 应用伤害
    local tbDamageExtraData = {}
    -- tbDamageExtraData.nWeaponId = nWeaponId
    -- tbDamageExtraData.nWeaponTemplateId = WeaponItem:GetTemplateId()
    local nDamage = TakerPropertyComponent:GetMaxDyingHp() + TakerPropertyComponent:GetMaxHp()
    TakerPropertyComponent:ApplyDamage(tbCauser, DamageTypeEx.SHIP_BUMPING, nDamage, tbDamageExtraData)
end
-----------------------------------------------------
--File Name    : FFAHumanUIHelper.lua
--Author       : WuJizhou
--Create Time  : 4/2/2019, 3:14:25 PM
--Description  : FFAHumanUIHelper
-----------------------------------------------------
local BattleItemSystemHelper = require("BattleItemSystemHelper")
local BattleItemCategoryDef = require("BattleItemCategoryDef")
local HumanWeaponDef = require("HumanWeaponDef")
local GamePlayerSelfHelper = require("GamePlayerSelfHelper")
local FFAHumanUIHelper = {}

function FFAHumanUIHelper.GetSelfWeaponComponent()
    return GamePlayerSelfHelper:Get().HumanWeaponComponent
end

function FFAHumanUIHelper.IsEmptyInHand(nNewWeapon)
    local bResult = false
    if not nNewWeapon or nNewWeapon == 0 then
        bResult = true
    end
    return bResult
end

function FFAHumanUIHelper.IsMeleeWeaponInHand(nNewWeapon)
    local bResult = false
    if nNewWeapon > 0 then
        local tbWeaponItem = BattleItemSystemHelper:GetItem(nNewWeapon, true)
        if not tbWeaponItem then
            log("UPFFAHuman:IsMeleeWeaponInHand,tbWeaponItem is nil, nNewWeapon=",nNewWeapon)
            return
        end
        if(tbWeaponItem:GetCategory() == BattleItemCategoryDef.HUMAN_WEAPON) then
            local nPrimaryCategory = tbWeaponItem:GetTemplate().nPrimaryCategory
            if nPrimaryCategory == HumanWeaponDef.WeaponPrimaryCategory.Melee then
                bResult = true
            end
        end
    end
    return bResult
end

function FFAHumanUIHelper.IsThrownItemInHand(nNewWeapon)
    local bResult = false
    if nNewWeapon > 0 then
        local tbWeaponItem = BattleItemSystemHelper:GetItem(nNewWeapon, true)
        if not tbWeaponItem then
            log("UPFFAHuman:IsThrownItemInHand,tbWeaponItem is nil, nNewWeapon=",nNewWeapon)
            return bResult
        end
        if(tbWeaponItem:GetCategory() == BattleItemCategoryDef.HUMAN_THROWN_ITEM) then
            bResult = true
        end
    end
    return bResult
end

return FFAHumanUIHelper
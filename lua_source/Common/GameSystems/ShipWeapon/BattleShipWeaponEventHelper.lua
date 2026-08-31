-----------------------------------------------------
--File Name    : BattleShipWeaponEventHelper.lua
--Author       : Song Fuhao
--Create Time  : 2020-08-13
--Description  : 
-----------------------------------------------------
local BattleShipWeaponEventHelper = {}

local EventManager = require("EventManager")
local CommonEventDef = require("CommonEventDef")
local ClientEventDef = nil

local function LoadClientEventDef()
    if not ClientEventDef then
        ClientEventDef = require("ClientEventDef")
    end
end

function BattleShipWeaponEventHelper.FireOnShipWeaponFiredEvent(WeaponItem, nFiringCount)
    local tbCharacter = WeaponItem:GetOwnerCharacter()
    if WeaponItem:IsServerInstance() then
        EventManager:OnFireEvent(CommonEventDef.EV_PERCEPTION_WEAPON_FIRE_SOUND, WeaponItem:GetOwnerCharacterInstanceId())
        EventManager:OnFireEvent(CommonEventDef.EV_ON_SHIP_WEAPON_FIRED_SERVER, tbCharacter, WeaponItem, nFiringCount)
    else
        LoadClientEventDef()
        EventManager:OnFireEvent(ClientEventDef.EV_ON_SHIP_WEAPON_FIRED_CLIENT, tbCharacter, WeaponItem, nFiringCount)
    end
end

function BattleShipWeaponEventHelper.FireOnShipWeaponFiringSuccessEvent(WeaponItem)
    local tbCharacter = WeaponItem:GetOwnerCharacter()
    if WeaponItem:IsServerInstance() then
        EventManager:OnFireEvent(CommonEventDef.EV_ON_SHIP_WEAPON_FIRING_SUCCEED_SERVER, tbCharacter, WeaponItem)
    else
        LoadClientEventDef()
        EventManager:OnFireEvent(ClientEventDef.EV_ON_SHIP_WEAPON_FIRING_SUCCEED_CLIENT, tbCharacter, WeaponItem)
    end
end

function BattleShipWeaponEventHelper.FireOnShipWeaponBulletLoadBeganEvent(WeaponItem, nBulletLoadingTime, nBulletLoadingStartTime)
    local tbCharacter = WeaponItem:GetOwnerCharacter()
    if WeaponItem:IsServerInstance() then
        EventManager:OnFireEvent(CommonEventDef.EV_ON_SHIP_WEAPON_BULLET_LOAD_BEGAN_SERVER, tbCharacter, WeaponItem, nBulletLoadingTime, nBulletLoadingStartTime)
    else
        LoadClientEventDef()
        EventManager:OnFireEvent(ClientEventDef.EV_ON_SHIP_WEAPON_BULLET_LOAD_BEGAN_CLIENT, tbCharacter, WeaponItem, nBulletLoadingTime, nBulletLoadingStartTime)
    end
end

function BattleShipWeaponEventHelper.FireOnShipWeaponBulletLoadEndedEvent(WeaponItem)
    local tbCharacter = WeaponItem:GetOwnerCharacter()
    if WeaponItem:IsServerInstance() then
        EventManager:OnFireEvent(CommonEventDef.EV_ON_SHIP_WEAPON_BULLET_LOAD_ENDED_SERVER, tbCharacter, WeaponItem)
    else
        LoadClientEventDef()
        EventManager:OnFireEvent(ClientEventDef.EV_ON_SHIP_WEAPON_BULLET_LOAD_ENDED_CLIENT, tbCharacter, WeaponItem)
    end
end

function BattleShipWeaponEventHelper.FireOnShipWeaponEquippedEvent(WeaponItem)
    local nWeaponSlot = WeaponItem:GetWeaponSlot()
    local tbCharacter = WeaponItem:GetOwnerCharacter()
    if WeaponItem:IsServerInstance() then
        EventManager:OnFireEvent(CommonEventDef.EV_ON_SHIP_WEAPON_EQUIPPED_SERVER, tbCharacter, nWeaponSlot, WeaponItem)
    else
        LoadClientEventDef()
        EventManager:OnFireEvent(ClientEventDef.EV_ON_SHIP_WEAPON_EQUIPPED_CLIENT, tbCharacter, nWeaponSlot, WeaponItem)
    end
end

function BattleShipWeaponEventHelper.FireOnShipWeaponUnequippedEvent(WeaponItem)
    local nWeaponSlot = WeaponItem:GetWeaponSlot()
    local tbCharacter = WeaponItem:GetOwnerCharacter()
    if WeaponItem:IsServerInstance() then
        EventManager:OnFireEvent(CommonEventDef.EV_ON_SHIP_WEAPON_UNEQUIPPED_SERVER, tbCharacter, nWeaponSlot, WeaponItem)
    else
        LoadClientEventDef()
        EventManager:OnFireEvent(ClientEventDef.EV_ON_SHIP_WEAPON_UNEQUIPPED_CLIENT, tbCharacter, nWeaponSlot, WeaponItem)
    end
end

function BattleShipWeaponEventHelper.FireOnShipWeaponFiringOperationChangedEvent(WeaponItem, nFiringOperation)
    local tbCharacter = WeaponItem:GetOwnerCharacter()
    if WeaponItem:IsServerInstance() then
        EventManager:OnFireEvent(CommonEventDef.EV_ON_SHIP_WEAPON_FIRING_OPERATION_CHANGED_SERVER, tbCharacter, WeaponItem, nFiringOperation)
    else
        LoadClientEventDef()
        EventManager:OnFireEvent(ClientEventDef.EV_ON_SHIP_WEAPON_FIRING_OPERATION_CHANGED_CLIENT, tbCharacter, WeaponItem, nFiringOperation)
    end
end
return BattleShipWeaponEventHelper
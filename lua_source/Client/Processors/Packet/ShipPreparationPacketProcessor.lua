local luaclass = require("luaclass")
local NetMessageProcessorBase = require("NetMessageProcessorBase")
local ShipPreparationPacketProcessor = luaclass("ShipPreparationPacketProcessor", NetMessageProcessorBase)

local UIUtils = require("UIUtils")
local Proto = require("ClientProtoNames")
local EventManager = require("EventManager")
local ClientEventDef = require("ClientEventDef")
local NetworkManager = dynamic_require("NetworkManager")
local GamePlayerSelfHelper = require("GamePlayerSelfHelper")
local CostCurrencyHelper = require("CostCurrencyHelper")

--local MONEY_SCENE_UNLOCK_SHIP_SLOT = 1
local MONEY_SCENE_UNLOCK_SHIP = 2

local ErrorReturnCodeText = {
    [Proto.ReturnCode.SHIP_SLOT_LOCKED]                 = "RETURN_CODE_SHIP_SLOT_LOCKED",
    [Proto.ReturnCode.SHIP_SLOT_ALL_UNLOCKED]           = "RETURN_CODE_SHIP_SLOT_ALL_UNLOCKED",
    [Proto.ReturnCode.SHIP_SLOT_UNLOCKED]               = "RETURN_CODE_SHIP_SLOT_UNLOCKED",
    [Proto.ReturnCode.SHIP_SLOT_UNLOCK_IN_WRONG_ORDER]  = "RETURN_CODE_SHIP_SLOT_UNLOCK_IN_WRONG_ORDER",
    [Proto.ReturnCode.SHIP_NOT_FOUND]                   = "RETURN_CODE_SHIP_NOT_FOUND",
    [Proto.ReturnCode.SHIP_HAS_UNLOCKED]                = "RETURN_CODE_SHIP_HAS_UNLOCKED",
    [Proto.ReturnCode.SHIP_INVALID_UNLOCK_METHOD]       = "RETURN_CODE_SHIP_INVALID_UNLOCK_METHOD",
    [Proto.ReturnCode.SHIP_CATEGORY_INVALID]            = "RETURN_CODE_SHIP_CATEGORY_INVALID",
    [Proto.ReturnCode.SHIP_HAS_BEEN_EQUIPPED]           = "RETURN_CODE_SHIP_HAS_BEEN_EQUIPPED",
    [Proto.ReturnCode.SHIP_DEFAULT_EQUIPPED]            = "RETURN_CODE_SHIP_DEFAULT_EQUIPPED",
    [Proto.ReturnCode.SHIP_WEAPON_NOT_FOUND]            = "RETURN_CODE_SHIP_WEAPON_NOT_FOUND",
    [Proto.ReturnCode.SHIP_WEAPON_HAS_CHOSEN]           = "RETURN_CODE_SHIP_WEAPON_HAS_CHOSEN",
    [Proto.ReturnCode.SHIP_WEAPON_CATEGORY_INVALID]     = "RETURN_CODE_SHIP_WEAPON_CATEGORY_INVALID",
    [Proto.ReturnCode.SHIP_PART_NOT_FOUND]              = "RETURN_CODE_SHIP_PART_NOT_FOUND",
    [Proto.ReturnCode.SHIP_PART_HAS_CHOSEN]             = "RETURN_CODE_SHIP_PART_HAS_CHOSEN",
    [Proto.ReturnCode.SHIP_PART_CATEGORY_INVALID]       = "RETURN_CODE_SHIP_PART_CATEGORY_INVALID",
    [Proto.ReturnCode.SHIP_SKIN_ALREADY_OWN]            = "RETURN_CODE_SHIP_SKIN_ALREADY_OWN",
    [Proto.ReturnCode.SHIP_SKIN_SHIP_LOCKED]            = "RETURN_CODE_SHIP_SKIN_SHIP_LOCKED",
    [Proto.ReturnCode.SHIP_SKIN_CATEGORY_INVALID]       = "RETURN_CODE_SHIP_SKIN_CATEGORY_INVALID",
    [Proto.ReturnCode.SHIP_SKIN_NOT_FOUND]              = "RETURN_CODE_SHIP_SKIN_NOT_FOUND",
    [Proto.ReturnCode.SHIP_SKIN_INVALID_BUY_METHOD]     = "RETURN_CODE_SHIP_SKIN_INVALID_BUY_METHOD",
    [Proto.ReturnCode.SHIP_SKIN_HAS_BEEN_EQUIPPED]      = "RETURN_CODE_SHIP_SKIN_HAS_BEEN_EQUIPPED",
    [Proto.ReturnCode.SHIP_UNKNOWN_ERROR]               = "RETURN_CODE_SHIP_UNKNOWN_ERROR"
}

local MoneyErrorReturnCodeText = {
    --[MONEY_SCENE_UNLOCK_SHIP_SLOT]                  = "RETURN_CODE_MONEY_IS_NOT_ENOUGH_UNLOCK_SHIP_SLOT",
    [MONEY_SCENE_UNLOCK_SHIP]                       = "RETURN_CODE_MONEY_IS_NOT_ENOUGH_UNLOCK_SHIP",
}

local function CheckReturnCode(nReturnCode, nMoneySceneType)
    if nReturnCode ~= Proto.ReturnCode.OK then
        local szKey
        if nReturnCode == Proto.ReturnCode.MONEY_IS_NOT_ENOUGH then
            szKey = MoneyErrorReturnCodeText[nMoneySceneType]
        else
            szKey = ErrorReturnCodeText[nReturnCode]
        end
        if szKey then
            UIUtils.ShowToastWithKey(szKey)
        else
            logerror("PartnerPacketProcessor Unknown error code : " .. nReturnCode)
            UIUtils.ShowToastWithKey(ErrorReturnCodeText[Proto.ReturnCode.SHIP_UNKNOWN_ERROR])
        end
        return false
    end
    return true
end

local function GetShipPreparationComponent()
    return GamePlayerSelfHelper:Get().ShipPreparationComponent
end

local function OnReceiveUnlockShipSlotResult(tbPacket)
    CostCurrencyHelper:FinishRequest()
    if tbPacket.return_code == Proto.ReturnCode.MONEY_IS_NOT_ENOUGH then
        EventManager:OnFireEvent(ClientEventDef.EV_ON_RECEIVE_UNLOCK_SHIP_SLOT_NOT_ENOUGH_MONEY, tbPacket.currency_auto_exchange)
        return
    end

    if CheckReturnCode(tbPacket.return_code) then
        GetShipPreparationComponent():ReceiveUnlockShipSlot(tbPacket.ship_slot_id)
    end
end

local function OnReceiveEquipShipResult(tbPacket)
    if CheckReturnCode(tbPacket.return_code) then
        GetShipPreparationComponent():ReceiveEquipShipResult(tbPacket.slot_id, tbPacket.equipped_ship)
    end
end

local function OnReceiveUnequipShipResult(tbPacket)
    if CheckReturnCode(tbPacket.return_code) then
        GetShipPreparationComponent():ReceiveUnequipShipResult(tbPacket.slot_id)
    end
end

local function OnReceiveChooseShipWeaponResult(tbPacket)
    if CheckReturnCode(tbPacket.return_code) then
        GetShipPreparationComponent():ReceiveActivateWeaponResult(tbPacket.ship_weapon_instance_id)
    end
end

local function OnReceiveChooseShipPartResult(tbPacket)
    if CheckReturnCode(tbPacket.return_code) then
        GetShipPreparationComponent():ReceiveActivatePartResult(tbPacket.ship_part_instance_id)
    end
end

local function OnReceiveUnequipShipSkinResult(tbPacket)
    if CheckReturnCode(tbPacket.return_code) then
        GetShipPreparationComponent():ReceiveUnequipShipSkinResult(tbPacket.ship_instance_id, tbPacket.equipped_ship_skin_instance_id)
    end
end

local function OnReceiveEquipShipSkinResult(tbPacket)
    if CheckReturnCode(tbPacket.return_code) then
        GetShipPreparationComponent():ReceiveEquipShipSkinResult(tbPacket.ship_instance_id, tbPacket.ship_skin_instance_id)
    end
end

function ShipPreparationPacketProcessor:RegisterPackets()
    self:BindFunc(Proto.s2c_UnlockShipSlot, OnReceiveUnlockShipSlotResult)
    self:BindFunc(Proto.s2c_EquipShip, OnReceiveEquipShipResult)
    self:BindFunc(Proto.s2c_UnequipShip, OnReceiveUnequipShipResult)
    self:BindFunc(Proto.s2c_ChooseShipWeapon, OnReceiveChooseShipWeaponResult)
    self:BindFunc(Proto.s2c_ChooseShipPart, OnReceiveChooseShipPartResult)
    self:BindFunc(Proto.s2c_UnequipShipSkin, OnReceiveUnequipShipSkinResult)
    self:BindFunc(Proto.s2c_EquipShipSkin, OnReceiveEquipShipSkinResult)
end

function ShipPreparationPacketProcessor:Init()
    ShipPreparationPacketProcessor.super.Init(self)
    self:SetBinder(NetworkManager:GetHubServerProxy())
    self:RegisterPackets()
    return true
end

return ShipPreparationPacketProcessor

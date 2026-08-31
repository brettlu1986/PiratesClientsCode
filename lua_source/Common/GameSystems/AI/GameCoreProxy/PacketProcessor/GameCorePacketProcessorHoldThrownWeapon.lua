local luaclass = require("luaclass")
local GameCorePacketProcessorAction = require("GameCorePacketProcessorAction")
local GameCorePacketProcessorHoldThrownWeapon = luaclass("GameCorePacketProcessorHoldThrownWeapon", GameCorePacketProcessorAction)

local BattleItemSystemServer  = require("BattleItemSystemServer")
local BattleItemCategoryDef = require("BattleItemCategoryDef")
local BattleHumanWeaponSystemNew = dynamic_require("BattleHumanWeaponSystemNew")
local BattleShipWeaponSystem = dynamic_require("BattleShipWeaponSystem")
local HumanMovementStateType = require("HumanMovementStateType")
local BattleItemDataTable = require("BattleItemDataTable")
local ShipWeaponSlotDef = require("ShipWeaponSlotDef")

-- luacheck: push ignore
local function LOG(...)
    log("CJ->GameCorePacketProcessorHoldThrownWeapon:", ...)
end
-- luacheck: pop

local ServerProtoNames      = require("GameCoreServerProtoNames")
local tbIgnoredPackets = {
    ServerProtoNames.s2c_fire,
    ServerProtoNames.s2c_switchWeapon,
    ServerProtoNames.s2c_jumpWall,
    ServerProtoNames.s2c_holdThrownWeapon,
    ServerProtoNames.s2c_unholdThrownWeapon,
    ServerProtoNames.s2c_throwAttack,
}

function GameCorePacketProcessorHoldThrownWeapon:CD()
    self:IngorePackets(tbIgnoredPackets, 1)
end

local function HoldShipThrownWeapon(tbPlayer, nItemTemplateId)
    local nCharacterInstanceId = tbPlayer:GetServerInstanceId()

    local tbTemplate = BattleItemDataTable:GetTemplate(nItemTemplateId)
    if not tbTemplate then
        logerror("GameCoreBotAgent-> Hold thrown weapon failed! template id is not exist!", nCharacterInstanceId, nItemTemplateId)
        return
    end

    if BattleItemSystemServer:GetUnequippedItemCount(nCharacterInstanceId, nItemTemplateId) <= 0 then
        logerror("GameCoreBotAgent-> Hold thrown weapon failed! item count 0!", nCharacterInstanceId, nItemTemplateId)
        return
    end
    if tbTemplate.nCategory ~= BattleItemCategoryDef.SHIP_THROWN_ITEM then
        logerror("GameCoreBotAgent-> Hold thrown weapon failed! Item is not ship thrown item!", nCharacterInstanceId, nItemTemplateId, tbTemplate.nCategory)
        return
    end
    local ActiveWeapon = BattleShipWeaponSystem:GetActiveWeaponItem(tbPlayer)
    if ActiveWeapon and (ActiveWeapon:GetTemplateId() == nItemTemplateId) then
        log("GameCoreBotAgent-> Hold thrown weapon failed! Already active same ship thrown weapon!", nCharacterInstanceId, nItemTemplateId)
        return
    end

    BattleShipWeaponSystem:EquipThrownItem(tbPlayer, nItemTemplateId)
    BattleShipWeaponSystem:ActivateWeaponItem(tbPlayer, BattleShipWeaponSystem:GetEquippedWeaponItem(tbPlayer, ShipWeaponSlotDef.THROW))
    LOG("Hold thrown weapon", nCharacterInstanceId, nItemTemplateId)
end

local function HoldHumanThrownWeapon(tbPlayer, nItemInstanceId)
    local nCharacterInstanceId = tbPlayer:GetServerInstanceId()
    local tbItem = BattleItemSystemServer:GetItem(nItemInstanceId)
    if not tbItem then
        logerror("GameCoreBotAgent-> Hold thrown weapon failed! Item's is not exist!", nCharacterInstanceId, nItemInstanceId)
        return false
    end
    if tbItem:GetOwnerCharacterInstanceId() ~= nCharacterInstanceId then
        logerror("GameCoreBotAgent-> Hold thrown weapon failed! Item's owner is not this bot!", nCharacterInstanceId)
        return false
    end
    if tbItem:GetCategory() ~= BattleItemCategoryDef.HUMAN_THROWN_ITEM then
        logerror("GameCoreBotAgent-> Hold thrown weapon failed! Item is not human thrown item!", nCharacterInstanceId, tbItem:GetTemplateId(), tbItem:GetCategory())
        return false
    end

    local HumanMovementStateComponent = tbPlayer.HumanMovementStateComponent
    local nMovementState = HumanMovementStateComponent:GetCurrentState()
    if nMovementState == HumanMovementStateType.Jumping_SpeelWall then
        log("GameCoreBotAgent-> Hold thrown weapon failed!In JumpSpeel Can't SetWeapon nInstanceId", nCharacterInstanceId, nItemInstanceId)
        return false
    end

    if nMovementState == HumanMovementStateType.Dying_State then
        log("GameCoreBotAgent-> Hold thrown weapon failed!In Dying_State Can't SetWeapon nInstanceId", nCharacterInstanceId, nItemInstanceId)
        return false
    end

    if HumanMovementStateComponent:IsInVehicle() then
        log("GameCoreBotAgent-> Hold thrown weapon failed!In Vehicle Can't SetWeapon nInstanceId", nCharacterInstanceId, nItemInstanceId)
        return false
    end

    if nMovementState == HumanMovementStateType.Swimming then
        log("GameCoreBotAgent-> Hold thrown weapon failed!In Swimming Can't SetWeapon nInstanceId", nCharacterInstanceId, nItemInstanceId)
        return false
    end

    BattleHumanWeaponSystemNew:OnHoldThrownWeapon(tbPlayer, nItemInstanceId)
    LOG("Hold thrown weapon", nCharacterInstanceId, nItemInstanceId)
    return true
end

function GameCorePacketProcessorHoldThrownWeapon:DoAction(tbPacket)
    local tbPlayer = self.tbAgent:GetGameObject()

    if tbPlayer:IsHuman() then
        if HoldHumanThrownWeapon(tbPlayer, tbPacket.item_id) then
            self:CD()
        end
    else
        HoldShipThrownWeapon(tbPlayer, tbPacket.item_id)
    end
end


return GameCorePacketProcessorHoldThrownWeapon
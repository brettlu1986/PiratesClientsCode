local luaclass = require("luaclass")
local GameCorePacketProcessorAction = require("GameCorePacketProcessorAction")
local GameCorePacketProcessorUnholdThrownWeapon = luaclass("GameCorePacketProcessorUnholdThrownWeapon", GameCorePacketProcessorAction)

local HumanWeaponMisc = require("HumanWeaponMisc")
local HumanWeaponType = HumanWeaponMisc.Type
local BattleItemCategoryDef = require("BattleItemCategoryDef")
local BattleHumanWeaponSystemNew = dynamic_require("BattleHumanWeaponSystemNew")
local BattleShipWeaponSystem = dynamic_require("BattleShipWeaponSystem")

-- luacheck: push ignore
local function LOG(...)
    log("CJ->GameCorePacketProcessorUnholdThrownWeapon:", ...)
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

function GameCorePacketProcessorUnholdThrownWeapon:CD()
    self:IngorePackets(tbIgnoredPackets, 0.8)
end

local function UnholdHumanThrownWeapon(tbPlayer)
    local nCharacterInstanceId = tbPlayer:GetServerInstanceId()
    local WeaponComponent = tbPlayer.HumanWeaponComponent
    local tbCurrentWeapon = WeaponComponent:GetCurrentWeapon()
    if not tbCurrentWeapon then
        LOG("Unhold thrown weapon failed! No current weapon!")
        return false
    end
    if not tbCurrentWeapon:IsType(HumanWeaponType.THROW) then
        LOG("Unhold thrown weapon failed! Current weapon is not human thrown item!", nCharacterInstanceId, tbCurrentWeapon:GetTemplateId(), tbCurrentWeapon:GetType())
        return false
    end
    BattleHumanWeaponSystemNew:OnUnholdThrownWeapon(tbPlayer)
    LOG("Unhold human thrown weapon", nCharacterInstanceId)
    return true
end

local function UnholdShipThrownWeapon(tbPlayer)
    local nCharacterInstanceId = tbPlayer:GetServerInstanceId()
    local ActiveWeapon = BattleShipWeaponSystem:GetActiveWeaponItem(tbPlayer)
    if (not ActiveWeapon) or ActiveWeapon:GetCategory() ~= BattleItemCategoryDef.SHIP_THROWN_ITEM then
        LOG("Unhold thrown weapon failed! No current ship thrown weapon!", nCharacterInstanceId)
        return
    end
    BattleShipWeaponSystem:ActivateWeaponItem(tbPlayer)
    LOG("Unhold ship thrown weapon", nCharacterInstanceId)
end

function GameCorePacketProcessorUnholdThrownWeapon:DoAction(tbPacket)
    local tbPlayer = self.tbAgent:GetGameObject()
    if tbPlayer:IsHuman() then
        if UnholdHumanThrownWeapon(tbPlayer) then
            self:CD()
        end
    else
        UnholdShipThrownWeapon(tbPlayer)
    end
end


return GameCorePacketProcessorUnholdThrownWeapon
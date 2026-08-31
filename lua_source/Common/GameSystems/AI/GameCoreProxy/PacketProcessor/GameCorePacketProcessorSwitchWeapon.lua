local luaclass = require("luaclass")
local GameCorePacketProcessorAction = require("GameCorePacketProcessorAction")
local GameCorePacketProcessorSwitchWeapon = luaclass("GameCorePacketProcessorSwitchWeapon", GameCorePacketProcessorAction)

local Proto                         = require("GameCoreClientProtoNames")
local BattleItemSystemServer    = require("BattleItemSystemServer")
local BattleItemCategoryDef = require("BattleItemCategoryDef")
local ShipWeaponSlotDef = require("ShipWeaponSlotDef")
local HumanWeaponSlotDef = require("HumanWeaponSlotDef")
local BattleShipWeaponSystem = dynamic_require("BattleShipWeaponSystem")

-- luacheck: push ignore
local function LOG(...)
    log("CJ->GameCorePacketProcessorSwitchWeapon:", ...)
end
-- luacheck: pop

local ServerProtoNames      = require("GameCoreServerProtoNames")
local tbIgnoredPackets = {
    ServerProtoNames.s2c_fire,
    ServerProtoNames.s2c_switchWeapon,
    ServerProtoNames.s2c_jumpWall,
    ServerProtoNames.s2c_holdThrownWeapon,
    ServerProtoNames.s2c_unholdThrownWeapon,
}
local nSwitchWeaponCDTime = 1

function GameCorePacketProcessorSwitchWeapon:CD()
    local tbAgent = self.tbAgent
    for i,v in ipairs(tbIgnoredPackets) do
        tbAgent:AddIngorePacket(v, nSwitchWeaponCDTime)
    end
end


function GameCorePacketProcessorSwitchWeapon:DoAction(tbPacket)
    local nSlot = tbPacket.waepoan_slot
    local tbGameObject = self.tbAgent:GetGameObject()
    local nServerInstanceId = tbGameObject:GetServerInstanceId()
    if tbGameObject:IsHuman() then
        local WeaponComponent = tbGameObject.HumanWeaponComponent
        if nSlot == 0 then -- 设置空手
            WeaponComponent:SetCurrentWeapon(0, true)
            self:ReportActionResult(Proto.ActionType.SwitchWeapon, 0)
            self:CD()
            return
        elseif nSlot > 0 and nSlot <= HumanWeaponSlotDef:SlotCount() then
            self:StopAttack()
            local tbWeapon = BattleItemSystemServer:GetEquippedItem(nServerInstanceId, BattleItemCategoryDef.HUMAN_WEAPON,
            nServerInstanceId, nSlot)
            if tbWeapon then
                WeaponComponent:SetCurrentWeapon(tbWeapon:GetInstanceId())
                self:ReportActionResult(Proto.ActionType.SwitchWeapon, 0)
                self:CD()
                return
            end
        end
        self:ReportActionResult(Proto.ActionType.SwitchWeapon, 1)
    else
        if nSlot == ShipWeaponSlotDef.UNKNOWN then -- 选择默认船武器
            BattleShipWeaponSystem:ActivateWeaponItem(tbGameObject)
            self:ReportActionResult(Proto.ActionType.SwitchWeapon, 0)
            return
        elseif ShipWeaponSlotDef.IsValid(nSlot) then
            self:StopAttack()
            local tbWeapon = BattleItemSystemServer:GetEquippedItem(nServerInstanceId, BattleItemCategoryDef.SHIP_WEAPON,
            nServerInstanceId, nSlot)
            if tbWeapon then
                BattleShipWeaponSystem:ActivateWeaponItem(tbGameObject, tbWeapon)
                self:ReportActionResult(Proto.ActionType.SwitchWeapon, 0)
                return
            end
        end
        self:ReportActionResult(Proto.ActionType.SwitchWeapon, 1)
    end
end


return GameCorePacketProcessorSwitchWeapon
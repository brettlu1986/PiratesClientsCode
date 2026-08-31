local luaclass = require("luaclass")
local SAIActionBase = require("SAIActionBase")
local SAIActionShip = luaclass("SAIActionShip", SAIActionBase)
local BattleItemSystemServer = require("BattleItemSystemServer")
local BattleItemCategoryDef  = require("BattleItemCategoryDef")
local BattleShipWeaponSystem = dynamic_require("BattleShipWeaponSystem")

local function LOG(...)
    log("CJ->SAIActionShip:", ...)
end



function SAIActionShip:OnSwitchWeapon(nSlot)
    LOG("switch weapon ", nSlot)
    assert(self.Owner and self.Owner.pUEActor)
    local tbBot = self.Owner
    local tbWeapon = BattleItemSystemServer:GetEquippedItem(tbBot:GetServerInstanceId(), BattleItemCategoryDef.SHIP_WEAPON,
    tbBot:GetServerInstanceId(), nSlot)
    if tbWeapon then
        BattleShipWeaponSystem:ActivateWeaponItem(tbBot, tbWeapon)
    end
end

return SAIActionShip
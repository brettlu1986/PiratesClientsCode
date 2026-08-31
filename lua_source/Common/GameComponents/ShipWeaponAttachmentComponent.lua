local luaclass = require("luaclass")
local GameComponentBase = require("GameComponentBase")
local ShipWeaponAttachmentComponent = luaclass("ShipWeaponAttachmentComponent", GameComponentBase)

local ShipWeaponAttachmentTypeDef = require("ShipWeaponAttachmentTypeDef")
local BattleItemCategoryDef = require("BattleItemCategoryDef")
local BattleItemSystemHelper = require("BattleItemSystemHelper")


local function LOG(self, ...)
    log("[ShipWeaponAttachment]", self.Owner.szName, ...)
end

function ShipWeaponAttachmentComponent:OnShipWeaponActiveServer(tbWeaponItem)
    if tbWeaponItem.tbOwnerCharacter == self.Owner then
        LOG(self, "Active attachment on weapon actived.")
        for i=1,ShipWeaponAttachmentTypeDef.Max do
            local tbEquippedAttachment = BattleItemSystemHelper:GetEquippedItem(tbWeaponItem:GetOwnerCharacterInstanceId(),
            BattleItemCategoryDef.SHIP_WEAPON_ATTACHMENT, tbWeaponItem:GetInstanceId(), i, false)
            if tbEquippedAttachment then
                tbEquippedAttachment:Active()
            end
        end
    end
end

function ShipWeaponAttachmentComponent:OnShipWeaponDeActiveServer(tbWeaponItem)
    if tbWeaponItem.tbOwnerCharacter == self.Owner then
        LOG(self, "Deactive attachment on weapon deactived.")
        for i=1,ShipWeaponAttachmentTypeDef.Max do
            local tbEquippedAttachment = BattleItemSystemHelper:GetEquippedItem(tbWeaponItem:GetOwnerCharacterInstanceId(),
            BattleItemCategoryDef.SHIP_WEAPON_ATTACHMENT, tbWeaponItem:GetInstanceId(), i, false)
            if tbEquippedAttachment then
                tbEquippedAttachment:Deactive()
            end
        end
    end
end



return ShipWeaponAttachmentComponent
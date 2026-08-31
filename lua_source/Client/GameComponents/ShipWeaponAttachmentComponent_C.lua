local luaclass = require("luaclass")
local ShipWeaponAttachmentComponent = require("ShipWeaponAttachmentComponent")
local ShipWeaponAttachmentComponent_C = luaclass("ShipWeaponAttachmentComponent_C", ShipWeaponAttachmentComponent)


local ShipWeaponAttachmentTypeDef = require("ShipWeaponAttachmentTypeDef")
local BattleItemCategoryDef = require("BattleItemCategoryDef")
local BattleItemSystemHelper = require("BattleItemSystemHelper")


function ShipWeaponAttachmentComponent_C:OnShipWeaponActiveClient(tbWeaponItem)
    for i=1,ShipWeaponAttachmentTypeDef.Max do
        local tbEquippedAttachment = BattleItemSystemHelper:GetEquippedItem(tbWeaponItem:GetOwnerCharacterInstanceId(), 
        BattleItemCategoryDef.SHIP_WEAPON_ATTACHMENT, tbWeaponItem:GetInstanceId(), i, true)
        if tbEquippedAttachment then
            tbEquippedAttachment:Active()
        end
    end
end

function ShipWeaponAttachmentComponent_C:OnShipWeaponDeActiveClient(tbWeaponItem)
    for i=1,ShipWeaponAttachmentTypeDef.Max do
        local tbEquippedAttachment = BattleItemSystemHelper:GetEquippedItem(tbWeaponItem:GetOwnerCharacterInstanceId(),
        BattleItemCategoryDef.SHIP_WEAPON_ATTACHMENT, tbWeaponItem:GetInstanceId(), i, true)
        if tbEquippedAttachment then
            tbEquippedAttachment:Deactive()
        end
    end
end

return ShipWeaponAttachmentComponent_C
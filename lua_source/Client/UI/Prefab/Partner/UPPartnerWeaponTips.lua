-----------------------------------------------------
--File Name    : UPPartnerWeaponTips.lua
--Author       : Song Fuhao
--Create Time  : 2019-04-11
--Description  : 伙伴武器Tips
-----------------------------------------------------
local luaclass = require("luaclass")
local ListItemBase = require("ListItemBase")
local UPPartnerWeaponTips = luaclass("UPPartnerWeaponTips", ListItemBase)

local BattleItemDataTable = require("BattleItemDataTable")

function UPPartnerWeaponTips:SetWeaponId(nWeaponId)
    local tbTemplate = BattleItemDataTable:GetTemplate(nWeaponId)
    self.pWidgetRef.txtName:SetText(tbTemplate.l10nName)
    self.pWidgetRef.txtDamagePerBullet:SetText(tbTemplate.nDamagePerBullet)
    self.pWidgetRef.txtEffectiveRange:SetText(tbTemplate.nEffectiveRange)
end

return UPPartnerWeaponTips
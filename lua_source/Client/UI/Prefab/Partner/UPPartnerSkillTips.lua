-----------------------------------------------------
--File Name    : UPPartnerSkillTips.lua
--Author       : Song Fuhao
--Create Time  : 2019-03-11
--Description  : 伙伴技能Tips
-----------------------------------------------------
local luaclass = require("luaclass")
local ListItemBase = require("ListItemBase")
local UPPartnerSkillTips = luaclass("UPPartnerSkillTips", ListItemBase)

local SkillDataTable = require("SkillDataTable")

function UPPartnerSkillTips:SetSkillId(nSkillId)
    local tbSkillTemplate = SkillDataTable:GetResTemplate(nSkillId)
    self.pWidgetRef.txtTitle:SetText(tbSkillTemplate.l10nName)
    self.pWidgetRef.ktxtDesc:SetText(tbSkillTemplate.l10nDesc)
end

return UPPartnerSkillTips
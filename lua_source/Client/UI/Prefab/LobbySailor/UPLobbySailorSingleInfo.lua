
local luaclass = require("luaclass")
local PrefabBase = require("PrefabBase")
local UPLobbySailorSingleInfo = luaclass("UPLobbySailorSingleInfo", PrefabBase)
local ItemSystem = require("ItemSystem")
local UISetUtils = require("UISetUtils")
local UIResourceDef = require("UIResourceDef")
local L10N = require("L10N")

function UPLobbySailorSingleInfo:OnLoad()
end

function UPLobbySailorSingleInfo:OnBindEvent(EventHelper)
end

function UPLobbySailorSingleInfo:SetData(nSailorId)
    local pWidgetRef = self.pWidgetRef
    local tbTemplate = ItemSystem:GetItemTemplate(nSailorId)
    pWidgetRef.txtName:SetText(tbTemplate.l10nName)
    local nCountLeft = ItemSystem:GetItemCount(nSailorId)
    pWidgetRef.txtLeft:SetText(L10N:Format(UISetUtils.GetL10NTextByKey("SAILOR_OWNED_FORMAT"), nCountLeft))
    
    local szGradeIcon = UIResourceDef.ITEM_INFO_GRADE_BG_H[tbTemplate.nGrade]
    UISetUtils.SetBorderBrushRes(pWidgetRef.bdrInfoBg, szGradeIcon:load(), true)
end

return UPLobbySailorSingleInfo
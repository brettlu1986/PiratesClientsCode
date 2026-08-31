-----------------------------------------------------
--File Name    : UPSailorBagItem.lua
--Author       : Song Fuhao
--Create Time  : 2019-03-20
--Description  : 水手背包列表中的小Item
-----------------------------------------------------
local luaclass = require("luaclass")
local ListItemBase = require("ListItemBase")
local UPSailorBagItem = luaclass("UPSailorBagItem", ListItemBase)

local L10N = require("L10N")
local UISetUtils = require("UISetUtils")
local UIResourceDef = require("UIResourceDef")
local ItemSystem = require("ItemSystem")
local GamePlayerSelfHelper = require("GamePlayerSelfHelper")

local VALID_OPACITY = 1
local INVALID_OPACITY = 0.4

local function GetSailorComponent()
    return GamePlayerSelfHelper:Get().SailorComponent
end

function UPSailorBagItem:OnRefresh(tbData)
    local tbTemplate = tbData.tbTemplate
    local pWidgetRef = self.pWidgetRef
    local tbResTemplate = ItemSystem:GetItemResTemplate(tbData.nSailorId)
    pWidgetRef.txtName:SetText(tbTemplate.l10nName)
    log("tbTemplate.l10nName", L10N:ToString(tbTemplate.l10nName))
    UISetUtils.SetImageBrushRes(pWidgetRef.imgIcon, tbResTemplate.szIconPath:load())
    UISetUtils.SetImageBrushRes(pWidgetRef.imgGrade, UIResourceDef.SAILOR_GRADE_ICONS[tbTemplate.nGrade + 1]:load())
    if tbData.nCount > 0 then
        pWidgetRef:SetRenderOpacity(VALID_OPACITY)
        pWidgetRef.txtCount:SetText("x"..tbData.nCount)
    else
        pWidgetRef:SetRenderOpacity(INVALID_OPACITY)
        pWidgetRef.txtCount:SetText(UISetUtils.GetL10NTextByKey("SAILOR_NOT_OBTAINED"))
    end

    local szIntroduce = GetSailorComponent():GetSailorIntroduce(tbData.nSailorId)
    self.pWidgetRef.txtProperties:SetText(szIntroduce)
end

function UPSailorBagItem:OnBindEvent(EventHelper)
    EventHelper:RegisterCppDelegate(self.pWidgetRef.btnListItem.OnClicked, self, self.SelectItem)
end

return UPSailorBagItem
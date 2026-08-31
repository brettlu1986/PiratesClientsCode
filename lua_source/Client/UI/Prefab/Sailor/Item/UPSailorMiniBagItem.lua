-----------------------------------------------------
--File Name    : UPSailorMiniBagItem.lua
--Author       : Song Fuhao
--Create Time  : 2019-03-20
--Description  : 水手装备页面中右侧的水手列表Item
-----------------------------------------------------
local luaclass = require("luaclass")
local ListItemBase = require("ListItemBase")
local UPSailorMiniBagItem = luaclass("UPSailorMiniBagItem", ListItemBase)

local UISetUtils = require("UISetUtils")
local ItemSystem = require("ItemSystem")
local UIResourceDef = require("UIResourceDef")
local GamePlayerSelfHelper = require("GamePlayerSelfHelper")

local function GetSailorComponent()
    return GamePlayerSelfHelper:Get().SailorComponent
end

local function OnClickedListItem(self)
    if not self:IsSelected() then
        self:SelectItem()
    end
end

function UPSailorMiniBagItem:OnRefresh(tbData)
    local tbTemplate = tbData.tbTemplate
    local tbResTemplate = ItemSystem:GetItemResTemplate(tbData.nSailorId)
    local pWidgetRef = self.pWidgetRef
    pWidgetRef.txtName:SetText(tbTemplate.l10nName)
    UISetUtils.SetImageBrushRes(pWidgetRef.imgIcon, tbResTemplate.szIconPath:load())
    UISetUtils.SetImageBrushRes(self.pWidgetRef.imgGrade, UIResourceDef.SAILOR_GRADE_ICONS[tbTemplate.nGrade + 1]:load())
    pWidgetRef.txtCount:SetText("x"..tbData.nCount)
    if self:IsSelected() then
        pWidgetRef:PlayAnimation(pWidgetRef.animSelected, 0, 0, EUMGSequencePlayMode.PingPong, 1)
    else
        pWidgetRef.imgBg:SetRenderOpacity(1)
        pWidgetRef:StopAnimation(pWidgetRef.animSelected)
    end

    local szIntroduce = GetSailorComponent():GetSailorIntroduce(tbData.nSailorId)
    self.pWidgetRef.txtProperties:SetText(szIntroduce)
end

function UPSailorMiniBagItem:OnBindEvent(EventHelper)
    EventHelper:RegisterCppDelegate(self.pWidgetRef.btnListItem.OnClicked, self, OnClickedListItem)
end

return UPSailorMiniBagItem
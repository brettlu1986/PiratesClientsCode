-----------------------------------------------------
--File Name    : UPPartnerSkinItem.lua
--Author       : Song Fuhao
--Create Time  : 2019-03-11
--Description  : 伙伴皮肤Item
-----------------------------------------------------
local luaclass = require("luaclass")
local GalleryItemBase = require("GalleryItemBase")
local UPPartnerSkinItem = luaclass("UPPartnerSkinItem", GalleryItemBase)

local UISetUtils = require("UISetUtils")

local function OnClickedBtnItem(self)
    self:SelectItem()
end

local function OnClickedBtnOk(self)
    -- body
end

function UPPartnerSkinItem:OnRefresh(tbData)
    -- self.pWidgetRef.btnOk:SetIsEnabled(false)
    self.pWidgetRef.txtTips:SetText(UISetUtils.GetL10NTextByKey("PARTNER_SKIN_USED"))
    UISetUtils.SetImageBrushRes(self.pWidgetRef.imgBg, tbData.szSkinPosterRes:load())
end

function UPPartnerSkinItem:OnBindEvent(EventHelper)
    EventHelper:RegisterCppDelegate(self.pWidgetRef.btnItem.OnClicked, self, OnClickedBtnItem)
    EventHelper:RegisterCppDelegate(self.pWidgetRef.btnOk.OnClicked, self, OnClickedBtnOk)
end

return UPPartnerSkinItem
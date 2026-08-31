-----------------------------------------------------
--File Name    : UPLobbyShipDetailPropItem.lua
--Author       : Song Fuhao
--Create Time  : 2019-06-13
--Description  : 舰船详情参数Item
-----------------------------------------------------
local luaclass = require("luaclass")
local ListItemBase = require("ListItemBase")
local UPLobbyShipDetailPropItem = luaclass("UPLobbyShipDetailPropItem", ListItemBase)

local WIDGET_INDEX_CATEGORY = 0
local WIDGET_INDEX_PROPERTY = 1
local ARROW_RIGHT_ANGLE = 0
local ARROW_DOWN_ANGLE = 90
local CATEGORY_PADDING = Margin{Left=0 , Top=10, Right=0, Bottom=0}
local PROPERTY_PADDING = Margin{Left=0 , Top=0 , Right=0, Bottom=0}

-- tbData = {
--     -- bCategory为true时需要这些值
--     nCategoryIndex = 1,
--     nScore = 56,
--     bExpanded = false,
--
--     -- bCategory为false时需要这些值
--     l10nPropName = "血量",
--     l10nPropValue = "12000"
-- }

local function OnClickedBtnCategory(self)
    self.ListHelper.tbExtraDatas.fnToogleCategoryExpanded(self.tbData.nCategoryIndex)
end

function UPLobbyShipDetailPropItem:OnRefresh(tbData)
    if tbData.tbProperties ~= nil then
        self.pWidgetRef.wsContent:SetActiveWidgetIndex(WIDGET_INDEX_CATEGORY)
        self.pWidgetRef.txtCategoryName:SetText(tbData.l10nCategoryName)
        self.pWidgetRef.txtScore:SetText(tbData.nScore)
        self.pWidgetRef.pgbScore:SetPercent(tbData.nScore / 100)
        if tbData.bExpanded then
            self.pWidgetRef.imgArrow:SetRenderTransformAngle(ARROW_DOWN_ANGLE)
            self.pWidgetRef.imgLine:SetVisibility(ESlateVisibility.HitTestInvisible)
        else
            self.pWidgetRef.imgArrow:SetRenderTransformAngle(ARROW_RIGHT_ANGLE)
            self.pWidgetRef.imgLine:SetVisibility(ESlateVisibility.Collapsed)
        end
        self.pWidgetRef:SetPadding(CATEGORY_PADDING)
    else
        self.pWidgetRef.wsContent:SetActiveWidgetIndex(WIDGET_INDEX_PROPERTY)
        self.pWidgetRef.txtPropName:SetText(tbData.l10nPropName)
        self.pWidgetRef.txtPropValue:SetText(tbData.l10nPropValue)
        self.pWidgetRef:SetPadding(PROPERTY_PADDING)
    end
end

function UPLobbyShipDetailPropItem:OnBindEvent(EventHelper)
    EventHelper:RegisterCppDelegate(self.pWidgetRef.btnCategory.OnClicked, self, OnClickedBtnCategory)
end

return UPLobbyShipDetailPropItem
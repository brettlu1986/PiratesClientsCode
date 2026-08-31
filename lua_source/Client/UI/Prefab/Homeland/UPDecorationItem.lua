-----------------------------------------------------
--File Name    : UPDecorationItem.lua
--Author       : zheng
--Create Time  : 4/25/2019
--Description  : 装饰物选项
-----------------------------------------------------
local luaclass = require("luaclass")
local ListItemBase = require("ListItemBase")

local UPDecorationItem = luaclass("UPDecorationItem", ListItemBase)
local BuildingDataTable = require("BuildingDataTable")
local UISetUtils = require("UISetUtils")

function UPDecorationItem:OnRefresh(tbData)
    local pWidgetRef = self.pWidgetRef
    local tbTemplate
    if tbData.nAvailableCount > 0 then
        local Item = tbData.Item
        tbTemplate = Item:GetTemplate()
    else
        tbTemplate = tbData.ItemTemplate
    end
    -- local nBuildId = tbData.nBuildingId
    local nBuildId = tbTemplate.nBuildingId
    local tbBuildTemplate = BuildingDataTable:GetTemplate(nBuildId)
    local szIconRes = tbBuildTemplate.szIcon
    local pRes = szIconRes:load()
    UISetUtils.SetImageBrushRes(pWidgetRef.imgIcon, pRes)

    if tbData.nAvailableCount > 0 then
        pWidgetRef.imgIcon:SetRenderOpacity(1)
    else
        pWidgetRef.imgIcon:SetRenderOpacity(0.4)
    end
    local nSelectIndex = self.ListHelper:GetSelectedIndex()

    if self.nIndex == nSelectIndex then
        pWidgetRef.imgSelect:SetVisibility(ESlateVisibility.SelfHitTestInvisible)
    else
        pWidgetRef.imgSelect:SetVisibility(ESlateVisibility.Collapsed)
    end
    pWidgetRef.imgColour:SetVisibility(ESlateVisibility.Collapsed)
end

local function OnClickedBtnSelect(self)
    self:SelectItem()
end

function UPDecorationItem:OnBindEvent(EventHelper)
    local pWidgetRef = self.pWidgetRef
    EventHelper:RegisterCppDelegate(pWidgetRef.btnPressed.OnClicked, self, OnClickedBtnSelect)

end

return UPDecorationItem
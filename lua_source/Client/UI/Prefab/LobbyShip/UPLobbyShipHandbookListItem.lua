-----------------------------------------------------
--File Name    : UPLobbyShipHandbookListItem.lua
--Author       : chenyixin
--Description  : 舰船图鉴Item
-----------------------------------------------------
local luaclass = require("luaclass")
local ListItemBase = require("ListItemBase")
local UPLobbyShipHandbookListItem = luaclass("UPLobbyShipHandbookListItem", ListItemBase)

local ItemResDataTable = require("ItemResDataTable")
local ItemDataTable = require("ItemDataTable")
local UISetUtils = require("UISetUtils")

local LobbyShipDef = require("LobbyShipDef")
local ShipOwningStateDef = LobbyShipDef.OwningStateDef

--[[
    tbData = {
        nShipItemId,
        nGrade,
        nLevel,
        nSubCategory,
        nShipOwningState,
        tbTemplate,
    }
]]

----------------- widget事件们 ---------------------------------------------------

local function OnSelect(self)
    if self:IsSelected() then
        return 
    end
    self:SelectItem()
end

----------------- override ----------------------------------------------------

function UPLobbyShipHandbookListItem:OnBindEvent(EventHelper)
    EventHelper:RegisterCppDelegate(self.pWidgetRef.btnSelect.OnClicked, self, OnSelect)
end

function UPLobbyShipHandbookListItem:OnRefresh(tbData)
    local nShipId = tbData.nShipItemId
    local OwnerSub = self.ListHelper.tbExtraDatas.OwnerSub
    local ShipPreparationComponent = OwnerSub:GetShipPreparationComponent()
    local pWidgetRef = self.pWidgetRef

    -- 设置拥有状态
    if tbData.nShipOwningState < ShipOwningStateDef.Locked then
        pWidgetRef.imgShip:SetIsEnabled(true)
    else
        pWidgetRef.imgShip:SetIsEnabled(false)
    end

    tbData.bHaveNewSkin = ShipPreparationComponent:CheckShipHasNewSkins(nShipId)
    if tbData.bHaveNewSkin then
        pWidgetRef.imgIconTips:SetVisibility(ESlateVisibility.Visible)
        pWidgetRef.imgIconNew:SetVisibility(ESlateVisibility.Collapsed)
    elseif ShipPreparationComponent:IsNewShipItem(nShipId) then
        pWidgetRef.imgIconTips:SetVisibility(ESlateVisibility.Collapsed)
        pWidgetRef.imgIconNew:SetVisibility(ESlateVisibility.Visible)
    else
        pWidgetRef.imgIconTips:SetVisibility(ESlateVisibility.Collapsed)
        pWidgetRef.imgIconNew:SetVisibility(ESlateVisibility.Collapsed)
    end

    -- 设置选中背景
    if self:IsSelected() then
        pWidgetRef.imgSelect:SetVisibility(ESlateVisibility.Visible)
    else
        pWidgetRef.imgSelect:SetVisibility(ESlateVisibility.Hidden)
    end

    -- 设置舰船图片
    local nShipSkinId = ShipPreparationComponent:GetEquippedShipSkinId(nShipId)
    nShipId = nShipSkinId and nShipSkinId or nShipId
    local tbTemplate = ItemDataTable:GetTemplate(nShipId)
    if not tbTemplate then
        logerror("[LobbyShip] UPLobbyShipHandbookListItem cannot find ship tbTemplate, id is", nShipId)
    end
    local tbResTemplate = ItemResDataTable:GetTemplate(tbTemplate.nResId)
    local szImgPath = tbResTemplate.szIconPath
    UISetUtils.SetImageBrushRes(pWidgetRef.imgShip, szImgPath:load())

end

----------------- 接口 ----------------------------------------------------------


return UPLobbyShipHandbookListItem
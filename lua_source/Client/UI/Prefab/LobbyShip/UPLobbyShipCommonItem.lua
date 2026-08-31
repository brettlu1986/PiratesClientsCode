-----------------------------------------------------
--File Name    : UPLobbyShipCommonItem.lua
--Author       : chenyixin
--Description  : 舰船界面通用Item
-----------------------------------------------------
local luaclass = require("luaclass")
local PrefabBase = require("PrefabBase")
local UPLobbyShipCommonItem = luaclass("UPLobbyShipCommonItem", PrefabBase)

local UISetUtils = require("UISetUtils")

UPLobbyShipCommonItem.OwnerSub = nil
UPLobbyShipCommonItem.bSelected = false
UPLobbyShipCommonItem.fnOnSelected = nil
UPLobbyShipCommonItem.tbData = nil
UPLobbyShipCommonItem.tbDisplayData = nil

--[[
    tbDisplayData = {
        szBtnImg,   -- icon图片资源，为空则使用初始icon
        nCount,     -- item叠加数量，为空则隐藏txtCount
        bEnableBtn, -- item是否可点击，为true则点击时调用fnOnSelected，为空或为false则禁用button
        bNew,       -- item是否显示右上角红点
        bShowBox,   -- item是否显示选中白框
    }
]]

local function OnBtnItemClicked(self)
    if self.fnOnSelected then
        self.fnOnSelected()
    end
end

function UPLobbyShipCommonItem:OnLoad()
    self.OwnerSub = self.Owner.OwnerSub
    self.pWidgetRef.imgSelected:SetVisibility(ESlateVisibility.Collapsed)
    self.pWidgetRef.imgSelectedBg:SetVisibility(ESlateVisibility.Collapsed)
end

function UPLobbyShipCommonItem:OnShow()
end

function UPLobbyShipCommonItem:OnBindEvent(EventHelper)
    local pWidgetRef = self.pWidgetRef
    EventHelper:RegisterCppDelegate(pWidgetRef.btnItem.OnClicked, self, OnBtnItemClicked)
end

function UPLobbyShipCommonItem:SetData(tbSubCategoryTemplate)
    -- local pWidgetRef = self.pWidgetRef
end

function UPLobbyShipCommonItem:SetVisibility(pVisibility)
    self.pWidgetRef:SetVisibility(pVisibility)
end

function UPLobbyShipCommonItem:SetSelected(bSelected)
    if self.bSelected == bSelected then
        return
    end

    self.bSelected = bSelected
    self.pWidgetRef.imgSelectedBg:SetVisibility(bSelected and ESlateVisibility.Visible or ESlateVisibility.Collapsed)
    self.pWidgetRef.imgSelectedBox:SetVisibility(ESlateVisibility.Collapsed)
    if self.tbDisplayData and self.tbDisplayData.bShowBox and bSelected then
        self.pWidgetRef.imgSelectedBox:SetVisibility(ESlateVisibility.Visible)
    end
    -- self.pWidgetRef.imgSelected:SetVisibility(bSelected and ESlateVisibility.Visible or ESlateVisibility.Collapsed)
    -- local szImg = bSelected and SELECTED_BG or UNSELECTED_BG
    -- local Margin = bSelected and SELECTED_BG_MARGIN or UNSELECTED_BG_MARGIN
    -- UISetUtils.SetImageBrushRes(self.pWidgetRef.imgPackItemBg, szImg:load())
    -- self.pWidgetRef.imgPackItemBg.Brush.Margin = Margin
end

function UPLobbyShipCommonItem:BindOnSelected(fnOnSelected)
    self.fnOnSelected = fnOnSelected
end

function UPLobbyShipCommonItem:SetItemDisplayData(tbDisplayData)
    self.tbDisplayData = tbDisplayData
    local pWidgetRef = self.pWidgetRef
    
    if tbDisplayData.szBtnImg then
        UISetUtils.SetButtonBrushRes(pWidgetRef.btnItem, tbDisplayData.szBtnImg:load())
    end
    
    if tbDisplayData.nCount then
        pWidgetRef.txtCount:SetText(tbDisplayData.nCount)
        pWidgetRef.txtCount:SetVisibility(ESlateVisibility.Visible)
    else
        pWidgetRef.txtCount:SetVisibility(ESlateVisibility.Collapsed)
    end

    if tbDisplayData.bEnableBtn then
        pWidgetRef.btnItem:SetVisibility(ESlateVisibility.Visible)
    else
        pWidgetRef.btnItem:SetVisibility(ESlateVisibility.SelfHitTestInvisible)
    end

    if tbDisplayData.bNew then
        pWidgetRef.imgNew:SetVisibility(ESlateVisibility.Visible)
    else
        pWidgetRef.imgNew:SetVisibility(ESlateVisibility.Collapsed)
    end

    if self.tbDisplayData and self.tbDisplayData.bShowBox and self.bSelected then
        self.pWidgetRef.imgSelectedBox:SetVisibility(ESlateVisibility.Visible)
    else
        self.pWidgetRef.imgSelectedBox:SetVisibility(ESlateVisibility.Collapsed)
    end
end

function UPLobbyShipCommonItem:SetItemData(tbData)
    self.tbData = tbData
end

function UPLobbyShipCommonItem:GetItemData()
    return self.tbData
end

function UPLobbyShipCommonItem:PlayAnimActive(fnCallback)
    self:PlayAnimation("anim_LobbyItemWeaponEnable", 0, 1, EUMGSequencePlayMode.Forward, 1, function()
        if fnCallback then
            fnCallback()
        end
    end)
end

return  UPLobbyShipCommonItem
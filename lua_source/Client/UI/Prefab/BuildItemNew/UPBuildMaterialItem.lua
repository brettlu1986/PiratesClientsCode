-----------------------------------------------------
--File Name    : UPBuildMaterialItem.lua
--Author       : chenyixin
--Description  : 材料Item
-----------------------------------------------------
local luaclass = require("luaclass")
local PrefabBase = require("PrefabBase")
local UPBuildMaterialItem = luaclass("UPBuildMaterialItem", PrefabBase)

local UISetUtils = require("UISetUtils")

UPBuildMaterialItem.OwnerSub = nil
UPBuildMaterialItem.bSelected = false
UPBuildMaterialItem.fnOnSelected = nil
UPBuildMaterialItem.tbData = nil

--[[
    tbDisplayData = {
        szBtnImg,   -- icon图片资源，为空则使用初始icon
        nCount,     -- item叠加数量，为空则隐藏txtCount
        bEnableBtn, -- item是否可点击，为true则点击时调用fnOnSelected，为空或为false则禁用button
    }
]]

local function OnBtnItemClicked(self)
    if self.fnOnSelected then
        self.fnOnSelected()
    end
end

function UPBuildMaterialItem:OnLoad()
    self.OwnerSub = self.Owner.OwnerSub
    self.pWidgetRef.imgSelected:SetVisibility(ESlateVisibility.Collapsed)
end

function UPBuildMaterialItem:OnShow()
end

function UPBuildMaterialItem:OnBindEvent(EventHelper)
    local pWidgetRef = self.pWidgetRef
    EventHelper:RegisterCppDelegate(pWidgetRef.btnItem.OnClicked, self, OnBtnItemClicked)
end

function UPBuildMaterialItem:SetData(tbSubCategoryTemplate)
    -- local pWidgetRef = self.pWidgetRef
end

function UPBuildMaterialItem:SetVisibility(pVisibility)
    self.pWidgetRef:SetVisibility(pVisibility)
end

function UPBuildMaterialItem:SetSelected(bSelected)
    if self.bSelected == bSelected then
        return
    end

    self.bSelected = bSelected
    self.pWidgetRef.imgSelected:SetVisibility(bSelected and ESlateVisibility.Visible or ESlateVisibility.Collapsed)
end

function UPBuildMaterialItem:BindOnSelected(fnOnSelected)
    self.fnOnSelected = fnOnSelected
end

function UPBuildMaterialItem:SetItemDisplayData(tbDisplayData)
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
        pWidgetRef.btnItem:SetIsEnabled(true)
    else
        pWidgetRef.btnItem:SetIsEnabled(false)
    end
end

function UPBuildMaterialItem:SetItemData(tbData)
    self.tbData = tbData
end

function UPBuildMaterialItem:GetItemData()
    return self.tbData
end

function UPBuildMaterialItem:PlayAnimActive(fnCallback)
    self:PlayAnimation("anim_LobbyItemWeaponEnable", 0, 1, EUMGSequencePlayMode.Forward, 1, function()
        if fnCallback then
            fnCallback()
        end
    end)
end

return  UPBuildMaterialItem
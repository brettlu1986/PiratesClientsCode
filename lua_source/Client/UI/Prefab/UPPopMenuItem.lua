-----------------------------------------------------
--File Name    : UPPopMenuItem.lua
--Description  : Prefab UPPopMenuItem
-----------------------------------------------------

local luaclass = require ("luaclass")
local ListItemBase = require("ListItemBase")
local UPPopMenuItem = luaclass("UPPopMenuItem", ListItemBase)

local UISetUtils = require("UISetUtils")


UPPopMenuItem.nInstanceId = nil
UPPopMenuItem.tbDelayHandle = nil
UPPopMenuItem.SelectedFunc = nil
UPPopMenuItem.DoFunc = nil

local function OnItemClicked(self)
    if self.DoFunc then
        self.DoFunc()
    end
    if self.SelectedFunc then
        self.SelectedFunc()
    end
end


--[[
    public function
]]


function UPPopMenuItem:OnBindEvent(EventHelper)
    local pWidgetRef = self.pWidgetRef
    EventHelper:RegisterCppDelegate(pWidgetRef.kmbtnUse.OnClicked , self, OnItemClicked)
end


function UPPopMenuItem:SetData(tbData, SelectedFunc)
    local pWidgetRef = self.pWidgetRef
    pWidgetRef:SetVisibility(ESlateVisibility.SelfHitTestInvisible)
    pWidgetRef.txtMenu:SetText(tbData.szText)
    if tbData.szIcon then
        UISetUtils.SetImageBrushRes(pWidgetRef.imgIcon, tbData.szIcon:load())
        pWidgetRef.imgIcon:SetVisibility(ESlateVisibility.Visible)
    else
        pWidgetRef.imgIcon:SetVisibility(ESlateVisibility.Collapsed)
    end
    self.DoFunc = tbData.DoFunc
    self.SelectedFunc = SelectedFunc
end

function UPPopMenuItem:HideMenu()
    self.pWidgetRef:SetVisibility(ESlateVisibility.Collapsed)
end

return UPPopMenuItem

-----------------------------------------------------
--File Name    : UPHomeBlockRemoveBuildingView.lua
--Author       : WuJizhou
--Create Time  : 5/14/2019, 11:21:49 AM
--Description  : UPHomeBlockRemoveBuildingView
-----------------------------------------------------
local luaclass = require("luaclass")
local PrefabBase = require("PrefabBase")

local UPHomeBlockRemoveBuildingView = luaclass("UPHomeBlockRemoveBuildingView", PrefabBase)
local UISetUtils = require("UISetUtils")
local UITextDef = require("UITextDef")
local ItemSystem = require("ItemSystem")
local L10N = require("L10N")



function UPHomeBlockRemoveBuildingView:SetViewData(tbBlockData)
    local pWidgetRef = self.pWidgetRef
    pWidgetRef.hbox2:SetVisibility(ESlateVisibility.Collapsed)
    local nInstanceId = tbBlockData.nItemInstanceId
    local tbItem = ItemSystem:GetItem(nInstanceId)
    local nTemplateId = tbItem:GetTemplateId()
    local szItemIcon = ItemSystem:GetItemResTemplate(nTemplateId).szIconPath
    UISetUtils.SetImageBrushRes(pWidgetRef.imgRet, szItemIcon:load())
    pWidgetRef.kmtxtContent:SetText(L10N:Format(UITextDef.HOMELAND_REMOVE_BUILDING_CONFIRM_CONTENT, tbItem:GetName()))
end

return UPHomeBlockRemoveBuildingView
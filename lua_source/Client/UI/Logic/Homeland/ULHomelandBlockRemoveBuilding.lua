-----------------------------------------------------
--File Name    : ULHomelandBlockRemoveBuilding.lua
--Author       : WuJizhou
--Create Time  : 5/13/2019, 5:38:13 PM
--Description  : ULHomelandBlockRemoveBuilding
-----------------------------------------------------
local luaclass = require("luaclass")
local UILogicBase = require("UILogicBase")

local ULHomelandBlockRemoveBuilding = luaclass("ULHomelandBlockRemoveBuilding", UILogicBase)
local UIUtils = require("UIUtils")
local HomelandSystem = require("HomelandSystem")
local UITextDef = require("UITextDef")
local UISetUtils = require("UISetUtils")
local UIDef = require("UIDef")

local function ConfirmRemoveBuilding(tbBlockData)
    HomelandSystem:RequestRemoveItemBuilding(tbBlockData.nBlockId)
end

local function ShowConfirmDialog(self, tbBlockData)
    local Dialog = UIUtils.CreateDialog(UISetUtils.GetL10NTextByKey("HOMELAND_REMOVE_BUILDING_TITLE"))
    local pbView = self.PrefabHelper:CreatePrefab(UIDef.UP_HOME_BLOCK_REMOVE_BUIDING_VIEW)
    pbView:SetViewData(tbBlockData)
    Dialog:SetView(pbView.pWidgetRef)
    Dialog:SetPositiveButtonVisible(true)

    Dialog:SetPositiveText(UITextDef.HOMELAND_REMOVE_BUILDING_CONFIRM)
    Dialog:SetPositiveButtonCallback(ConfirmRemoveBuilding, tbBlockData)
    Dialog:SetNegativeButtonVisible(false)
    Dialog:ShowDialog()
end

function ULHomelandBlockRemoveBuilding:Do(tbBlockData)
    ShowConfirmDialog(self, tbBlockData)
end


return ULHomelandBlockRemoveBuilding
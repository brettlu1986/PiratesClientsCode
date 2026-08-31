-----------------------------------------------------
--File Name    : UPLandmarkUpgradeUnlockContentItem.lua
--Author       : WuJizhou
--Create Time  : 4/23/2019, 11:30:13 AM
--Description  : UPLandmarkUpgradeUnlockContentItem
-----------------------------------------------------
local luaclass = require("luaclass")
local ListItemBase = require("ListItemBase")

local UPLandmarkUpgradeUnlockContentItem = luaclass("UPLandmarkUpgradeUnlockContentItem", ListItemBase)

function UPLandmarkUpgradeUnlockContentItem:OnRefresh(tbData)
    self.pWidgetRef.txtContent:SetText(tbData.l10nContent)
end


return UPLandmarkUpgradeUnlockContentItem
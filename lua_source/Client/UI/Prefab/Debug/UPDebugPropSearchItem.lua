-----------------------------------------------------
--File Name    : UPDebugPropSearchItem.lua
--Author       : Song Fuhao
--Create Time  : 2019-05-16
--Description  :
-----------------------------------------------------
local luaclass = require("luaclass")
local ListItemBase = require("ListItemBase")
local UPDebugPropSearchItem = luaclass("UPDebugPropSearchItem", ListItemBase)

local function OnClickedBtnSearch(self)
    -- 为了便于热更新，随用随加载，仅Debug使用
    local PropValueGMHelper = require("PropValueGMHelper")
    PropValueGMHelper.Search(self.tbData.szKey)
end

function UPDebugPropSearchItem:OnRefresh(tbData)
    self.pWidgetRef.chkBg:SetIsChecked(self.nIndex % 2 == 0)
    self.pWidgetRef.txtName:SetText(tbData.szDesc)
end

function UPDebugPropSearchItem:OnBindEvent(EventHelper)
    EventHelper:RegisterCppDelegate(self.pWidgetRef.btnSearch.OnClicked, self, OnClickedBtnSearch)
end

return UPDebugPropSearchItem
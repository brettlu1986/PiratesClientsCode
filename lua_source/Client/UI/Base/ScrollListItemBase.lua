-----------------------------------------------------
--File Name    : ScrollListItemBase.lua
--Author       : Ran Jie
--Create Time  : 2020-05-20
--Description  : ScrollListItemBase
-----------------------------------------------------

local luaclass = require("luaclass")
local PrefabBase = require("PrefabBase")
local ScrollListItemBase = luaclass("ScrollListItemBase", PrefabBase)

ScrollListItemBase.ListHelper = nil
ScrollListItemBase.nIndex     = nil
ScrollListItemBase.tbData     = nil

function ScrollListItemBase:SetListHelper(ListHelper)
    self.ListHelper = ListHelper
end

function ScrollListItemBase:RefreshItem(nIndex, tbData)
    self.nIndex = nIndex
    self.tbData = tbData
    if tbData ~= nil then -- tbData可能为false
        self:OnRefresh(tbData)
    end
end

function ScrollListItemBase:OnRefresh(tbData)
end

function ScrollListItemBase:IsSelected()
    return self.ListHelper:GetSelectedIndex() == self.nIndex
end


return ScrollListItemBase

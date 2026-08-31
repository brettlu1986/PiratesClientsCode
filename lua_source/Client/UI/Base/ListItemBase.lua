-----------------------------------------------------
--File Name    : ListItemBase.lua
--Author       : Song Fuhao
--Create Time  : 2016-06-17
--Description  : ListItem基类
-----------------------------------------------------

local luaclass = require("luaclass")
local PrefabBase = require("PrefabBase")
local ListItemBase = luaclass("ListItemBase", PrefabBase)

ListItemBase.ListHelper = nil
ListItemBase.nIndex     = nil
ListItemBase.tbData     = nil

function ListItemBase:SetListHelper(ListHelper)
    self.ListHelper = ListHelper
end

function ListItemBase:RefreshItem(nIndex, tbData)
    self.nIndex = nIndex
    self.tbData = tbData
    if tbData ~= nil then -- tbData可能为false
        self:OnRefresh(tbData)
    end
end

function ListItemBase:OnRefresh(tbData)
end

function ListItemBase:RemoveFromDataList()
    self.ListHelper:RemoveItemAt(self.nIndex)
end

function ListItemBase:IsSelected()
    return self.ListHelper:GetSelectedIndex() == self.nIndex
end

function ListItemBase:SelectItem()
    self.ListHelper:SetSelectedIndex(self.nIndex)
end

function ListItemBase:UnselectItem()
    self.ListHelper:UnselectCurrentItem()
end

function ListItemBase:ToogleSelectItem()
    if self:IsSelected() then
        self:UnselectItem()
    else
        self:SelectItem()
    end
end

return ListItemBase

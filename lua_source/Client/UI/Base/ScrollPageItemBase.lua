-----------------------------------------------------
--File Name    : ScrollPageItemBase.lua
--Author       : Ran Jie
--Create Time  : 2017-04-08
--Description  : ScrollPageItem基类
-----------------------------------------------------

local luaclass = require("luaclass")
local PrefabBase = require("PrefabBase")
local ScrollPageItemBase = luaclass("ScrollPageItemBase", PrefabBase)

ScrollPageItemBase.ListHelper = nil
ScrollPageItemBase.nIndex     = nil
ScrollPageItemBase.tbData     = nil

function ScrollPageItemBase:SetListHelper( ListHelper )
    self.ListHelper = ListHelper
end

function ScrollPageItemBase:Init(nIndex)
    self.nIndex = nIndex
end

function ScrollPageItemBase:RefreshItem( nIndex, tbData )
    self.nIndex = nIndex
    self.tbData = tbData
    
    self:OnRefresh(tbData)
end

function ScrollPageItemBase:OnRefresh(tbData)
end



return ScrollPageItemBase

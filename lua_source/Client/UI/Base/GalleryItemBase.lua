-----------------------------------------------------
--File Name    : GalleryItemBase.lua
--Author       : Song Fuhao
--Create Time  : 2019-05-08
--Description  : GalleryItem基类
-----------------------------------------------------

local luaclass = require("luaclass")
local PrefabBase = require("PrefabBase")
local GalleryItemBase = luaclass("GalleryItemBase", PrefabBase)

GalleryItemBase.GalleryHelper   = nil
GalleryItemBase.nIndex          = nil
GalleryItemBase.tbData          = nil

function GalleryItemBase:SetGalleryHelper(GalleryHelper)
    self.GalleryHelper = GalleryHelper
end

function GalleryItemBase:RefreshItem(nIndex, tbData)
    self.nIndex = nIndex
    self.tbData = tbData
    self:OnRefresh(tbData)
end

function GalleryItemBase:IsSelected()
    return self.GalleryHelper:GetSelectedItemIndex() == self.nIndex
end

-- 选中当前Item，默认有动画
function GalleryItemBase:SelectItem(bWithAnim)
    self.GalleryHelper:SelectItemByIndex(self.nIndex, bWithAnim ~= false)
end

-- 选中当前Item，默认有动画
function GalleryItemBase:RefreshSelf()
    self:OnRefresh(self.tbData)
end

-- 派生类Override这个函数实现数据刷新
function GalleryItemBase:OnRefresh(tbData)
end

return GalleryItemBase

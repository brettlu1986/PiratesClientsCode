-----------------------------------------------------
--File Name    : LobbyCaptainSubCategoryTabBarHelper.lua
--Author       : WuJizhou
--Create Time  : 2020-00-27
--Description  : LobbyCaptainSubCategoryTabBarHelper
-----------------------------------------------------

local luaclass = require("luaclass")
local SelfTabBarHelper = require("SelfTabBarHelper")
local LobbyCaptainSubCategoryTabBarHelper = luaclass("LobbyCaptainSubCategoryTabBarHelper", SelfTabBarHelper)


function LobbyCaptainSubCategoryTabBarHelper:SetTabIcon(nIndex, szSelectedIcon, szUnselectedIcon)
    local TabButton = self.tbButtonList[nIndex]
    if(TabButton == nil)then
        return
    end
    TabButton:SetItemIcon(szSelectedIcon, szUnselectedIcon)
end

function LobbyCaptainSubCategoryTabBarHelper:SetOverlayIconVisible(nIndex, bVisible)
    local TabButton = self.tbButtonList[nIndex]
    if(TabButton == nil)then
        return
    end
    TabButton:SetOverlayIconVisible(bVisible)
end

return LobbyCaptainSubCategoryTabBarHelper

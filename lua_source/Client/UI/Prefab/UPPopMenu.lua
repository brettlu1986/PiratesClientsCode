-----------------------------------------------------
--File Name    : UPPopMenu.lua
--Description  : Prefab UPPopMenu
-----------------------------------------------------

local luaclass = require ("luaclass")
local ListItemBase = require("ListItemBase")
local UPPopMenu = luaclass("UPPopMenu", ListItemBase)


local UIDef = require("UIDef")

UPPopMenu.tbMenuPrefab = {}

local function SelectMenuFunc(self)
    for i = 1, #self.tbMenuPrefab do
        local pbMenuItem = self.tbMenuPrefab[i]
        pbMenuItem:HideMenu()
    end
    self:HideMenu()
end

--[[
    public function
]]


function UPPopMenu:SetData(tbData, nGroupId)
    local PrefabHelper = self.PrefabHelper
    local pWidgetRef = self.pWidgetRef
    self.nGroupId = nGroupId
    self.pWidgetRef:SetVisibility(ESlateVisibility.SelfHitTestInvisible)
    for k, v in ipairs(tbData)do
        local pbMenuItem = self.tbMenuPrefab[k]
        if not pbMenuItem then
            local pMenuItemWidget = nil
            pbMenuItem, pMenuItemWidget = PrefabHelper:CreatePrefab(UIDef.UP_POP_MENU_ITEM)
            pbMenuItem:SetOwner(self)
            pWidgetRef.vbxMenu:AddChildToVerticalBox(pMenuItemWidget)
            table.insert(self.tbMenuPrefab, pbMenuItem)
        end
        pbMenuItem:SetData(v, function()  SelectMenuFunc(self) end)
        
    end
    for i = #tbData + 1, #self.tbMenuPrefab do
        local pbMenuItem = self.tbMenuPrefab[i]
        pbMenuItem:HideMenu()
    end
end

function UPPopMenu:HideMenu()
    self.nGroupId = nil
    self.pWidgetRef:SetVisibility(ESlateVisibility.Collapsed)
end

return UPPopMenu

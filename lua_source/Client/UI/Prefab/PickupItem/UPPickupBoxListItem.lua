-----------------------------------------------------
--File Name    : UPPickupBoxListItem.lua
--Description  : Prefab FightPanel
-----------------------------------------------------

local luaclass = require ("luaclass")
local ListItemBase = require("ListItemBase")
local UPPickupBoxListItem = luaclass("UPPickupBoxListItem", ListItemBase)


local UIDef = require("UIDef")


UPPickupBoxListItem.tbItemPrefabList = nil

local function GetOrCreateChildPrefab(self, nIndex, szPrefabName, nRow, nColumn)
    local PrefabScript = self.tbItemPrefabList[nIndex]
    if not PrefabScript then
        PrefabScript = self.PrefabHelper:CreatePrefab(szPrefabName)
        --logdebug("AddChild,nIndex=",nIndex)
        self.pWidgetRef.ugridBox:AddChildToUniformGrid(PrefabScript.pWidgetRef, nRow, nColumn)
        table.insert(self.tbItemPrefabList, PrefabScript)
    end
    return PrefabScript
end

local function HideAllChild(self)
    for k, v in pairs(self.tbItemPrefabList) do
        v:Hide()
    end
end

--[[
    public function
]]


function UPPickupBoxListItem:OnRefresh(tbListData)
    HideAllChild(self)
    if not tbListData then
        log("UPPickupBoxListItem:OnRefresh, tbListData is nil")
        return
    end
    local pWidgetRef = self.pWidgetRef
    if tbListData.szLastOwnerName then
        pWidgetRef.OwnerName:SetVisibility(ESlateVisibility.Visible)
        pWidgetRef.ugridBox:SetVisibility(ESlateVisibility.Collapsed)
        pWidgetRef.OwnerName:SetText(tbListData.szLastOwnerName)
        return
    else
        pWidgetRef.OwnerName:SetVisibility(ESlateVisibility.Collapsed)
        pWidgetRef.ugridBox:SetVisibility(ESlateVisibility.Visible)
    end
    for i = 1, #tbListData.tbItemList do
        --logdebug("OnRefresh:i=",i)
        local tbItemData = tbListData.tbItemList[i]
        local PrefabScript = GetOrCreateChildPrefab(self, i, UIDef.UP_PICKUP_ITEM, 0, i - 1)
        PrefabScript:SetData(tbItemData)
    end
end

function UPPickupBoxListItem:OnLoad()
    self.tbItemPrefabList = {}
end

function UPPickupBoxListItem:OnExit()
    --self.tbItemPrefabList = {}
    HideAllChild(self)
end

return UPPickupBoxListItem

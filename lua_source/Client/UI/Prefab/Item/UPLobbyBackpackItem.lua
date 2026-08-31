-----------------------------------------------------
--File Name    : UPLobbyBackpackItem.lua
--Author       : zhiyuan
--Create Time  : 2019-02-25
--Description  : 背包里的物品Item
-----------------------------------------------------
local luaclass = require ("luaclass")
local ListItemBase = require("ListItemBase")
local UPLobbyBackpackItem = luaclass("UPLobbyBackpackItem", ListItemBase)

local LobbyItemUiHelper = require("LobbyItemUiHelper")
local GamePlayerSelfHelper = require("GamePlayerSelfHelper")

UPLobbyBackpackItem.tbItemData = nil
UPLobbyBackpackItem.Item = nil
UPLobbyBackpackItem.nAvailableCount = nil
UPLobbyBackpackItem.OnItemPressedDelegate = nil

local function OnClicked(self)
    local Item = self.Item
    if self.tbItemData.bShowNew then
        local pWidgetRef = self.pWidgetRef
        LobbyItemUiHelper.ShowNew(pWidgetRef, false)
        GamePlayerSelfHelper:Get().PlayerNewItemRecordComponent:UnmarkNewItemsInBackpack(Item:GetInstanceId())
        self.tbItemData.bShowNew = nil
    end

    self:SelectItem()
    local OnItemPressedDelegate = self.OnItemPressedDelegate
    if OnItemPressedDelegate then
        OnItemPressedDelegate:Fire(Item, self.nAvailableCount)
     end
end

local function Refresh(self, tbItemData)
    self.tbItemData = tbItemData
    local Item = tbItemData.Item

    self.Item = Item
    self.OnItemPressedDelegate = tbItemData.OnItemPressedDelegate

    local nAvailableCount = tbItemData.nAvailableCount
    if nAvailableCount then
        self.nAvailableCount = nAvailableCount
    else
        self.nAvailableCount = Item:GetStackCount()
    end

    local pWidgetRef = self.pWidgetRef

    local nTemplateId = Item:GetTemplateId()

    local nGrade = Item:GetGrade()
    local nCategory = Item:GetCategory()
    LobbyItemUiHelper.SetGradeColorImage(pWidgetRef, nGrade)
    LobbyItemUiHelper.SetCount(pWidgetRef, self.nAvailableCount)
    LobbyItemUiHelper.SetIconImage(pWidgetRef, nTemplateId)
    LobbyItemUiHelper.SetGradeImage(pWidgetRef, nCategory, nGrade)

    if self:IsSelected() then
        LobbyItemUiHelper.SetSelected(pWidgetRef, true)
    else
        LobbyItemUiHelper.SetSelected(pWidgetRef, false)
    end

    LobbyItemUiHelper.ShowTryTxt(pWidgetRef, nTemplateId)

    LobbyItemUiHelper.ShowNew(pWidgetRef, tbItemData.bShowNew)
end

function UPLobbyBackpackItem:OnRefresh(tbItemData)
    Refresh(self, tbItemData)
end

function UPLobbyBackpackItem:OnBindEvent(EventHelper)
    EventHelper:RegisterCppDelegate(self.pWidgetRef.btnItem.OnClicked, self, OnClicked)
end

return UPLobbyBackpackItem

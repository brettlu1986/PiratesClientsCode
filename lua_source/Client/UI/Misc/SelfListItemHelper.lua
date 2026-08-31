-----------------------------------------------------
--File Name    : SelfListItemHelper.lua
--Author       : Ran Jie
--Create Time  : 2020-05-18
--Description  : 划动到特定item的滚动列表
-----------------------------------------------------

local luaclass = require("luaclass")
local SelfListItemHelper = luaclass("SelfListItemHelper")

local CppDelegate = require("CppDelegate")
local LuaDelegate = require("LuaDelegate")
local UninitCheckSystem = require("UninitCheckSystem")

local NONE_INDEX = -1

--[[
    public
]]
SelfListItemHelper.Owner                                = nil       -- for get prefab
SelfListItemHelper.pListRef                             = nil       -- for bind OnGenerateListItem event
SelfListItemHelper.pOnItemGeneratedDelegate             = nil
SelfListItemHelper.pOnItemReleasedDelegate              = nil
SelfListItemHelper.pOnSelectedIndexChangedDelegate      = nil
SelfListItemHelper.pOnScrollStopedDelegate              = nil
SelfListItemHelper.pOnScrollStartedDelegate              = nil

SelfListItemHelper.tbDataList                           = nil
SelfListItemHelper.tbItemList                           = nil
SelfListItemHelper.tbItemUniqueIDs                      = nil       -- luaIndex->UniqueID
SelfListItemHelper.tbExtraDatas                         = nil       -- 用来提供额外的数据供Item和调用UI间通信和存储公nSelectedIdx

SelfListItemHelper.szPrefabName                         = nil
SelfListItemHelper.nSelectIndex                         = -1
SelfListItemHelper.OnSelectedChangedDelegate            = nil
SelfListItemHelper.OnScrollStopedDelegate               = nil
SelfListItemHelper.OnScrollStartedDelegate              = nil


local function OnItemGenerated(self, nIndex, pWidgetRef)
    local nUniqueID = ExtendBlueprintFunctions.GetObjectUniqueID(pWidgetRef)
    local ListItem = self.tbItemList[nUniqueID]
    local nLuaIndex = nIndex + 1
    if not self.tbDataList[nLuaIndex] then
        logwarning("SelfListItemHelper:OnItemGenerated",nLuaIndex, #self.tbDataList)
        return
    end
    --logdebug("OnItemGenerated!!!!!!!!!!!!!!!!!!!!",nIndex,nUniqueID)
    if ListItem == nil then
        ListItem = self.Owner.PrefabHelper:BindPrefab(pWidgetRef,self.szPrefabName)
        ListItem:SetListHelper(self)
        self.tbItemList[nUniqueID] = ListItem
    end
    
    self.tbItemUniqueIDs[nLuaIndex] = nUniqueID
    ListItem:RefreshItem(nLuaIndex, self.tbDataList[nLuaIndex])
end

local function OnItemReleased(self, nIndex, pWidgetRef)
    local nUniqueID = ExtendBlueprintFunctions.GetObjectUniqueID(pWidgetRef)
    local ListItem = self.tbItemList[nUniqueID]
    --logdebug("OnItemReleased!!!!!!!!!!!!!!!!!!!!",nIndex,ListItem)
    if ListItem then
        if self.tbItemUniqueIDs[ListItem.nIndex] == nUniqueID then
            self.tbItemUniqueIDs[ListItem.nIndex] = nil
            ListItem.nIndex = nil
            ListItem.tbData = nil
        end
        self.Owner.PrefabHelper:UnbindPrefab(ListItem)
        self.tbItemList[nUniqueID] = nil
    end
end

local function OnSelectIndexChanged(self, nIndex)
    --logdebug("OnSelectIndexChanged,self.nSelectIndex=",nIndex + 1,nIndex)
    local nLastSelectedIdx = self.nSelectIndex
    self.nSelectIndex = nIndex + 1
    if nLastSelectedIdx > 0 then
        self:RefreshItemByIndex(nLastSelectedIdx)
    end
    self:RefreshItemByIndex(self.nSelectIndex)
    self.OnSelectedChangedDelegate:Fire(self.nSelectIndex)
end

local function OnScrollStarted(self)
    --logdebug("OnScrollStarted!!!!!!!!!!!!self.nSelectIndex=",self.nSelectIndex)
    if self.nSelectIndex > 0 then
        local nLastSelectedIdx = self.nSelectIndex
        self.nSelectIndex = -1
        self:RefreshItemByIndex(nLastSelectedIdx)
    end
    self.OnScrollStartedDelegate:Fire()
end

local function OnScrollStoped(self)
    
    local nIndex = self.pListRef:GetSelectedItemIndex()
    self.nSelectIndex = nIndex + 1
    --logdebug("OnScrollStoped!!!!!!!!!!!!,self.nSelectIndex=",self.nSelectIndex, nIndex)
    self:RefreshItemByIndex(self.nSelectIndex)
    self.OnScrollStopedDelegate:Fire(self.nSelectIndex)
end

function SelfListItemHelper:Init(Owner, pListRef, tbDataList, szPrefabName)
    UninitCheckSystem:Register(self)
    if Owner == nil then
        logerror('[UI] SelfListItemHelper init faild, owner is nil')
        return
    end
    if pListRef == nil then
        logerror('[UI] SelfListItemHelper init faild, list refrence is nil')
        return
    end
    self.Owner = Owner
    self.pListRef = pListRef
    self.tbDataList = {}
    self.tbItemList = {}
    self.tbItemUniqueIDs = {}
    self.tbExtraDatas = {}
    self.szPrefabName = szPrefabName
    if tbDataList then
        self:SetData(tbDataList)
    end

    self.pOnItemGeneratedDelegate = CppDelegate:BindMethod(self.pListRef.OnItemGenerated, self, OnItemGenerated)
    self.pOnItemReleasedDelegate = CppDelegate:BindMethod(self.pListRef.OnItemReleased, self, OnItemReleased)
    self.pOnSelectedIndexChangedDelegate = CppDelegate:BindMethod(self.pListRef.OnSelectedIndexChanged, self, OnSelectIndexChanged)
    self.pOnScrollStartedDelegate = CppDelegate:BindMethod(self.pListRef.OnScrollStarted, self, OnScrollStarted)
    self.pOnScrollStopedDelegate = CppDelegate:BindMethod(self.pListRef.OnScrollStoped, self, OnScrollStoped)
    self.OnSelectedChangedDelegate = LuaDelegate()
    self.OnScrollStopedDelegate = LuaDelegate()
    self.OnScrollStartedDelegate = LuaDelegate()
end

function SelfListItemHelper:GetItemByIndex(nIndex)
    local nUniqueID = self.tbItemUniqueIDs[nIndex]
    if nUniqueID ~= nil then
        return self.tbItemList[nUniqueID]
    end
end

function SelfListItemHelper:Uninit()
    UninitCheckSystem:Unregister(self)
    if self.pOnItemGeneratedDelegate then
        self.pOnItemGeneratedDelegate:Unbind()
    end
    if self.pOnItemReleasedDelegate then
        self.pOnItemReleasedDelegate:Unbind()
    end
    if self.pOnSelectedIndexChangedDelegate then
        self.pOnSelectedIndexChangedDelegate:Unbind()
    end
    if self.pOnScrollStopedDelegate then
        self.pOnScrollStopedDelegate:Unbind()
    end
    if self.pOnScrollStartedDelegate then
        self.pOnScrollStartedDelegate:Unbind()
    end
end

function SelfListItemHelper:SetData(tbDataList)
    self.tbDataList = tbDataList and tbDataList or {}
    self:RequestListRefresh()
end

function SelfListItemHelper:RemoveItemAt(nIndex)
    table.remove( self.tbDataList, nIndex )
    self:RequestListRefresh()
end

function SelfListItemHelper:RequestListRefresh()
    if self.nSelectIndex > #self.tbDataList then
        self:UnSelectItem()
    end
    self.pListRef:RequestListResize(#self.tbDataList)
end

function SelfListItemHelper:RefreshItemByIndex(nIndex)
    if nIndex == NONE_INDEX then
        return
    end

    local nUniqueID = self.tbItemUniqueIDs[nIndex]
    if nUniqueID ~= nil then
        local ListItem = self.tbItemList[nUniqueID]
        if ListItem ~= nil then
            ListItem:RefreshItem( nIndex, self.tbDataList[nIndex] )
        end
    end
end

function SelfListItemHelper:SelectItemByIndex(nIndex, bWithAnim)
    if nIndex < 1 or nIndex > #self.tbDataList then
        return
    end
    self.pListRef:SelectItemByIndex(nIndex - 1, bWithAnim == true)
end

function SelfListItemHelper:ScrollToTopLeft(bWithAnimation)
    self:ScrollToIndexTopLeft(1, bWithAnimation)
end

function SelfListItemHelper:ScrollToIndexTopLeft(nIndex, bWithAnimation)
    self.pListRef:ScrollToIndex(nIndex - 1, bWithAnimation == true)
end

function SelfListItemHelper:ScrollToIndexCenter(nIndex, bWithAnimation)
    self.pListRef:ScrollToIndex(nIndex - 1, bWithAnimation == true)
end

function SelfListItemHelper:GetViewingItemIndexFromTop()
    return self.pListRef:GetViewingItemIndexFromTop() + 1
end

function SelfListItemHelper:GetViewingItemIndexFromBottom()
    return self.pListRef:GetViewingItemIndexFromBottom() + 1
end

function SelfListItemHelper:SetScrollEnabled(bEnabled)
    self.pListRef:SetScrollEnabled(bEnabled)
end

function SelfListItemHelper:GetSelectedIndex()
    return self.nSelectIndex
end

function SelfListItemHelper:UnSelectItem()
    self.nSelectIndex = -1
    self.pListRef:ResetSelectedIndex()
end

return SelfListItemHelper

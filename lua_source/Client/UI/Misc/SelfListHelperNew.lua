-----------------------------------------------------
--File Name    : SelfListHelperNew.lua
--Author       : Song Fuhao
--Create Time  : 2019-05-25
--Description  : ListView新版控件的Helper，之后所有控件都会迁到这个
-----------------------------------------------------

local luaclass = require("luaclass")
local SelfListHelperNew = luaclass("SelfListHelperNew")

local CppDelegate = require("CppDelegate")
local LuaDelegate = require("LuaDelegate")
local UninitCheckSystem = require("UninitCheckSystem")

local NONE_INDEX = -1

--[[
    public
]]
SelfListHelperNew.Owner                      = nil       -- for get prefab
SelfListHelperNew.pListRef                   = nil       -- for bind OnGenerateListItem event
SelfListHelperNew.pOnItemGeneratedDelegate          = nil
-- SelfListHelperNew.pOnItemReleasedDelegate           = nil

SelfListHelperNew.tbDataList                 = nil
SelfListHelperNew.tbItemList                 = nil
SelfListHelperNew.tbItemUniqueIDs            = nil       -- luaIndex->UniqueID
SelfListHelperNew.tbExtraDatas               = nil       -- 用来提供额外的数据供Item和调用UI间通信和存储公nSelectedIdx

SelfListHelperNew.szPrefabName               = nil
SelfListHelperNew.nSelectedIdx               = NONE_INDEX
SelfListHelperNew.OnSelectedChangedDelegate  = nil

-- local function ToLuaIndex(nCppIndex)
--     -- body
-- end

-- local function ToCppIndex(nLuaIndex)
--     -- body
-- end

local function OnItemGenerated(self, nIndex, pWidgetRef)
    local nUniqueID = ExtendBlueprintFunctions.GetObjectUniqueID(pWidgetRef)
    local ListItem = self.tbItemList[nUniqueID]
    if ListItem == nil then
        ListItem = self.Owner.PrefabHelper:BindPrefab(pWidgetRef,self.szPrefabName)
        ListItem:SetListHelper(self)
        self.tbItemList[nUniqueID] = ListItem
    end
    local nLuaIndex = nIndex + 1
    self.tbItemUniqueIDs[nLuaIndex] = nUniqueID
    ListItem:RefreshItem(nLuaIndex, self.tbDataList[nLuaIndex])
end

local function OnItemReleased(self, nIndex, pWidgetRef)
    local nUniqueID = ExtendBlueprintFunctions.GetObjectUniqueID(pWidgetRef)
    local ListItem = self.tbItemList[nUniqueID]
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

function SelfListHelperNew:Init(Owner, pListRef, tbDataList, szPrefabName)
    UninitCheckSystem:Register(self)
    if Owner == nil then
        logerror('[UI] SelfListHelperNew init faild, owner is nil')
        return
    end
    if pListRef == nil then
        logerror('[UI] SelfListHelperNew init faild, list refrence is nil')
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
    self.OnSelectedChangedDelegate = LuaDelegate()
end

function SelfListHelperNew:Uninit()
    UninitCheckSystem:Unregister(self)
    if self.pOnItemGeneratedDelegate then
        self.pOnItemGeneratedDelegate:Unbind()
    end
    if self.pOnItemReleasedDelegate then
        self.pOnItemReleasedDelegate:Unbind()
    end
end

function SelfListHelperNew:SetData(tbDataList)
    self.nSelectedIdx = NONE_INDEX
    self.tbDataList = tbDataList and tbDataList or {}
    self:RequestListRefresh()
end

function SelfListHelperNew:RemoveItemAt(nIndex)
    table.remove( self.tbDataList, nIndex )
    self:RequestListRefresh()
end

function SelfListHelperNew:RequestListRefresh()
    self.pListRef:RequestListResize(#self.tbDataList)
end

function SelfListHelperNew:RefreshItemByIndex(nIndex)
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

function SelfListHelperNew:SetSelectedIndex(nIndex)
    local nLastSelectedIdx = self.nSelectedIdx
    self.nSelectedIdx = nIndex
    self.OnSelectedChangedDelegate:Fire(nIndex)
    self:RefreshItemByIndex(nLastSelectedIdx)
    self:RefreshItemByIndex(self.nSelectedIdx)
--    if nIndex ~= NONE_INDEX then
--        self:ScrollToIndex(nIndex, false)
--    elseif nLastSelectedIdx ~= NONE_INDEX then
--        self:ScrollToIndex(nLastSelectedIdx, false)
--    end
end

function SelfListHelperNew:GetSelectedIndex()
    return self.nSelectedIdx
end

function SelfListHelperNew:GetSelectedData()
    return self.tbDataList[self.nSelectedIdx]
end

function SelfListHelperNew:UnselectCurrentItem()
    self:SetSelectedIndex(NONE_INDEX)
end

function SelfListHelperNew:ScrollToTopLeft(bWithAnimation)
    self:ScrollToIndexTopLeft(1, bWithAnimation)
end

function SelfListHelperNew:ScrollToIndexTopLeft(nIndex, bWithAnimation)
    self.pListRef:ScrollToIndex(nIndex - 1, bWithAnimation == true)
end

function SelfListHelperNew:ScrollToIndexCenter(nIndex, bWithAnimation)
    self.pListRef:ScrollToIndex(nIndex - 1, bWithAnimation == true)
end

function SelfListHelperNew:GetViewingItemIndexFromTop()
    return self.pListRef:GetViewingItemIndexFromTop() + 1
end

function SelfListHelperNew:GetViewingItemIndexFromBottom()
    return self.pListRef:GetViewingItemIndexFromBottom() + 1
end

function SelfListHelperNew:SetScrollEnabled(bEnabled)
    self.pListRef:SetScrollEnabled(bEnabled)
end

return SelfListHelperNew

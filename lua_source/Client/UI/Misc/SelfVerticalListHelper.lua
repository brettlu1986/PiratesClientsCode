-----------------------------------------------------
--File Name    : SelfVerticalListHelper.lua
--Author       : Song Fuhao
--Create Time  : 2016-11-18
--Description  : SelfVerticalListHelper
-----------------------------------------------------

local luaclass = require("luaclass")
local SelfVerticalListHelper = luaclass("SelfVerticalListHelper")

local CppDelegate = require("CppDelegate")
local LuaDelegate = require("LuaDelegate")
local UninitCheckSystem = require("UninitCheckSystem")

--[[
    private
]]
local NONE_INDEX = -1


--[[
    public
]]
SelfVerticalListHelper.Owner = nil -- for get prefab
SelfVerticalListHelper.pListRef = nil -- for bind OnGenerateListItem event
SelfVerticalListHelper.GenerateDelegate = nil
SelfVerticalListHelper.ReleaseDelegate = nil
SelfVerticalListHelper.tbDataList = nil
SelfVerticalListHelper.tbItemList = nil
SelfVerticalListHelper.tbExtraDatas = nil -- 用来提供额外的数据供Item和调用UI间通信和存储公nSelectedIdx
SelfVerticalListHelper.tbItemUniqueIDs = nil -- luaIndex->UniqueID
SelfVerticalListHelper.OnSelectedChangedDelegate = nil
SelfVerticalListHelper.nSelectedIdx = NONE_INDEX
SelfVerticalListHelper.szPrefabName = nil
SelfVerticalListHelper.bAutoScrollEnabled = true

function SelfVerticalListHelper:Init( Owner, pListRef, tbDataList, szPrefabName )
    UninitCheckSystem:Register(self)
    if Owner == nil then
        logerror('[UI] SelfVerticalListHelper init faild, owner is nil')
        return
    end
    if pListRef == nil then
        logerror('[UI] SelfVerticalListHelper init faild, list refrence is nil')
        return
    end
    self.Owner = Owner
    self.pListRef = pListRef
    self.tbDataList = {}
    self.tbItemList = {}
    self.tbExtraDatas = {}
    self.tbItemUniqueIDs = {}
    self.szPrefabName = szPrefabName
    if tbDataList then
        self:SetData(tbDataList)
    end

    self.GenerateDelegate = CppDelegate:BindMethod(self.pListRef.OnGenerateListItem, self, self.OnGenerateListItem)
    self.ReleaseDelegate = CppDelegate:BindMethod(self.pListRef.OnReleaseListItem, self, self.OnReleaseListItem)
    self.OnSelectedChangedDelegate = LuaDelegate()
end

function SelfVerticalListHelper:Uninit()
    UninitCheckSystem:Unregister(self)
    if self.GenerateDelegate then
        self.GenerateDelegate:Unbind()
        self.GenerateDelegate = nil
    end
    if self.ReleaseDelegate then
        self.ReleaseDelegate:Unbind()
        self.ReleaseDelegate = nil
    end
end

function SelfVerticalListHelper:SetEnable(bEnable)
    if bEnable then
        if not self.GenerateDelegate then
            self.GenerateDelegate = CppDelegate:BindMethod(self.pListRef.OnGenerateListItem, self, self.OnGenerateListItem)
        end
        if not self.ReleaseDelegate then
            self.ReleaseDelegate = CppDelegate:BindMethod(self.pListRef.OnReleaseListItem, self, self.OnReleaseListItem)
        end
    else
        self:Uninit()
    end
    if not self.tbItemList then
        return
    end
    for k, v in pairs(self.tbItemList) do
        --if self.tbItemUniqueIDs[v.nIndex] then
            if bEnable then
                v:BindEvent()
            else
                v:UnbindEvent()
            end
        --end
    end
end

function SelfVerticalListHelper:SetData( tbDataList, bResetSelect )
    if bResetSelect then
        self.nSelectedIdx = NONE_INDEX
    end
    self.tbDataList = tbDataList and tbDataList or {}
    self:RequestListRefresh()
end

function SelfVerticalListHelper:GetData()
    return self.tbDataList
end

function SelfVerticalListHelper:AddItem( tbItemData )
    table.insert( self.tbDataList, tbItemData )
    self:RequestListRefresh()
end

function SelfVerticalListHelper:InsertItem(tbItemData, nIndex)
    table.insert( self.tbDataList, nIndex, tbItemData )
    self:RequestListRefresh()
end

function SelfVerticalListHelper:SetItemAt(tbItemData, nIndex)
    self.tbDataList[nIndex] = tbItemData
    self:RequestListRefreshByIndex(nIndex)
end

function SelfVerticalListHelper:RemoveItemAt( nIndex )
    table.remove( self.tbDataList, nIndex )
    self:RequestListRefresh()
end

function SelfVerticalListHelper:RemoveItem( tbItemData )
    for i,v in ipairs(self.tbDataList) do
        if v == tbItemData then
            self:RemoveAt(i)
            return
        end
    end
    self:RequestListRefresh()
end

function SelfVerticalListHelper:RequestListRefresh()
    self.pListRef:RequestListResize(#self.tbDataList)
end

function SelfVerticalListHelper:IsBottom()
    return self.pListRef:IsItemInView( #self.tbDataList - 1 )
end

function SelfVerticalListHelper:IsItemInView( nIndex )
    return self.pListRef:IsItemInView( nIndex )
end

-- 刷新List时，如果涉及到Item高度变化出现显示BUG，可以调用此接口
function SelfVerticalListHelper:ForceRequestListRefresh()
    self.pListRef:ForceRequestListRefresh()
end

function SelfVerticalListHelper:RequestListRefreshByIndex( nIndex )
    if nIndex > 0 then
        self.pListRef:RequestListRefresh(nIndex - 1)
    end
end

function SelfVerticalListHelper:ScrollToTop( bWithAnim )
    self.pListRef:ScrollToTop( bWithAnim == true )
end

function SelfVerticalListHelper:ScrollToBottom( bWithAnim )
    self.pListRef:ScrollToBottom( bWithAnim == true )
end

function SelfVerticalListHelper:ScrollToIndex( nIndex, bWithAnim )
    self.pListRef:ScrollToItemByIndex( nIndex - 1, bWithAnim == true )
end

function SelfVerticalListHelper:OnGenerateListItem( nIndex, pWidgetRef )
    local nUniqueID = ExtendBlueprintFunctions.GetObjectUniqueID(pWidgetRef)
    local ListItem = self.tbItemList[nUniqueID]
    local nLuaIndex = nIndex + 1
    if ListItem == nil then
        ListItem = self.Owner.PrefabHelper:BindPrefab(pWidgetRef,self.szPrefabName)
        ListItem:SetListHelper(self)
        self.tbItemList[nUniqueID] = ListItem
    end
    self.tbItemUniqueIDs[nLuaIndex] = nUniqueID
    ListItem:RefreshItem( nLuaIndex, self.tbDataList[nLuaIndex] )
end

function SelfVerticalListHelper:OnReleaseListItem( pWidgetRef )
    local nUniqueID = ExtendBlueprintFunctions.GetObjectUniqueID(pWidgetRef)
    local ListItem = self.tbItemList[nUniqueID]
    if ListItem then
        if self.tbItemUniqueIDs[ListItem.nIndex] == nUniqueID then
            self.tbItemUniqueIDs[ListItem.nIndex] = nil
            ListItem.nIndex = nil
            ListItem.tbData = nil
        end
    end
end

function SelfVerticalListHelper:RefreshItemByIndex(nIndex)
    if nIndex == NONE_INDEX or nIndex > #(self.tbDataList) then
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

-- 刷新可以看见的ListItem（不改变数据及位置）
function SelfVerticalListHelper:RefreshItemInView()
    for nIndex, nUniqueID in pairs(self.tbItemUniqueIDs) do
        local ListItem = self.tbItemList[nUniqueID]
        if ListItem ~= nil then
            ListItem:RefreshItem(nIndex, self.tbDataList[nIndex])
        end
    end
end

function SelfVerticalListHelper:SetSelectedIndex(nIndex)
    local nLastSelectedIdx = self.nSelectedIdx
    self.nSelectedIdx = nIndex
    self.OnSelectedChangedDelegate:Fire(nIndex)
    self:RefreshItemByIndex(nLastSelectedIdx)
    self:RefreshItemByIndex(self.nSelectedIdx)
    if self.bAutoScrollEnabled then
        if nIndex ~= NONE_INDEX then
            self:ScrollToIndex(nIndex, false)
        elseif nLastSelectedIdx ~= NONE_INDEX then
            self:ScrollToIndex(nLastSelectedIdx, false)
        end
    end
end

-- 只更新状态
function SelfVerticalListHelper:SetSelectedIndexState(nIndex)
    local nLastSelectedIdx = self.nSelectedIdx
    self.nSelectedIdx = nIndex
    self:RefreshItemByIndex(nLastSelectedIdx)
    self:RefreshItemByIndex(self.nSelectedIdx)
end

function SelfVerticalListHelper:GetSelectedIndex()
    return self.nSelectedIdx
end

function SelfVerticalListHelper:GetSelectedData()
    return self.tbDataList[self.nSelectedIdx]
end

function SelfVerticalListHelper:UnselectCurrentItem()
    self:SetSelectedIndex(NONE_INDEX)
end

function SelfVerticalListHelper:SetAutoScrollEnabled(bEnabled)
    self.bAutoScrollEnabled = bEnabled
end

function SelfVerticalListHelper:SetScrollEnabled(bEnabled)
    self.pListRef:SetScrollEnabled(bEnabled)
end

function SelfVerticalListHelper:SetCellInLineCount(nCellInLineCount)
    self.pListRef:SetCellInLineCount(nCellInLineCount)
end

return SelfVerticalListHelper

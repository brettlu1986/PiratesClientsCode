-----------------------------------------------------
--File Name    : SelfGalleryHelper.lua
--Author       : Song Fuhao
--Create Time  : 2018-03-05
--Description  : 用于给舰船/伙伴等皮肤类型的列表使用
-----------------------------------------------------
-- TODO Hao 这个回头要继承自ListHelperNew

local luaclass = require("luaclass")
local SelfGalleryHelper = luaclass("SelfGalleryHelper")

local LuaDelegate = require("LuaDelegate")
local CppDelegate = require("CppDelegate")
local UninitCheckSystem = require("UninitCheckSystem")

local DEFAULT_INDEX = 0

SelfGalleryHelper.Owner                             = nil       -- for get prefab
SelfGalleryHelper.pGalleryRef                       = nil       -- for bind OnGenerateListItem event
SelfGalleryHelper.pOnGenerateDelegate               = nil
SelfGalleryHelper.pOnSelectedIndexChangedDelegate   = nil

SelfGalleryHelper.tbDataList                        = nil
SelfGalleryHelper.tbItemList                        = nil
SelfGalleryHelper.tbItemUniqueIDs                   = nil       -- luaIndex->UniqueID
SelfGalleryHelper.tbExtraDatas                      = nil       -- 用来提供额外的数据供Item和调用UI间通信和存储公nSelectedIdx

SelfGalleryHelper.szPrefabName                      = nil
SelfGalleryHelper.nSelectedItemIndex                = DEFAULT_INDEX
SelfGalleryHelper.OnSelectedChangedDelegate         = nil

local function OnItemGenerated(self, nIndex, pWidgetRef)
    local nUniqueID = ExtendBlueprintFunctions.GetObjectUniqueID(pWidgetRef)
    local GalleryItem = self.tbItemList[nUniqueID]
    if GalleryItem == nil then
        GalleryItem = self.Owner.PrefabHelper:BindPrefab(pWidgetRef,self.szPrefabName)
        GalleryItem:SetGalleryHelper(self)
        self.tbItemList[nUniqueID] = GalleryItem
    end
    local nLuaIndex = nIndex + 1
    self.tbItemUniqueIDs[nLuaIndex] = nUniqueID
    GalleryItem:RefreshItem(nLuaIndex, self.tbDataList[nLuaIndex])
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
    end
end

local function OnSelectedIndexChanged(self, nIndex)
    local nLastSelectedItemIndex = self.nSelectedItemIndex
    self.nSelectedItemIndex = nIndex + 1
    self:RefreshItemByIndex(nLastSelectedItemIndex)
    self:RefreshItemByIndex(self.nSelectedItemIndex)
    self.OnSelectedChangedDelegate:Fire(self.nSelectedItemIndex)
end

function SelfGalleryHelper:Init(Owner, pGalleryRef, tbDataList, szPrefabName)
    UninitCheckSystem:Register(self)
    if Owner == nil then
        logerror('[UI] SelfGalleryHelper init faild, owner is nil')
        return
    end
    if pGalleryRef == nil then
        logerror('[UI] SelfGalleryHelper init faild, gallery refrence is nil')
        return
    end
    self.Owner = Owner
    self.pGalleryRef = pGalleryRef
    self.tbItemList = {}
    self.tbItemUniqueIDs = {}
    self.tbExtraDatas = {}
    self.szPrefabName = szPrefabName
    if tbDataList then
        self:SetData(tbDataList)
    else
        self.tbDataList = {}
    end

    self.pOnItemGeneratedDelegate = CppDelegate:BindMethod(self.pGalleryRef.OnItemGenerated, self, OnItemGenerated)
    self.pOnItemReleasedDelegate = CppDelegate:BindMethod(self.pGalleryRef.OnItemReleased, self, OnItemReleased)
    self.pOnSelectedIndexChangedDelegate = CppDelegate:BindMethod(self.pGalleryRef.OnSelectedIndexChanged, self, OnSelectedIndexChanged)
    self.OnSelectedChangedDelegate = LuaDelegate()
end

function SelfGalleryHelper:Reset()
    local PrefabHelper = self.Owner.PrefabHelper
    for k, v in pairs(self.tbItemList) do
        PrefabHelper:UnbindPrefab(v)
    end
    self.tbItemList = {}
    self.tbItemUniqueIDs = {}
    self:SetData()
end

function SelfGalleryHelper:Uninit()
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
end

function SelfGalleryHelper:SetData(tbDataList)
    self.tbDataList = tbDataList or {}
    self:RequestListRefresh()
end

function SelfGalleryHelper:RequestListRefresh()
    self.pGalleryRef:RequestListResize(#self.tbDataList)
end

function SelfGalleryHelper:RefreshItemByIndex(nIndex)
    local nUniqueID = self.tbItemUniqueIDs[nIndex]
    if nUniqueID ~= nil then
        local ListItem = self.tbItemList[nUniqueID]
        if ListItem ~= nil then
            ListItem:RefreshItem(nIndex, self.tbDataList[nIndex])
        end
    end
end

function SelfGalleryHelper:SelectItemByIndex(nIndex, bWithAnim)
    self.pGalleryRef:SelectItemByIndex(nIndex - 1, bWithAnim == true)
end

function SelfGalleryHelper:GetSelectedItemIndex()
    return self.nSelectedItemIndex
end

function SelfGalleryHelper:GetSelectedData()
    return self.tbDataList[self.nSelectedItemIndex]
end

return SelfGalleryHelper

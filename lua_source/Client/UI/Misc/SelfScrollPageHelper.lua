-----------------------------------------------------
--File Name    : SelfScrollPageHelper.lua
--Author       : Ran Jie
--Create Time  : 2017-03-28
--Description  : SelfScrollPageHelper
-----------------------------------------------------

local luaclass = require("luaclass")
local SelfScrollPageHelper = luaclass("SelfScrollPageHelper")

local CppDelegate = require("CppDelegate")
local UninitCheckSystem = require("UninitCheckSystem")
local LuaDelegate = require("LuaDelegate")

SelfScrollPageHelper.Owner        = nil       -- for get prefab
SelfScrollPageHelper.pListRef     = nil       -- for bind OnGenerateListItem event
SelfScrollPageHelper.delegate     = nil
SelfScrollPageHelper.tbDataList   = nil
SelfScrollPageHelper.tbItemList   = nil
SelfScrollPageHelper.nCurrentIndex = nil
SelfScrollPageHelper.HandleTouchStartedDelegate = nil
SelfScrollPageHelper.HandleTouchEndedDelegate = nil
SelfScrollPageHelper.OnScrollItemEndDelegate = nil
SelfScrollPageHelper.OnScrollClickedDelegate = nil

SelfScrollPageHelper.nBeginScrollOffset = nil

function SelfScrollPageHelper:Init( Owner, pListRef, tbDataList, nDefalutIndex )
    UninitCheckSystem:Register(self)
    if Owner == nil then
        logerror('[UI] SelfScrollPageHelper init faild, owner is nil')
        return
    end
    if pListRef == nil then
        logerror('[UI] SelfScrollPageHelper init faild, list refrence is nil')
        return
    end
    self.Owner = Owner
    self.pListRef = pListRef
    self.tbDataList = {}
    self.tbItemList = {}
    
    local nCount = pListRef:GetChildrenCount()
    for i = 1,nCount do
        local pContentWidget = pListRef:GetChildAt(i - 1)
        local tbContent = Owner.PrefabHelper:BindPrefab(pContentWidget)
        tbContent:Init(i)
        self.tbItemList[i] = tbContent
    end
    self.HandleTouchStartedDelegate = CppDelegate:BindMethod(self.pListRef.OnHandleTouchStarted, self, self.OnHandleTouchStarted)
    self.HandleTouchEndedDelegate = CppDelegate:BindMethod(self.pListRef.OnHandleTouchEnded, self, self.OnHandleTouchEnded)
    self.OnScrollItemEndDelegate = LuaDelegate()
    self.OnScrollClickedDelegate = LuaDelegate()
    if tbDataList then
        self:SetData(tbDataList)
    end
    if nDefalutIndex and nDefalutIndex <= nCount then
        self.nDefalutIndex = nDefalutIndex
    else
        self.nDefalutIndex = 1
    end
    self.pListRef:ScrollWidgetIntoView(self.tbItemList[self.nDefalutIndex].pWidgetRef, false, EDescendantScrollDestination.Center, 0)
end

function SelfScrollPageHelper:Uninit()
    UninitCheckSystem:Unregister(self)
    if self.HandleTouchStartedDelegate then
        self.HandleTouchStartedDelegate:Unbind()
        self.HandleTouchStartedDelegate = nil
    end
    if self.HandleTouchEndedDelegate then
        self.HandleTouchEndedDelegate:Unbind()
        self.HandleTouchEndedDelegate = nil
    end
    if self.ScrollItemEndDelegate then
        self.ScrollItemEndDelegate:Unbind()
        self.ScrollItemEndDelegate = nil
    end
end

function SelfScrollPageHelper:SetData( tbDataList )
    if not self.tbItemList or #self.tbItemList == 0 then
        return
    end
    self.tbDataList = tbDataList
    self.nCurrentIndex = 1
    for k, v in ipairs(tbDataList) do
        local tbContent = self.tbItemList[k]
        if tbContent then
            tbContent:RefreshItem(k, v)
        end
    end
    
end

function SelfScrollPageHelper:ScrollToIndex( nIndex )
    self.pListRef:ScrollWidgetIntoView(self.tbItemList[nIndex].pWidgetRef, false, EDescendantScrollDestination.Center, 0)
end

function SelfScrollPageHelper:OnHandleTouchStarted()
    self.nBeginScrollOffset = self.pListRef:GetScrollOffset()
    --logdebug("SelfScrollPageHelper:OnHandleTouchStarted",self.nBeginScrollOffset)
    return WidgetBlueprintLibrary.Unhandled() 
end

function SelfScrollPageHelper:OnHandleTouchEnded()
    --logdebug("SelfScrollPageHelper:OnHandleTouchEnded",self.nBeginScrollOffset)
    if not self.nBeginScrollOffset then
        return WidgetBlueprintLibrary.Unhandled()
    end
    local nScrollOffset = self.pListRef:GetScrollOffset()
    local nCurrentLuaIndex = self.nCurrentIndex
    local nNextLuaIndex = nCurrentLuaIndex
    local nDeltaOffset = nScrollOffset - self.nBeginScrollOffset
    --logdebug("SelfScrollPageHelper:OnHandleTouchEnded",nScrollOffset,self.nBeginScrollOffset,nCurrentLuaIndex,nDeltaOffset)
    if nDeltaOffset > 0 and math.abs(nDeltaOffset) > 50 then
        --left
        nNextLuaIndex = nCurrentLuaIndex + 1
    elseif nDeltaOffset < 0 and math.abs(nDeltaOffset) > 50 then
        --right
        nNextLuaIndex = nCurrentLuaIndex - 1
    end
    local tbNextItem = self.tbItemList[nNextLuaIndex]
    if tbNextItem then
        self.nCurrentIndex = nNextLuaIndex
        self.pListRef:ScrollWidgetIntoView(tbNextItem.pWidgetRef, true, EDescendantScrollDestination.Center, 0)
    end
    self.nBeginScrollOffset = nil
    if math.abs(nDeltaOffset) > 2 then
        self.OnScrollItemEndDelegate:Fire(nNextLuaIndex)
    else
        self.OnScrollClickedDelegate:Fire()
    end
    return WidgetBlueprintLibrary.Unhandled()
end

return SelfScrollPageHelper

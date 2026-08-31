-----------------------------------------------------
--File Name    : UIToastBoard.lua
--Author       : Song Fuhao
--Create Time  : 2016-06-18
--Description  : Toast面板
-----------------------------------------------------

local luaclass = require("luaclass")
local WndBase = require("WndBase")
local UIToastBoard = luaclass("UIToastBoard", WndBase)

local WidgetAnimationHandle = require("WidgetAnimationHandle")

local MAX_ITEM_TOAST_COUNT = 4
local ITEM_DISTANCE = -70
local FUNC_MAKE_VECTOR_2D = KismetMathLibrary.MakeVector2D

UIToastBoard.tbFreeItemList     = nil
UIToastBoard.tbUsedItemList     = nil
UIToastBoard.tbWaitMessageList  = nil
UIToastBoard.bCanvasMoved       = false
UIToastBoard.l10nCacheMessage   = nil

local function SetItemPosition(ToastItem, nIndex)
    ToastItem.pWidgetRef.Slot:SetPosition(FUNC_MAKE_VECTOR_2D(0, ITEM_DISTANCE * nIndex))
end

-- 添加新的获取道具Toast
local function HandleNextToast(self)
    local l10nMessage = self.tbWaitMessageList[1]
    local ToastItem = self.tbFreeItemList[1]
    if l10nMessage and ToastItem then
        table.remove(self.tbWaitMessageList, 1)
        table.remove(self.tbFreeItemList, 1)
        table.insert(self.tbUsedItemList, ToastItem)
        
        ToastItem.pWidgetRef:SetVisibility(ESlateVisibility.HitTestInvisible)
        SetItemPosition(ToastItem, 1)
        ToastItem:ShowToast(l10nMessage)
    end
end

local function RevertToastCanvasMoveUp(self)
    self.bCanvasMoved = false
    self:PlayAnimation("animToastMoveUp", 0.5, 1, EUMGSequencePlayMode.Reverse, 1)
    local nUsedItemCount = #self.tbUsedItemList
    for i,v in ipairs(self.tbUsedItemList) do
        SetItemPosition(v, nUsedItemCount + 1 - i)
    end
end

local function ToastCanvasMoveUp(self)
    if (not self.bCanvasMoved) and (#self.tbWaitMessageList > 0) then
        self.bCanvasMoved = true
        self:PlayAnimation("animToastMoveUp", 0, 1, EUMGSequencePlayMode.Forward, 1)
    
        if #self.tbUsedItemList == MAX_ITEM_TOAST_COUNT - 1 then
            self.tbUsedItemList[1]:HideToast()
        end
    end
end

local function OnAnimToastMoveUpFinished(self)
    if self.bCanvasMoved then
        HandleNextToast(self)
        RevertToastCanvasMoveUp(self)
    end
end

local function OnToastHideFinished(self, ToastItem)
    ToastItem.pWidgetRef:SetVisibility(ESlateVisibility.Collapsed)
    table.remove(self.tbUsedItemList, 1)
    table.insert(self.tbFreeItemList, ToastItem)
end

local function OnToastShowFinished(self, ToastItem)
    ToastCanvasMoveUp(self)
end

function UIToastBoard:OnLoad()
    self.tbFreeItemList = {}
    self.tbUsedItemList = {}

    for i = 1, MAX_ITEM_TOAST_COUNT do
        self.tbFreeItemList[i] = self.PrefabHelper:BindPrefab(self.pWidgetRef["pbToastItem0"..i])
    end
end

function UIToastBoard:OnBindEvent(Helper)
    for i,v in ipairs(self.tbFreeItemList) do
        Helper:RegisterLuaDelegate(v.tbOnShowFinished, function() OnToastShowFinished(self, v) end)
        Helper:RegisterLuaDelegate(v.tbOnHideFinished, function() OnToastHideFinished(self, v) end)
    end
    Helper:RegisterHandle(WidgetAnimationHandle:BindToAnimationFinished(self.pWidgetRef, self.pWidgetRef.animToastMoveUp, OnAnimToastMoveUpFinished, self))
end

function UIToastBoard:OnCreate()
    self.tbWaitMessageList = {}
end

function UIToastBoard:OnShow()
    if #self.tbWaitMessageList > #self.tbUsedItemList then
        HandleNextToast(self)
    end
end

function UIToastBoard:ShowToast(l10nMessage)
    table.insert(self.tbWaitMessageList, l10nMessage)
    if self.tbFreeItemList == nil then
        return
    end

    if #self.tbUsedItemList == 0 then
        HandleNextToast(self)
    else
        ToastCanvasMoveUp(self)
    end
end

return UIToastBoard

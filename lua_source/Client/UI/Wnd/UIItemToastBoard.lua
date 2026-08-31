-----------------------------------------------------
--File Name    : UIItemToastBoard.lua
--Author       : Chang Nan
--Create Time  : 2017-10-17
--Description  : Toast Item面板
-----------------------------------------------------

local luaclass = require("luaclass")
local WndBase = require("WndBase")
local UIItemToastBoard = luaclass("UIItemToastBoard", WndBase)

local MAX_ITEM_TOAST_COUNT = 3
local ITEM_DISTANCE = 130
local FUNC_MAKE_VECTOR_2D = KismetMathLibrary.MakeVector2D

UIItemToastBoard.tbFreeItemList     = nil
UIItemToastBoard.tbUsedItemList     = nil
UIItemToastBoard.tbWaitMessageList  = nil
UIItemToastBoard.bCanvasMoved       = false

-- 设置toast在canvas中的坐标
local function SetItemPosition(ToastItem, nIndex)
    ToastItem.pWidgetRef.Slot:SetPosition(FUNC_MAKE_VECTOR_2D(0, ITEM_DISTANCE * nIndex))
end

-- 添加新的获取道具Toast
local function HandleNextToast(self)
    local tbMessageInfo = self.tbWaitMessageList[1]
    if tbMessageInfo then
        table.remove(self.tbWaitMessageList, 1)
    
        local ToastItem = self.tbFreeItemList[1]
        table.remove(self.tbFreeItemList, 1)
        table.insert(self.tbUsedItemList, ToastItem)
    
        ToastItem.pWidgetRef:SetVisibility(ESlateVisibility.HitTestInvisible)
        SetItemPosition(ToastItem, #self.tbUsedItemList)
        ToastItem:ShowToast(tbMessageInfo[1], tbMessageInfo[2])
    end
end

-- 恢复GetItemToastsCanvas的坐标
local function RevertToastCanvasMoveUp(self)
    self.bCanvasMoved = false
    self:PlayAnimation("animToastMoveUp", 0.5, 1, EUMGSequencePlayMode.Reverse, 1)
    for i,v in ipairs(self.tbUsedItemList) do
        SetItemPosition(v, i)
    end
end

-- GetItemToast列表上移
local function ToastCanvasMoveUp(self)
    self.bCanvasMoved = true
    self:PlayAnimation("animToastMoveUp", 0, 1, EUMGSequencePlayMode.Forward, 1)
end

-- 监听GetItemToast移除事件
local function OnToastHideFinished(self, ToastItem)
    ToastItem.pWidgetRef:SetVisibility(ESlateVisibility.Collapsed)
    table.remove(self.tbUsedItemList, 1)
    table.insert(self.tbFreeItemList, ToastItem)

    if self.bCanvasMoved then
        RevertToastCanvasMoveUp(self)
        HandleNextToast(self)
    elseif #self.tbUsedItemList == 0 then
        HandleNextToast(self)
    end
end

-- 监听GetItemToast显示完成事件
local function OnToastShowFinished(self, ToastItem)
    if (#self.tbUsedItemList == MAX_ITEM_TOAST_COUNT) and (#self.tbWaitMessageList > 0) then 
        self.tbUsedItemList[1]:HideToast()
        ToastCanvasMoveUp(self)
    else
        HandleNextToast(self)
    end
end

function UIItemToastBoard:OnLoad()
    self.tbFreeItemList = {}
    self.tbUsedItemList = {}
    self.tbWaitMessageList = {}

    for i = 1, MAX_ITEM_TOAST_COUNT do
        self.tbFreeItemList[i] = self.PrefabHelper:BindPrefab(self.pWidgetRef["pbToastGetItem0"..i])
    end
end

function UIItemToastBoard:OnBindEvent(Helper)
    for i,v in ipairs(self.tbFreeItemList) do
        Helper:RegisterLuaDelegate(v.tbOnShowFinished, function() OnToastShowFinished(self, v) end)
        Helper:RegisterLuaDelegate(v.tbOnHideFinished, function() OnToastHideFinished(self, v) end)
    end
end

function UIItemToastBoard:ShowToast(tbItemType, nCount)
    table.insert(self.tbWaitMessageList, {tbItemType, nCount})
    if #self.tbUsedItemList == 0 then
        HandleNextToast(self)
    end
end

return UIItemToastBoard

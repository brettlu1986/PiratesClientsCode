-----------------------------------------------------
--File Name    : UPDialogFrame.lua
--Author       : Song Fuhao
--Create Time  : 2019-02-27
--Description  : 对话框框架逻辑
-----------------------------------------------------
local luaclass = require("luaclass")
local PrefabBase = require("PrefabBase")
local UPDialogFrame = luaclass("UPDialogFrame", PrefabBase)

local LuaDelegateClass = require("LuaDelegate")

UPDialogFrame.OnDisableClickedPositiveButton = nil
UPDialogFrame.OnDisableClickedNegativeButton = nil
UPDialogFrame.OnClickedPositiveButton = nil
UPDialogFrame.OnClickedNegativeButton = nil
UPDialogFrame.OnClickedCloseButton = nil
UPDialogFrame.OnDialogClosed = nil

local function OnDisableClickedBtnPositive(self)
    self.OnDisableClickedPositiveButton:Fire()
end

local function OnDisableClickedBtnNegative(self)
    self.OnDisableClickedNegativeButton:Fire()
end

local function OnClickedBtnPositive(self)
    self:HideDialog()
    self.OnClickedPositiveButton:Fire()
end

local function OnClickedBtnNegative(self)
    self:HideDialog()
    self.OnClickedNegativeButton:Fire()
end

local function OnClickedBtnClose(self)
    self:HideDialog()
    self.OnClickedCloseButton:Fire()
end

local function OnDialogHideFinished(self)
    self.OnDialogClosed:Fire()
end

function UPDialogFrame:OnCreate()
    self.OnDisableClickedPositiveButton = LuaDelegateClass()
    self.OnDisableClickedNegativeButton = LuaDelegateClass()
    self.OnClickedPositiveButton = LuaDelegateClass()
    self.OnClickedNegativeButton = LuaDelegateClass()
    self.OnClickedCloseButton = LuaDelegateClass()
    self.OnDialogClosed = LuaDelegateClass()
end

function UPDialogFrame:OnBindEvent(EventHelper)
    EventHelper:RegisterCppDelegate(self.pWidgetRef.btnPositive.OnDisableClicked, self, OnDisableClickedBtnPositive)
    EventHelper:RegisterCppDelegate(self.pWidgetRef.btnNegative.OnDisableClicked, self, OnDisableClickedBtnNegative)
    EventHelper:RegisterCppDelegate(self.pWidgetRef.btnPositive.OnClicked, self, OnClickedBtnPositive)
    EventHelper:RegisterCppDelegate(self.pWidgetRef.btnNegative.OnClicked, self, OnClickedBtnNegative)
    EventHelper:RegisterCppDelegate(self.pWidgetRef.btnClose.OnClicked, self, OnClickedBtnClose)
end

-- 设置对话框标题文本
function UPDialogFrame:SetTitle(l10nTitle)
    self.pWidgetRef.DialogTitle = l10nTitle
    self.pWidgetRef.txtTitle:SetText(l10nTitle)
end

-- 设置对话框消息文本
function UPDialogFrame:SetMessage(l10nMessage)
    self.pWidgetRef.MessageText = l10nMessage
    self.pWidgetRef.txtMessage:SetText(l10nMessage)
end

-- 设置对话框消息文本对齐方式
function UPDialogFrame:SetMessageJustification(pETextJustify)
    self.pWidgetRef.txtMessage:SetJustification(pETextJustify)
end

-- 设置对话框消息文本行高
function UPDialogFrame:SetMessageLineHeightPercentage(nLineHeightPercentage)
    self.pWidgetRef.txtMessage:SetLineHeightPercentage(nLineHeightPercentage)
end

-- 隐藏消息文本，设置对话框具体UI
function UPDialogFrame:SetView(pViewWidget)
    self.pWidgetRef.nsContent:SetContent(pViewWidget)
end

-- 获取对话框具体UI实例引用
function UPDialogFrame:GetView()
    return self.pWidgetRef.nsContent:GetChildAt(0)
end

-- 设置右侧按钮文字
function UPDialogFrame:SetPositiveText(l10nText)
    self.pWidgetRef.PositiveButtonText = l10nText
    self.pWidgetRef.txtPositive:SetText(l10nText)
end

-- 设置左侧按钮文字
function UPDialogFrame:SetNegativeText(l10nText)
    self.pWidgetRef.NegativeButtonText = l10nText
    self.pWidgetRef.txtNegative:SetText(l10nText)
end

-- 设置右侧按钮（积极的，带诱导性的）禁用时点击回调
function UPDialogFrame:SetPositiveButtonDisableCallback(fnCallback, tbEnv)
    self.OnDisableClickedPositiveButton:Bind(fnCallback, tbEnv)
end

-- 设置左侧按钮（消极的，不推荐的）禁用时点击回调
function UPDialogFrame:SetNegativeButtonDisableCallback(fnCallback, tbEnv)
    self.OnDisableClickedNegativeButton:Bind(fnCallback, tbEnv)
end

-- 设置右侧按钮（积极的，带诱导性的）点击回调
function UPDialogFrame:SetPositiveButtonCallback(fnCallback, tbEnv)
    self.OnClickedPositiveButton:Bind(fnCallback, tbEnv)
end

-- 设置左侧按钮（消极的，不推荐的）点击回调
function UPDialogFrame:SetNegativeButtonCallback(fnCallback, tbEnv)
    self.OnClickedNegativeButton:Bind(fnCallback, tbEnv)
end

-- 设置关闭按钮（右上角按钮）点击回调
function UPDialogFrame:SetCloseButtonCallback(fnCallback, tbEnv)
    self.OnClickedCloseButton:Bind(fnCallback, tbEnv)
end

-- 设置对话框关闭时回调（所有操作导致的关闭都会执行）
function UPDialogFrame:SetDialogClosedCallback(fnCallback, tbEnv)
    self.OnDialogClosed:Bind(fnCallback, tbEnv)
end

-- 设置背景显隐
function UPDialogFrame:SetBackgroudVisible(bVisible)
    self.pWidgetRef.BackgroudVisible = bVisible
    self.pWidgetRef.imgBg:SetVisibility(bVisible and ESlateVisibility.HitTestInvisible or ESlateVisibility.Collapsed)
end

-- 设置关闭按钮显隐
function UPDialogFrame:SetCloseButtonVisible(bVisible)
    self.pWidgetRef.CloseButtonVisible = bVisible
    self.pWidgetRef.btnClose:SetVisibility(bVisible and ESlateVisibility.Visible or ESlateVisibility.Collapsed)
end

-- 设置右侧按钮显隐
function UPDialogFrame:SetPositiveButtonVisible(bVisible)
    self.pWidgetRef.PositiveButtonVisible = bVisible
    self.pWidgetRef.btnPositive:SetVisibility(bVisible and ESlateVisibility.Visible or ESlateVisibility.Collapsed)
end

-- 设置左侧按钮显隐
function UPDialogFrame:SetNegativeButtonVisible(bVisible)
    self.pWidgetRef.NegativeButtonVisible = bVisible
    self.pWidgetRef.btnNegative:SetVisibility(bVisible and ESlateVisibility.Visible or ESlateVisibility.Collapsed)
end

-- 设置右侧按钮是否可用
function UPDialogFrame:SetPositiveButtonEnabled(bEnabled)
    self.pWidgetRef.btnPositive:SetIsEnabled(bEnabled)
end

-- 设置左侧按钮是否可用
function UPDialogFrame:SetNegativeButtonEnabled(bEnabled)
    self.pWidgetRef.btnNegative:SetIsEnabled(bEnabled)
end

-- 显示对话框
function UPDialogFrame:ShowDialog()
    self:PlayAnimation("animShow", 0, 1, EUMGSequencePlayMode.Forward, 1)
end

-- 隐藏对话框
function UPDialogFrame:HideDialog()
    self:PlayAnimation("animShow", 0, 1, EUMGSequencePlayMode.Reverse, 1, function()
        OnDialogHideFinished(self)
    end)
    -- 因为目前UI动画存在播放不全的问题，采用Timer辅助关闭
    self.TimerHelper:NewDelayRunTimerMethod(self, OnDialogHideFinished, self.pWidgetRef.animShow:GetEndTime())
end

return UPDialogFrame
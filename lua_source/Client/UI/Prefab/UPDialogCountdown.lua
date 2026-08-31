-----------------------------------------------------
--File Name    : UPDialogCountdown.lua
--Author       : ranjie
--Create Time  : 2019-09-05
--Description  : 按钮上带倒计时的对话框
-----------------------------------------------------
local luaclass = require("luaclass")
local PrefabBase = require("PrefabBase")
local UPDialogCountdown = luaclass("UPDialogCountdown", PrefabBase)

local LuaDelegateClass = require("LuaDelegate")

UPDialogCountdown.OnDisableClickedPositiveButton = nil
UPDialogCountdown.OnDisableClickedNegativeButton = nil
UPDialogCountdown.OnClickedPositiveButton = nil
UPDialogCountdown.OnClickedNegativeButton = nil
UPDialogCountdown.OnCountdownFinished = nil
UPDialogCountdown.Parent = nil

local function OnDisableClickedBtnPositive(self)
    self.OnDisableClickedPositiveButton:Fire()
end

local function OnDisableClickedBtnNegative(self)
    self.OnDisableClickedNegativeButton:Fire()
end

local function OnClickedBtnPositive(self)
    self.Parent:HideDialog()
    self.OnClickedPositiveButton:Fire()
end

local function OnClickedBtnNegative(self)
    self.Parent:HideDialog()
    self.OnClickedNegativeButton:Fire()
end

local function OnTextCountdownFinished(self)
    self.Parent:HideDialog()
    self.OnCountdownFinished:Fire()
end

function UPDialogCountdown:OnCreate()
    self.OnDisableClickedPositiveButton = LuaDelegateClass()
    self.OnDisableClickedNegativeButton = LuaDelegateClass()
    self.OnClickedPositiveButton = LuaDelegateClass()
    self.OnClickedNegativeButton = LuaDelegateClass()
    self.OnCountdownFinished = LuaDelegateClass()
end

function UPDialogCountdown:OnBindEvent(EventHelper)
    EventHelper:RegisterCppDelegate(self.pWidgetRef.btnPositive.OnDisableClicked, self, OnDisableClickedBtnPositive)
    EventHelper:RegisterCppDelegate(self.pWidgetRef.btnNegative.OnDisableClicked, self, OnDisableClickedBtnNegative)
    EventHelper:RegisterCppDelegate(self.pWidgetRef.btnPositive.OnClicked, self, OnClickedBtnPositive)
    EventHelper:RegisterCppDelegate(self.pWidgetRef.btnNegative.OnClicked, self, OnClickedBtnNegative)
    EventHelper:RegisterCppDelegate(self.pWidgetRef.txtPositive.OnCountDownFinished, self, OnTextCountdownFinished)
end

function UPDialogCountdown:SetParent(Parent)
    self.Parent = Parent
end

-- 设置对话框消息文本
function UPDialogCountdown:SetMessage(l10nMessage)
    self.pWidgetRef.txtMessage:SetText(l10nMessage)
end

-- 设置对话框消息文本对齐方式
function UPDialogCountdown:SetMessageJustification(pETextJustify)
    self.pWidgetRef.txtMessage:SetJustification(pETextJustify)
end

-- 设置对话框消息文本行高
function UPDialogCountdown:SetMessageLineHeightPercentage(nLineHeightPercentage)
    self.pWidgetRef.txtMessage:SetLineHeightPercentage(nLineHeightPercentage)
end

-- 设置右侧按钮文字
function UPDialogCountdown:SetPositiveText(l10nText)
    self.pWidgetRef.txtPositive:SetText(l10nText)
end

-- 设置左侧按钮文字
function UPDialogCountdown:SetNegativeText(l10nText)
    self.pWidgetRef.txtNegative:SetText(l10nText)
end

-- 设置右侧按钮（积极的，带诱导性的）禁用时点击回调
function UPDialogCountdown:SetPositiveButtonDisableCallback(fnCallback, tbEnv)
    self.OnDisableClickedPositiveButton:Bind(fnCallback, tbEnv)
end

-- 设置左侧按钮（消极的，不推荐的）禁用时点击回调
function UPDialogCountdown:SetNegativeButtonDisableCallback(fnCallback, tbEnv)
    self.OnDisableClickedNegativeButton:Bind(fnCallback, tbEnv)
end

-- 设置右侧按钮（积极的，带诱导性的）点击回调
function UPDialogCountdown:SetPositiveButtonCallback(fnCallback, tbEnv)
    self.OnClickedPositiveButton:Bind(fnCallback, tbEnv)
end

-- 设置左侧按钮（消极的，不推荐的）点击回调
function UPDialogCountdown:SetNegativeButtonCallback(fnCallback, tbEnv)
    self.OnClickedNegativeButton:Bind(fnCallback, tbEnv)
end

-- 设置右侧按钮显隐
function UPDialogCountdown:SetPositiveButtonVisible(bVisible)
    self.pWidgetRef.btnPositive:SetVisibility(bVisible and ESlateVisibility.Visible or ESlateVisibility.Collapsed)
end

-- 设置左侧按钮显隐
function UPDialogCountdown:SetNegativeButtonVisible(bVisible)
    self.pWidgetRef.btnNegative:SetVisibility(bVisible and ESlateVisibility.Visible or ESlateVisibility.Collapsed)
end

-- 设置右侧按钮是否可用
function UPDialogCountdown:SetPositiveButtonEnabled(bEnabled)
    self.pWidgetRef.btnPositive:SetIsEnabled(bEnabled)
end

-- 设置左侧按钮是否可用
function UPDialogCountdown:SetNegativeButtonEnabled(bEnabled)
    self.pWidgetRef.btnNegative:SetIsEnabled(bEnabled)
end

--设置倒计时的结束时间和显示文字
function UPDialogCountdown:SetPositiveButtonCountdownTime(l10nText, nEndTime)
    self.pWidgetRef.txtPositive:SetTimerStart(l10nText, false, nEndTime)
end

--设置倒计时结束的回调
function UPDialogCountdown:SetCountdownFinishedCallback(fnCallback, tbEnv)
    self.OnCountdownFinished:Bind(fnCallback, tbEnv)
end

return UPDialogCountdown
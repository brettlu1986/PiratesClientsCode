-----------------------------------------------------
--File Name    : UPDialogCommon.lua
--Author       : Chang Nan
--Create Time  : 2017-03-24
--Description  : 弹窗公用Prefab
-----------------------------------------------------

local luaclass = require ("luaclass")
local PrefabBase = require("PrefabBase")
local UPDialogCommon = luaclass("UPDialogCommon", PrefabBase)
local UIManager = require("UIManager")
local UISetUtils = require("UISetUtils")

local L10N_BTN_TEXT_CONFIRM = UISetUtils.GetL10NTextByKey("UPDIALOGCOMMON_L10N_BTN_TEXT_CONFIRM")
local L10N_BTN_TEXT_CANCEL = UISetUtils.GetL10NTextByKey("UPDIALOGCOMMON_L10N_BTN_TEXT_CANCEL")


UPDialogCommon.pAnimCommonPop = nil
UPDialogCommon.szBtnOKText = nil
UPDialogCommon.szBtnCancelText = nil
UPDialogCommon.funOK = nil
UPDialogCommon.funCancel = nil
UPDialogCommon.bAutoCallCancel = true
UPDialogCommon.bIsOpen = false
UPDialogCommon.szCurrentDialogType = nil    --挂接在通用弹窗预设上的窗口名称
UPDialogCommon.bBtnCancelFullScreen = true
--按下cancel是否关闭界面
UPDialogCommon.bCancelCloseUi = true
--动画播放完毕
UPDialogCommon.funPlayAnimEnd = nil


local OnAnimatePopFinished = function(self)
    if self.funPlayAnimEnd then
        self.funPlayAnimEnd()
    end
    if self.bIsOpen then
        return
    end
    if self.bAutoCallCancel then
        if self.funCancel then
            self.funCancel()
        end
    end
end

--播放打开动画
function UPDialogCommon:PlayEnterAnim()
    self.bIsOpen = true
    self:PlayAnimation("animCommonPop", 0, 1, EUMGSequencePlayMode.Forward, 1, function() OnAnimatePopFinished(self) end)
end

--播放隐藏动画
function UPDialogCommon:PlayHideAnim()
    if self.bIsOpen == true then
        self.bIsOpen = false
        self:PlayAnimation("animCommonPop", 0, 1, EUMGSequencePlayMode.Reverse, 1, function() OnAnimatePopFinished(self) end)
    end
end

function UPDialogCommon:OnShow()
end

function UPDialogCommon:OnLoad()
    self.bBtnCancelFullScreen = true
end

--确定按钮点击事件
local function OnClickBtnOK(self)
    self.funOK()
end

--取消按钮点击事件
local function OnClickBtnCancel(self)
    if self.bCancelCloseUi then
        self.PlayHideAnim(self)
    else
        if self.funCancel then
            self.funCancel()
        end
    end
end

--事件绑定
function UPDialogCommon:OnBindEvent()
    local Helper = self.EventHelper
    local pWidgetRef = self.pWidgetRef

    

    Helper:RegisterCppDelegateFunc(pWidgetRef.btnOK.OnClicked, function() OnClickBtnOK(self) end)
    Helper:RegisterCppDelegateFunc(pWidgetRef.btnCancel.OnClicked, function() OnClickBtnCancel(self) end)
    Helper:RegisterCppDelegateFunc(pWidgetRef.btnBack.OnClicked, function() OnClickBtnCancel(self) end)
    --Helper:RegisterHandle(WidgetAnimationHandle:BindToAnimationFinished(pWidgetRef, pWidgetRef.animCommonPop, OnAnimatePopFinished, self))
    Helper:RegisterCppDelegate(pWidgetRef.btnCancelFullScreen.OnClicked,  self,  self.OnBtnCancelFullScreen)
end

--设置标题文本
local function SetTitleText(self,szTitle)
    self.pWidgetRef.rtxtTitle:SetText(szTitle)
end

--设置公用按钮文本
local function SetButtonText(self, txtBtnOK, txtBtnCancel)
    self.szBtnOKText = txtBtnOK
    self.szBtnCancelText = txtBtnCancel
    if self.szBtnOKText ~= "" and self.szBtnOKText ~= nil then
        self.pWidgetRef.txtOK:SetText(self.szBtnOKText)
    else
        self.pWidgetRef.txtOK:SetText(L10N_BTN_TEXT_CONFIRM)
    end
    if self.szBtnCancelText ~= "" and self.szBtnCancelText ~= nil  then
        self.pWidgetRef.txtCancel:SetText(self.szBtnCancelText)
    else
        self.pWidgetRef.txtCancel:SetText(L10N_BTN_TEXT_CANCEL)
    end
end

--设置公用按钮点击事件
local function SetButtonClickDelegate(self, funOK, funCancel, bCancelCloseUi, funPlayAnimEnd)
    self.funOK = funOK or function() end
    self.funPlayAnimEnd = funPlayAnimEnd or function() end
    self.funCancel = function()
        if funCancel then
            funCancel()
        end
        if bCancelCloseUi == nil or bCancelCloseUi == true then
            UIManager:CloseWnd(self.szCurrentDialogType)
        end
    end
end

--设置弹窗的公用控件
function UPDialogCommon:SetDialogCommonData(szTitle,tbCommonBtnData)
    SetTitleText(self, szTitle)
    SetButtonText(self, tbCommonBtnData.szBtnOKText, tbCommonBtnData.szBtnCancelText)
    SetButtonClickDelegate(self, tbCommonBtnData.funOK, tbCommonBtnData.funCancel, tbCommonBtnData.bCancelCloseUi, tbCommonBtnData.funPlayAnimEnd)
    --self:SetBtnIsEnabled(false, false)
    if tbCommonBtnData.bCancelFullScreen == false then
        self.bBtnCancelFullScreen = false
    end
    if tbCommonBtnData.bCancelCloseUi~= nil and not tbCommonBtnData.bCancelCloseUi then
        self.bCancelCloseUi = false
    end
end

--设置按钮是否变灰
-- function UPDialogCommon:SetBtnIsEnabled(bEnabledOk, bEnabledCancel)
--     if bBtnOk ~= nil and bEnabledOk then
--         self.pWidgetRef.btnOK:SetIsEnabled(bBtnOk)
--     end
--     if bBtnCancel ~= nil and bEnabledCancel then
--         self.pWidgetRef.btnCancel:SetIsEnabled(bBtnCancel)
--     end
-- end

--隐藏弹窗公用按钮（确认和取消）
function UPDialogCommon:HideCommonButton()
    self.pWidgetRef.cvsButton:SetVisibility(ESlateVisibility.Hidden)
end

--隐藏左侧的按钮
function UPDialogCommon:HideLeftButton()
    self.pWidgetRef.sbxBack:SetVisibility(ESlateVisibility.Collapsed)
    self.pWidgetRef.btnBack:SetVisibility(ESlateVisibility.Collapsed)
end

--显示弹窗公用按钮
function UPDialogCommon:ShowCommonButton()
    self.pWidgetRef.cvsButton:SetVisibility(ESlateVisibility.Visible)
    self.pWidgetRef.sbxBack:SetVisibility(ESlateVisibility.Visible)
    self.pWidgetRef.btnBack:SetVisibility(ESlateVisibility.Visible)
    self.pWidgetRef.sbxBuy:SetVisibility(ESlateVisibility.Visible)
end

--响应对话框外 关闭按钮
function UPDialogCommon:OnBtnCancelFullScreen()
    if self.bBtnCancelFullScreen then
        OnClickBtnCancel(self)
    end
end

return UPDialogCommon

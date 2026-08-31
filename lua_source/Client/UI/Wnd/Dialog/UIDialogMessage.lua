-----------------------------------------------------
--File Name    : UIDialogMessage.lua
--Author       : Chang Nan
--Create Time  : 2017-03-24
--Description  : 信息弹窗
-----------------------------------------------------
local luaclass = require("luaclass")
local WndBase = require("WndBase")
local UIDef = require ("UIDef")
local UIDialogMessage = luaclass("UIDialogMessage", WndBase)

UIDialogMessage.UPDialogCommon = nil


local function BindTitleBarUp(self)
    local UPDialogCommon = self.PrefabHelper:BindPrefab(self.pWidgetRef.pbDialogCommon)
    self.UPDialogCommon = UPDialogCommon
    UPDialogCommon.szCurrentDialogType = UIDef.UI_DIALOG_MESSAGE
end

local function SetTipText(self, szTipText)
    local pWidgetRef = self.pWidgetRef
    if szTipText and szTipText ~= "" then
        pWidgetRef.rtxtTip:SetText(szTipText)
        pWidgetRef.rtxtTip:SetVisibility(ESlateVisibility.SelfHitTestInvisible)
    else
        pWidgetRef.rtxtTip:SetVisibility(ESlateVisibility.Collapsed)
    end
end

function UIDialogMessage:OnLoad()
    BindTitleBarUp(self)
end

function UIDialogMessage:OnShow()
    self.UPDialogCommon:PlayEnterAnim()
end

function UIDialogMessage:OnHide()
    if self.tbCloseArgs.bNoAnim then
        return true
    end

    if self.UPDialogCommon.pWidgetRef ~= nil then
        self.UPDialogCommon:PlayHideAnim()
    end
    return false
end

-- szTitle            标题文本
-- szMessage          信息文本
-- szTipText          提示文本
-- szBtnOkText        确认按钮文本
-- szBtnCancelText    取消按钮文本
-- funOK              确认按钮点击事件
-- bCancelFullScreen  是否可以通过点框外来关闭窗口, false表示不能关掉，默认值为可以关掉
-- funCancel          取消按钮的点击事件
-- bMiddle            信息文本是否居中，居中为true
-- bWithoutCancel     是否需要取消按钮，隐藏取消按钮则为true

function UIDialogMessage:ShowMessageDialog(szTitle, szMessage, szTipText, szBtnOkText, szBtnCancelText, funOK, funCancel, bCancelFullScreen, bMiddle, bWithoutCancel, bCancelCloseUi)
    local pWidgetRef = self.pWidgetRef
    local tbCommonBtnData = {}
    tbCommonBtnData.szBtnOKText = szBtnOkText
    tbCommonBtnData.szBtnCancelText = szBtnCancelText
    tbCommonBtnData.funOK = funOK
    tbCommonBtnData.funCancel = funCancel
    tbCommonBtnData.bCancelCloseUi = bCancelCloseUi
    tbCommonBtnData.bCancelFullScreen = bCancelFullScreen
    tbCommonBtnData.funPlayAnimEnd = function() 
        if not self.UPDialogCommon.bIsOpen then
            self:HideFinished() 
        end
    end
    self.UPDialogCommon:SetDialogCommonData(szTitle , tbCommonBtnData)
    SetTipText(self, szTipText)
    pWidgetRef.rtxtMessage:SetText(szMessage)

    if bMiddle == true then
        pWidgetRef.rtxtMessage:SetJustification(ETextJustify.Center)
    else
        pWidgetRef.rtxtMessage:SetJustification(ETextJustify.Left)
    end

    if bWithoutCancel == true then
        self.UPDialogCommon:HideLeftButton()
    else
        self.UPDialogCommon:ShowCommonButton()
    end
end


function UIDialogMessage:CloseDialog(tbParam)
    if tbParam and tbParam.bNoAnim then
        self:CloseSelf() 
        return 
    end

    if self.UPDialogCommon.pWidgetRef ~= nil then
        self.UPDialogCommon:PlayHideAnim()
    end
end


return UIDialogMessage

-----------------------------------------------------
--File Name    : UIDialogMessage.lua
--Author       : Chang Nan
--Create Time  : 2017-03-24
--Description  : 信息弹窗
-----------------------------------------------------
local luaclass = require("luaclass")
local PrefabBase = require("PrefabBase")
local UIDef = require ("UIDef")
local UPDialogMessage = luaclass("UPDisconnectDialog", PrefabBase)

UPDialogMessage.UPDialogCommon = nil


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

function UPDialogMessage:OnLoad()
    BindTitleBarUp(self)
end

function UPDialogMessage:OnShow()
    -- self.UPDialogCommon:PlayEnterAnim()
end

function UPDialogMessage:ShowMessageDialog(tbParam)
    log("UPDialogMessage:ShowMessageDialog")
    local pWidgetRef = self.pWidgetRef
    local tbCommonBtnData = {}
    tbCommonBtnData.szBtnOKText = tbParam.szBtnOkText
    tbCommonBtnData.szBtnCancelText = tbParam.szBtnCancelText
    tbCommonBtnData.funOK = tbParam.funOK
    tbCommonBtnData.funCancel = tbParam.funCancel
    self.UPDialogCommon:SetDialogCommonData(tbParam.szTitle , tbCommonBtnData)
    SetTipText(self, tbParam.szTipText)
    pWidgetRef.rtxtMessage:SetText(tbParam.szMessage)

    if tbParam.bShowCancel then
        self.UPDialogCommon:ShowCommonButton()
    else
        self.UPDialogCommon:HideLeftButton()
    end
    self.UPDialogCommon.pWidgetRef.btnBack:SetVisibility(ESlateVisibility_Collapsed)
    
    self.pWidgetRef:SetVisibility(ESlateVisibility_Visible)
end

function UPDialogMessage:HideMessageDialog()
    log("UPDialogMessage:HideMessageDialog")
    self.pWidgetRef:SetVisibility(ESlateVisibility_Collapsed)
end

return UPDialogMessage

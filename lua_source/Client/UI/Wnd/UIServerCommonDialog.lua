-----------------------------------------------------
--File Name    : UIProvocationCoundDown.lua
--Author       : Zuo Kun
--Create Time  : 2017-06-05
--Description  : 任务界面
-----------------------------------------------------
local luaclass = require("luaclass")
local WndBase = require("WndBase")
local UIServerCommonDialog = luaclass("UIServerCommonDialog", WndBase)

local UIDef = require ("UIDef")
local UIManager = require("UIManager")
-- local GamePlayerSelfHelper = require("GamePlayerSelfHelper")
local Proto = require("ClientProtoNames")
local NetworkManager = dynamic_require("NetworkManager")
local UITextDef = require("UITextDef")
local UISetUtils = require("UISetUtils")
local WidgetAnimationHandle = require("WidgetAnimationHandle")
local GlobalVariableSystem = dynamic_require("GlobalVariableSystem")

local L10N_OK = UISetUtils.GetL10NTextByKey("UISERVERCOMMONDIALOG_L10N_OK")
local L10N_Cancel = UISetUtils.GetL10NTextByKey("UISERVERCOMMONDIALOG_L10N_CANCEL")

UIServerCommonDialog.UPDialogCommon = nil
-- UIServerCommonDialog.CancelMatchmaking = nil
-- UIServerCommonDialog.bIsLeader = false
UIServerCommonDialog.bIsClose = false

UIServerCommonDialog.nType = Proto.s2c_ShowMessageBox_Type.SERVER
UIServerCommonDialog.nButtonType = Proto.s2c_ShowMessageBox_Buttons.OK_CANCEL
UIServerCommonDialog.nID = 0

local function BindPrefabs(self)
    self.UPDialogCommon = self.PrefabHelper:BindPrefab(self.pWidgetRef.pbDialogCommon)
    self.UPDialogCommon.szCurrentDialogType = UIDef.UI_COUNT_DOWN
end


function UIServerCommonDialog:OnLoad()
    --logdebug("!!!!!!!!!!!!!UIServerCommonDialog:OnLoad()", self.pWidgetRef, KismetSystemLibrary.GetDisplayName(self.pWidgetRef))
    BindPrefabs(self)
    -- self.CancelMatchmaking = LuaDelegateClass()
end

function UIServerCommonDialog:OnShow()
    self.UPDialogCommon:PlayEnterAnim()
    -- local TeamComponent = GamePlayerSelfHelper:Get().TeamComponent
    -- if TeamComponent:IsLeader() then
    --     self.bIsLeader = true
    -- end

    self:ShowCountDownDialog()
    -- if not self.bIsLeader then
    --     self.pWidgetRef.btnContent:SetVisibility(ESlateVisibility.Hidden)
    -- end
    self.UPDialogCommon.bBtnCancelFullScreen = false
end

function UIServerCommonDialog:ShowCountDownDialog()
    local pWidgetRef = self.pWidgetRef
    local tbCommonBtnData = {}
    tbCommonBtnData.szBtnOKText = ""
    tbCommonBtnData.szBtnCancelText = ""
    tbCommonBtnData.bCancelFullScreen = false

    local tbOpenArgs = self.tbOpenArgs
    self.nID = tbOpenArgs.nID
    self.nType = tbOpenArgs.nType
    self.nButtonType = tbOpenArgs.nButtonType
    local nButtonType = tbOpenArgs.nButtonType
    if nButtonType == Proto.s2c_ShowMessageBox_Buttons.NO_BUTTON then
        self.UPDialogCommon:HideCommonButton()
    elseif nButtonType == Proto.s2c_ShowMessageBox_Buttons.OK then
        self.UPDialogCommon:HideLeftButton()
    elseif nButtonType == Proto.s2c_ShowMessageBox_Buttons.CANCEL then
        self.UPDialogCommon:HideLeftButton()
        tbCommonBtnData.szBtnOKText = UITextDef.L10N_Cancel
    end

    local nCountDownType = tbOpenArgs.nCountDownType
    local nCountDown = tbOpenArgs.nCountDown
    local szTitle = tbOpenArgs.szTitle
    local l10nMessage = tbOpenArgs.szText

    if nCountDownType == Proto.s2c_ShowMessageBox_Countdown.NO_COUNTDOWN then
        pWidgetRef.kcdCountDown:SetVisibility(ESlateVisibility.Hidden)
        pWidgetRef.txtMessage:SetText(l10nMessage)
        self.UPDialogCommon:SetDialogCommonData(szTitle , tbCommonBtnData)
    -- elseif nCountDownType == Proto.s2c_ShowMessageBox_Countdown.NO_COUNTDOWN then
    elseif nCountDownType == Proto.s2c_ShowMessageBox_Countdown.TEXT then
        pWidgetRef.txtMessage:SetVisibility(ESlateVisibility.Hidden)
        l10nMessage = l10nMessage .. "({0})"
        self.UPDialogCommon:SetDialogCommonData(szTitle , tbCommonBtnData)
        pWidgetRef.kcdCountDown:SetTimerStart(l10nMessage,false, GlobalVariableSystem:GetLocalTime() + nCountDown)
    elseif nCountDownType == Proto.s2c_ShowMessageBox_Countdown.OK_BUTTON then
        self.UPDialogCommon:SetDialogCommonData(szTitle , tbCommonBtnData)
        pWidgetRef.kcdCountDown:SetVisibility(ESlateVisibility.Hidden)
        pWidgetRef.txtMessage:SetText(l10nMessage)

        pWidgetRef.txtOkCountDown:SetVisibility(ESlateVisibility.HitTestInvisible)
        pWidgetRef.txtOkCountDown:SetTimerStart(L10N_OK,false, GlobalVariableSystem:GetLocalTime() + nCountDown)
        self.UPDialogCommon.pWidgetRef.txtOK:SetText("")
    elseif nCountDownType == Proto.s2c_ShowMessageBox_Countdown.CANCEL_BUTTON then
        self.UPDialogCommon:SetDialogCommonData(szTitle , tbCommonBtnData)
        pWidgetRef.kcdCountDown:SetVisibility(ESlateVisibility.Hidden)
        pWidgetRef.txtMessage:SetText(l10nMessage)
        pWidgetRef.txtCancelCountDown:SetVisibility(ESlateVisibility.HitTestInvisible)
        pWidgetRef.txtCancelCountDown:SetTimerStart(L10N_Cancel,false, GlobalVariableSystem:GetLocalTime() + nCountDown)
        self.UPDialogCommon.pWidgetRef.txtCancel:SetText("")
    end

end

function UIServerCommonDialog:CloseDialog()
    if not self.bIsClose then
        self.bIsClose = true
        -- self:PlayHideAnim()
        self.UPDialogCommon:PlayHideAnim()
    end
end

function UIServerCommonDialog:OnBtnCancelFullScreen()
--[[     if not self.bIsLeader then
	    self:CloseDialog()
    end  ]]
    if not self.bIsClose and self.nType == Proto.s2c_ShowMessageBox_Type.CLIENT then
        self:CloseDialog()
    end
	-- return WidgetBlueprintLibrary.Handled()
end

function UIServerCommonDialog:OnMatchMakingSuccess()
    self:CloseDialog()
end

function UIServerCommonDialog:OnClickBtnOK()
    if not self.bIsClose then
        self:CloseDialog()
        -- self.CancelMatchmaking:Fire()
        if self.nType == Proto.s2c_ShowMessageBox_Type.SERVER then
            NetworkManager:GetHubServerProxy():SendPacket(Proto.c2s_ClickMessageBox)
        end
    end
end

function UIServerCommonDialog:OnClickBtnCancel()
    if not self.bIsClose then
        self:CloseDialog()
        -- self.CancelMatchmaking:Fire()
        -- if self.nType == Proto.s2c_ShowMessageBox_Type.SERVER then
        --     NetworkManager:GetHubServerProxy():SendPacket(Proto.c2s_FactionAttackPlayer, {player_id = FoundObject.nPlayerId})
        -- end
    end
end

function UIServerCommonDialog:OnAnimatePopFinished()
    if self.bIsClose  then
        UIManager:CloseWnd(UIDef.UI_SERVER_COMMON_DIALOG)
    end
end

function UIServerCommonDialog:OnBindEvent(Helper)

    --Helper:RegisterEvent(ClientEventDef.EV_MATCH_MAING_CANCELLED,self,self.OnMatchMakingCancelled)
    -- Helper:RegisterCppDelegate(self.pWidgetRef.btnCancelMatch.OnClicked, self, self.OnCancelMatchClick)
    -- Helper:RegisterCppDelegate(self.pWidgetRef.bdrClose.OnMouseButtonDownEvent, self, self.OnMouseButtonDown)
    Helper:RegisterCppDelegate(self.pWidgetRef.kcdCountDown.OnCountDownFinished, self, self.OnMatchMakingSuccess)
    Helper:RegisterCppDelegate(self.pWidgetRef.txtCancelCountDown.OnCountDownFinished, self, self.OnMatchMakingSuccess)
    Helper:RegisterCppDelegate(self.pWidgetRef.txtOkCountDown.OnCountDownFinished, self, self.OnMatchMakingSuccess)
    -- Helper:RegisterEvent(ClientEventDef.EV_MATCH_MAKING_SUCCESS,self,self.OnMatchMakingSuccess)
    local dialogCommonWidget = self.UPDialogCommon.pWidgetRef
    Helper:RegisterHandle(WidgetAnimationHandle:BindToAnimationFinished(dialogCommonWidget, dialogCommonWidget.animCommonPop, self.OnAnimatePopFinished, self))
    Helper:RegisterCppDelegate(dialogCommonWidget.btnCancelFullScreen.OnClicked,  self,  self.OnBtnCancelFullScreen)
    Helper:RegisterCppDelegate(dialogCommonWidget.btnOK.OnClicked,  self,  self.OnClickBtnOK)
    Helper:RegisterCppDelegate(dialogCommonWidget.btnCancel.OnClicked,  self,  self.OnClickBtnCancel)
end


return UIServerCommonDialog

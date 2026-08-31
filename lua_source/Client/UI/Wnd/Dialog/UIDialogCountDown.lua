-----------------------------------------------------
--File Name    : UIDialogCountDown.lua
--Author       : Chang Nan
--Create Time  : 2017-08-31
--Description  : 匹配计时窗口
-----------------------------------------------------
local luaclass = require("luaclass")
local WndBase = require("WndBase")
local UIDialogCountDown = luaclass("UIDialogCountDown", WndBase)

local LuaDelegateClass = require("LuaDelegate")
local ClientEventDef = require("ClientEventDef")
local UIDef = require ("UIDef")
-- local UIDialogHelper = require("UIDialogHelper")

UIDialogCountDown.UPDialogCommon = nil
UIDialogCountDown.CancelMatchmaking = nil

local function BindTitleBarUp(self)
    self.UPDialogCommon = self.PrefabHelper:BindPrefab(self.pWidgetRef.pbDialogCommon)
    self.UPDialogCommon.szCurrentDialogType = UIDef.UI_COUNT_DOWN
end

function UIDialogCountDown:OnLoad()
    --logdebug("!!!!!!!!!!!!!UIDialogCountDown:OnLoad()", self.pWidgetRef, KismetSystemLibrary.GetDisplayName(self.pWidgetRef))
    BindTitleBarUp(self)
    self.CancelMatchmaking = LuaDelegateClass()
end

function UIDialogCountDown:OnShow()
    self.UPDialogCommon:PlayEnterAnim()
end




function UIDialogCountDown:ShowCountDownDialog(szTitle, l10nMessage)
    local pWidgetRef = self.pWidgetRef
    local tbCommonBtnData = {}
    tbCommonBtnData.szBtnOKText = ""
    tbCommonBtnData.szBtnCancelText = ""
    tbCommonBtnData.bCancelFullScreen = false
    tbCommonBtnData.funCancel = function()
        self:OnCancelMatchClick()
    end
    self.UPDialogCommon:SetDialogCommonData(szTitle , tbCommonBtnData)
    self.UPDialogCommon:HideCommonButton()
    pWidgetRef.kcdCountDown:SetTimerStart(l10nMessage,true, 0)

end


function UIDialogCountDown:CloseDialog()
    if self.UPDialogCommon.pWidgetRef ~= nil then
        self.UPDialogCommon:PlayHideAnim()
    end
end

function UIDialogCountDown:OnMatchMakingSuccess()
    self:CloseSelf()
    -- UIDialogHelper:CloseDialog(UIDef.UI_COUNT_DOWN)
end

function UIDialogCountDown:OnCancelMatchClick()
    self:CloseSelf()
    -- UIDialogHelper:CloseDialog(UIDef.UI_COUNT_DOWN)
    self.CancelMatchmaking:Fire()
end

function UIDialogCountDown:OnBindEvent(Helper)

    --Helper:RegisterEvent(ClientEventDef.EV_MATCH_MAING_CANCELLED,self,self.OnMatchMakingCancelled)
    Helper:RegisterCppDelegate(self.pWidgetRef.btnCancelMatch.OnClicked, self, self.OnCancelMatchClick)
    Helper:RegisterEvent(ClientEventDef.EV_MATCH_MAKING_SUCCESS,self,self.OnMatchMakingSuccess)
end






return UIDialogCountDown

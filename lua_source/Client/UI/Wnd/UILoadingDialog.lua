-----------------------------------------------------
--File Name    : UILoadingDialog.lua
--Author       : Song Fuhao
--Create Time  : 2016-12-17
--Description  : 对话框面板
-----------------------------------------------------

local luaclass = require ("luaclass")
local WndBase = require("WndBase")
local UILoadingDialog = luaclass("UILoadingDialog", WndBase)

local UISetUtils = require("UISetUtils")
local WidgetAnimationHandle = require("WidgetAnimationHandle")

UILoadingDialog.bHideAim = false

-- public function
function UILoadingDialog:OnShow()
    local l10nMessage = self.tbOpenArgs.l10nMessage
    if not l10nMessage then
        l10nMessage = UISetUtils.GetL10NTextByKey("LOADING_DIALOG_COMMON_MESSAGE")
    end
    self.pWidgetRef.txtMessage:SetText(l10nMessage)
    self.bHideAim = false
    self:PlayAnimation("ShowAnim", 0, 1, EUMGSequencePlayMode.Forward, 1)
end

function UILoadingDialog:OnHide()
    self.bHideAim = true
    self:PlayAnimation("ShowAnim", 0, 1, EUMGSequencePlayMode.Reverse, 1)
    return false
end

function UILoadingDialog:OnBindEvent()
    local OnAnimationFinishedEvent = function()
        if self.bHideAim then
            self:HideFinished()
        end
    end
    self.EventHelper:RegisterHandle(WidgetAnimationHandle:BindToAnimationFinished(self.pWidgetRef, self.pWidgetRef.ShowAnim, OnAnimationFinishedEvent))
end

return UILoadingDialog

local luaclass       = require("luaclass")
local WndBase        = require("WndBase")
local UIWaitConnectDialog = luaclass("UIWaitConnectDialog", WndBase)
local UIManager      = require("UIManager")
local UIDef          = require("UIDef")
local UIResourceDef  = require("UIResourceDef")
local UISetUtils     = require("UISetUtils")

local function PlayAnimation(self)
    self:PlayAnimation("animGO", 0, 0, EUMGSequencePlayMode.Forward, 1)
end

local function SetBackGroupColor(self, pColor)
    UISetUtils.SetBorderBrushTint(self.pWidgetRef.pBackGround, pColor)
end

function UIWaitConnectDialog:OnShow()
    log("UIWaitConnectDialog:OnShow", self.tbOpenArgs.bRetraveling)
    if self.tbOpenArgs.bRetraveling then
        SetBackGroupColor(self, UIResourceDef.COLOR.BLACK.SLATE_COLOR)
    else
        SetBackGroupColor(self, UIResourceDef.COLOR.BLACK.SLATE_COLOR_TRANSPARENT)
    end
    PlayAnimation(self)
end

function UIWaitConnectDialog:CloseDialog()
    UIManager:CloseWnd(UIDef.UI_WAIT_CONNECT_DIALOG)
end

-- retravel时,该界面代替uiloading界面
function UIWaitConnectDialog:AddPercent(nPercent)
end
function UIWaitConnectDialog:TryCloseWnd()
    log("UIWaitConnectDialog:TryCloseWnd")
    self:CloseSelf()
end

function UIWaitConnectDialog:Reload(tbParam)
    log("UIWaitConnectDialog:Reload")
    if tbParam and tbParam.bRetraveling then
        SetBackGroupColor(self, UIResourceDef.COLOR.BLACK.SLATE_COLOR)
    else
        SetBackGroupColor(self, UIResourceDef.COLOR.BLACK.SLATE_COLOR_TRANSPARENT)
    end
    PlayAnimation(self)
end

function UIWaitConnectDialog:ShowDialogMessage(tbParam)
    log("UIWaitConnectDialog:ShowDialogMessage")
end

return UIWaitConnectDialog
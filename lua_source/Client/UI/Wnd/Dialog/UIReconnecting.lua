local luaclass       = require("luaclass")
local WndBase        = require("WndBase")
local UIReconnecting = luaclass("UIReconnecting", WndBase)
local UIManager      = require("UIManager")
local UIDef          = require("UIDef")
local UIResourceDef  = require("UIResourceDef")
local UISetUtils     = require("UISetUtils")

function UIReconnecting:ShowReconnectingDialog( )

    self:PlayAnimation("animGO", 0, 0, EUMGSequencePlayMode.Forward, 1)
end

local function SetBackGroupColor(self, pColor)
    UISetUtils.SetBorderBrushTint(self.pWidgetRef.pBackGround, pColor)
end

function UIReconnecting:OnShow()
    log("UIReconnecting:OnShow", self.tbOpenArgs.bRetraveling)
    if self.tbOpenArgs.bRetraveling then
        SetBackGroupColor(self, UIResourceDef.COLOR.BLACK.SLATE_COLOR)
    else
        SetBackGroupColor(self, UIResourceDef.COLOR.BLACK.SLATE_COLOR_TRANSPARENT)
    end
    self:ShowReconnectingDialog()
end

function UIReconnecting:CloseDialog()
    UIManager:CloseWnd(UIDef.UI_RECONNECTING)
end

-- retravel时,该界面代替uiloading界面
function UIReconnecting:AddPercent(nPercent)
end
function UIReconnecting:TryCloseWnd()
    log("UIReconnecting:TryCloseWnd")
    self:CloseSelf()
end

function UIReconnecting:Reload(tbParam)
    log("UIReconnecting:Reload")
    if tbParam and tbParam.bRetraveling then
        SetBackGroupColor(self, UIResourceDef.COLOR.BLACK.SLATE_COLOR)
    else
        SetBackGroupColor(self, UIResourceDef.COLOR.BLACK.SLATE_COLOR_TRANSPARENT)
    end
    self:ShowReconnectingDialog()
end

function UIReconnecting:ShowDialogMessage(tbParam)
    log("UIReconnecting:ShowDialogMessage")
end

return UIReconnecting
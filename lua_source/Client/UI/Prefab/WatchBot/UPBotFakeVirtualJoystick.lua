
local luaclass = require ("luaclass")
local PrefabBase = require("PrefabBase")
local UPBotFakeVirtualJoystick = luaclass("UPBotFakeVirtualJoystick", PrefabBase)

local UISetUtils = require("UISetUtils")
local UIResourceDef = require("UIResourceDef")
local ControlModeSystem = require("ControlModeSystem")
local ControlModeDef = require("ControlModeDef")

function UPBotFakeVirtualJoystick:OnShow()
    local pWidgetRef = self.pWidgetRef
    local pIconRes = UIResourceDef.FFA_VIRTUALSTICK_HUMAN_RUN:load()
    if pIconRes then
        UISetUtils.SetImageBrushRes(pWidgetRef.imgContinuous, pIconRes)
    end
    pIconRes = UIResourceDef.FFA_VIRTUALSTICK_HUMAN_CHECK:load()
    if pIconRes then
        UISetUtils.SetCheckBoxCheckedBrushRes(pWidgetRef.chkContinuous, pIconRes)
    end
    pIconRes = UIResourceDef.FFA_VIRTUALSTICK_HUMAN_UNCHECK:load()
    if pIconRes then
        UISetUtils.SetCheckBoxUncheckedBrushRes(pWidgetRef.chkContinuous, pIconRes)
    end
    pWidgetRef.chkContinuous:SetVisibility(ESlateVisibility.SelfHitTestInvisible)
    if ControlModeSystem:GetCurrentModeType() == ControlModeDef.HUMAN then
        pWidgetRef.chkSprintImmediately:SetCheckedState(ECheckBoxState.Unchecked)
        pWidgetRef.chkSprintImmediately:SetVisibility(ESlateVisibility.Visible)
    else
        pWidgetRef.chkSprintImmediately:SetVisibility(ESlateVisibility.Collapsed)
    end
end

function UPBotFakeVirtualJoystick:SetVirtualJoystickIcon(szIconRes)
    local IconResObj = szIconRes:load()
    UISetUtils.SetImageBrushRes(self.pWidgetRef.imgThumb, IconResObj)
end

function UPBotFakeVirtualJoystick:SetContinuousEnable(bEnable)
    self.bContinuousEnable = bEnable
    if not bEnable then
        self.pWidgetRef.bdrContinuous:SetVisibility(ESlateVisibility.Hidden)
        self.pWidgetRef.bdrLock:SetVisibility(ESlateVisibility.Collapsed)
    end
    self.pWidgetRef.cvsContinuous:SetVisibility(ESlateVisibility.Collapsed)
end

return UPBotFakeVirtualJoystick

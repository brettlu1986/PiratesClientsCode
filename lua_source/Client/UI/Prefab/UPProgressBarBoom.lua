local luaclass = require("luaclass")
local PrefabBase = require("PrefabBase")
local UPProgressBarBoom = luaclass("UPProgressBarBoom", PrefabBase)

local TIMEFORMAT = {""}
local TEXT_REFRESH_INTERVAL = 1

UPProgressBarBoom.fnFinishCallback = nil

local function OnCpgbCountDownAnimationFinished(self)
    if self.fnFinishCallback then
        self.fnFinishCallback()
    end
end

function UPProgressBarBoom:OnBindEvent(EventHelper)
    EventHelper:RegisterCppDelegate(self.pWidgetRef.cpgbCountDown.OnAnimationFinished, self, OnCpgbCountDownAnimationFinished)
end

function UPProgressBarBoom:StartProgress(nDuration)
    self.pWidgetRef.cpgbCountDown:StartAnimation(0, 1, nDuration)
    self.pWidgetRef.txtCoutDown:StartTimer(nDuration , TEXT_REFRESH_INTERVAL, TIMEFORMAT, EMinTimeUnit.Second)
    self:SetVisible(true)
end

function UPProgressBarBoom:StopProgress()
    self.pWidgetRef.cpgbCountDown:StopAnimation()
    self.pWidgetRef.txtCoutDown:StopTimer()
    self:SetVisible(false)
end

function UPProgressBarBoom:SetVisible(bVisible)
    if bVisible then
        self.pWidgetRef:SetVisibility(ESlateVisibility.HitTestInvisible)
    else
        self.pWidgetRef:SetVisibility(ESlateVisibility.Collapsed)
    end
end

function UPProgressBarBoom:SetFinishCallback(fnFinishCallback)
    self.fnFinishCallback = fnFinishCallback
end

return UPProgressBarBoom
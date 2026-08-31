local luaclass = require("luaclass")
local PrefabBase = require("PrefabBase")
local UPAttackWarningItem = luaclass("UPAttackWarningItem", PrefabBase)

local LuaDelegate = require("LuaDelegate")
local WidgetAnimationHandle = require("WidgetAnimationHandle")

UPAttackWarningItem.OnWarningFinished = nil

local function OnAnimShowFinished(self)
    self.OnWarningFinished:Fire(self)
end

function UPAttackWarningItem:OnLoad()
    self.OnWarningFinished = LuaDelegate()
end

function UPAttackWarningItem:OnBindEvent(EventHelper)
    EventHelper:RegisterHandle(WidgetAnimationHandle:BindToAnimationFinished(self.pWidgetRef, self.pWidgetRef.animShow, OnAnimShowFinished, self))
end

function UPAttackWarningItem:ShowWarning(nAngle)
    local pWidgetRef = self.pWidgetRef
    pWidgetRef:SetRenderTransformAngle(nAngle)
    pWidgetRef:PlayAnimation(pWidgetRef.animShow, 0, 1, EUMGSequencePlayMode.Forward, 1)
end

function UPAttackWarningItem:InterruptWarning()
    local pWidgetRef = self.pWidgetRef
    pWidgetRef:StopAnimation(pWidgetRef.animShow)
end

return UPAttackWarningItem
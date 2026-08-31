-----------------------------------------------------
--File Name    : AbilityEvent_Dying.lua
--Author       : Song Fuhao
--Create Time  : 2020-06-30
--Description  : 重伤时触发
-----------------------------------------------------
local luaclass = require("luaclass")
local AbilityEventBase = require("AbilityEventBase")
local AbilityEvent_Dying = luaclass("AbilityEvent_Dying", AbilityEventBase)

AbilityEvent_Dying.bTriggered = false

local function OnIsDyingChanged(self, bIsDying)
    if bIsDying then
        self.bTriggered = true
        self:TriggerDo()
    elseif self.bTriggered then
        self.bTriggered = false
        self:TriggerUndo()
    end
end

function AbilityEvent_Dying:OnActivate()
    self.OwnerPawn.HumanBattlePropertyComponent.OnIsDyingChanged:Bind(OnIsDyingChanged, self)
    self.OwnerPawn.ShipBattlePropertyComponent.OnIsDyingChanged:Bind(OnIsDyingChanged, self)
    OnIsDyingChanged(self, self.OwnerPawn:IsDying())
end

function AbilityEvent_Dying:OnDeactivate()
    self.OwnerPawn.HumanBattlePropertyComponent.OnIsDyingChanged:Unbind(OnIsDyingChanged, self)
    self.OwnerPawn.ShipBattlePropertyComponent.OnIsDyingChanged:Unbind(OnIsDyingChanged, self)
    OnIsDyingChanged(self, false)
end

return AbilityEvent_Dying
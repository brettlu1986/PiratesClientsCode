-----------------------------------------------------
--File Name    : AbilityEventBase.lua
--Author       : Song Fuhao
--Create Time  : 2018-02-22
--Description  : AbilityEvent基类
-----------------------------------------------------
local luaclass = require("luaclass")
local AbilityEventBase = luaclass("AbilityEventBase")

AbilityEventBase.Owner = nil
AbilityEventBase.OwnerPawn = nil
AbilityEventBase.tbParams = nil
AbilityEventBase.fnTriggerDo = nil
AbilityEventBase.fnTriggerUndo = nil
AbilityEventBase.fnTriggerPostDo = nil
AbilityEventBase.bUndo = false
AbilityEventBase.bActivate = false
AbilityEventBase.bRepeatActivate = false

function AbilityEventBase:Create(Owner, OwnerPawn, tbParams, fnTriggerDo, fnTriggerUndo, fnTriggerPostDo)
    self.Owner = Owner
    self.OwnerPawn = OwnerPawn
    self.tbParams = tbParams
    self.fnTriggerDo = fnTriggerDo
    self.fnTriggerUndo = fnTriggerUndo
    self.fnTriggerPostDo = fnTriggerPostDo

    if tbParams.bUndo then
        self.bUndo = tbParams.Undo ~= 0
    end

    self:OnCreate(Owner, tbParams)
end

function AbilityEventBase:Destroy()
    self:OnDestroy()
    self.tbParams = nil
    self.OwnerPawn = nil
    self.Owner = nil
end

function AbilityEventBase:Activate()
    if self.bRepeatActivate or (not self.bActivate) then
        self.bActivate = true
        self:OnActivate()
    end
end

function AbilityEventBase:Deactivate()
    if self.bActivate then
        self:OnDeactivate()
        self.bActivate = false
    end
end

function AbilityEventBase:TriggerDo(tbParams)
    if self.fnTriggerDo and self.fnTriggerDo(self.Owner, tbParams) then
        self:OnTriggerDoSuccess()
        if self.fnTriggerPostDo then
            self.fnTriggerPostDo(self.Owner, tbParams)
        end
    end
end

function AbilityEventBase:TriggerUndo(tbParams)
    if self.fnTriggerUndo and self.fnTriggerUndo(self.Owner, tbParams) then
        self:OnTriggerUndoSuccess()
    end
end

function AbilityEventBase:OnCreate(Owner, tbParams)
end

function AbilityEventBase:OnDestroy()
end

function AbilityEventBase:OnActivate()
end

function AbilityEventBase:OnDeactivate()
end

function AbilityEventBase:OnTriggerDoSuccess()
end

function AbilityEventBase:OnTriggerUndoSuccess()
end

return AbilityEventBase

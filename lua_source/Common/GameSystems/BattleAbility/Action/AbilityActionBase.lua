-----------------------------------------------------
--File Name    : AbilityActionBase.lua
--Author       : Song Fuhao
--Create Time  : 2017-09-23
--Description  : AbilityAction基类
-----------------------------------------------------
local luaclass = require("luaclass")
local AbilityActionBase = luaclass("AbilityActionBase")

AbilityActionBase.Owner = nil -- Buff实例或Skill实例
AbilityActionBase.OwnerPawn = nil
AbilityActionBase.tbInstigator = nil
AbilityActionBase.tbInitParams = nil
AbilityActionBase.nExcuteCount = 0
AbilityActionBase.TimerHelper = nil
AbilityActionBase.AbilityHelper = nil
AbilityActionBase.nTargetType = nil -- PropUtil.TARGET_TYPE 类型

function AbilityActionBase:Create(Owner, OwnerPawn, tbInstigator, tbInitParams, nTargetType)
    self.Owner = Owner
    self.OwnerPawn = OwnerPawn
    self.tbInstigator = tbInstigator
    self.tbInitParams = tbInitParams
    self.TimerHelper = Owner.TimerHelper
    self.AbilityHelper = Owner.AbilityHelper
    self.nTargetType = nTargetType
    self:OnCreate(Owner, tbInitParams)
end

function AbilityActionBase:Destroy()
    self:OnDestroy()
    self.AbilityHelper = nil
    self.TimerHelper = nil
    self.tbInitParams = nil
    self.tbInstigator = nil
    self.OwnerPawn = nil
    self.Owner = nil
end

function AbilityActionBase:Do(tbParams)
    self.nExcuteCount = self.nExcuteCount + 1
    self:OnDo(tbParams)
end

function AbilityActionBase:Undo(tbParams)
    if self.nExcuteCount > 0 and (self.tbInitParams.ExecuteUndo ~= "false") then
        self:OnUndo(tbParams)
    end
end

function AbilityActionBase:OnCreate(Owner, tbInitParams)
end

function AbilityActionBase:OnDestroy()
end

function AbilityActionBase:OnDo(tbParams)
end

function AbilityActionBase:OnUndo(tbParams)
end

return AbilityActionBase

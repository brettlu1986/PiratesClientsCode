-----------------------------------------------------
--File Name    : AbilityEvent_AddBuff.lua
--Author       : Song Fuhao
--Create Time  : 2018-10-18
--Description  :
-----------------------------------------------------
local luaclass = require("luaclass")
local AbilityEventBaseClass = require("AbilityEventBase")
local AbilityEvent_AddBuff = luaclass("AbilityEvent_AddBuff", AbilityEventBaseClass)

local function OnBuffAdd(self, nBuffId)
    if nBuffId ~= self.tbParams.Value then
        return
    end
    self:TriggerDo()
end

local function OnBuffRemove(self, nBuffId)
    if nBuffId ~= self.tbParams.Value then
        return
    end
    self:TriggerUndo()
end

function AbilityEvent_AddBuff:OnActivate()
    self.OwnerPawn.BuffComponentServer.OnBuffAddDelegate:Bind(OnBuffAdd, self)
    self.OwnerPawn.BuffComponentServer.OnBuffRemoveDelegate:Bind(OnBuffRemove, self)
end

function AbilityEvent_AddBuff:OnDeactivate()
    self.OwnerPawn.BuffComponentServer.OnBuffAddDelegate:Unbind(OnBuffAdd, self)
    self.OwnerPawn.BuffComponentServer.OnBuffRemoveDelegate:Unbind(OnBuffRemove, self)
end

return AbilityEvent_AddBuff

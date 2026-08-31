-----------------------------------------------------
--File Name    : AbilityAction_StopMove.lua
--Author       : Song Fuhao
--Create Time  : 2019-05-29
--Description  : 打断角色移动状态，人船通用，可配置是否立即打断
-----------------------------------------------------
local luaclass = require("luaclass")
local AbilityActionBase = require("AbilityActionBase")
local AbilityAction_StopMove = luaclass("AbilityAction_StopMove", AbilityActionBase)

AbilityAction_StopMove.bImmediately = false

function AbilityAction_StopMove:OnCreate(Owner, tbInitParams)
    self.bImmediately = tbInitParams.Immediately == "true"
end

function AbilityAction_StopMove:OnDo(tbParams)
    self.AbilityHelper:ForeachAliveTargetPawns(function(tbCharacter)
        tbCharacter:StopMove(self.bImmediately)
    end, tbParams)
end

return AbilityAction_StopMove

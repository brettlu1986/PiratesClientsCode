-----------------------------------------------------
--File Name    : AbilityAction_RemoveBuff.lua
--Author       : Song Fuhao
--Create Time  : 2017-09-25
--Description  : 移除Buff
-----------------------------------------------------
local luaclass = require("luaclass")
local AbilityActionBase = require("AbilityActionBase")
local AbilityAction_RemoveBuff = luaclass("AbilityAction_RemoveBuff", AbilityActionBase)

local BattleAbilityDefine = require("BattleAbilityDefine")
local REMOVE_BUFF_TYPE = BattleAbilityDefine.REMOVE_BUFF_TYPE

AbilityAction_RemoveBuff.nBuffId = -1
AbilityAction_RemoveBuff.nGroupId = -1
AbilityAction_RemoveBuff.nTypeId = -1
AbilityAction_RemoveBuff.nType = REMOVE_BUFF_TYPE.REMOVE_BY_BUFF_ID
AbilityAction_RemoveBuff.tbBuffIds = nil

function AbilityAction_RemoveBuff:OnCreate(Owner, tbInitParams)
    self.nBuffId = tbInitParams.Value
    self.nGroupId = tbInitParams.Value
    self.nTypeId = tbInitParams.Value
    if tbInitParams.Type then
        self.nType = tbInitParams.Type
    end
    self.tbBuffIds = tbInitParams.BuffIds
end

function AbilityAction_RemoveBuff:OnDo(tbParams)
    self.AbilityHelper:ForeachAliveTargetPawns(function(tbCharacter)
        if self.nType == REMOVE_BUFF_TYPE.REMOVE_BY_BUFF_ID then
            tbCharacter.BuffComponentServer:RemoveBuffById(self.nBuffId)
        elseif self.nType == REMOVE_BUFF_TYPE.REMOVE_BY_GROUP_ID then
            tbCharacter.BuffComponentServer:RemoveBuffByGroupId(self.nGroupId)
        elseif self.nType == REMOVE_BUFF_TYPE.REMOVE_BY_TYPE_ID then
            tbCharacter.BuffComponentServer:RemoveBuffByTypeId(self.nTypeId)
        elseif self.nType == REMOVE_BUFF_TYPE.REMOVE_BY_BUFF_LIST then
            local tbBuffIds = self.tbBuffIds
            if tbBuffIds then
                for _, nBuffId in ipairs(tbBuffIds) do
                    tbCharacter.BuffComponentServer:RemoveBuffById(nBuffId)
                end
            end
        end
    end, tbParams)
end


return AbilityAction_RemoveBuff

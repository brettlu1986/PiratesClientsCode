-----------------------------------------------------
--File Name    : AbilityAction_AddBuff.lua
--Author       : Song Fuhao
--Create Time  : 2017-09-25
--Description  : 添加Buff
-----------------------------------------------------
local luaclass = require("luaclass")
local AbilityActionBase = require("AbilityActionBase")
local AbilityAction_AddBuff = luaclass("AbilityAction_AddBuff", AbilityActionBase)

AbilityAction_AddBuff.nBuffId = -1
AbilityAction_AddBuff.nLevel = 1
AbilityAction_AddBuff.nOverlapCount = 1
AbilityAction_AddBuff.tbBuffInfos = nil

function AbilityAction_AddBuff:OnCreate(Owner, tbInitParams)
    self.nBuffId = tbInitParams.Value
    if tbInitParams.Level then
        self.nLevel = tbInitParams.Level
    end
    if tbInitParams.Count then
        self.nOverlapCount = tbInitParams.Count
    end
    self.tbBuffInfos = {}
    if tbInitParams.InheritInstigator then
        self.tbNewBuffInstigator = self.tbInstigator
    else
        self.tbNewBuffInstigator = self.OwnerPawn
    end
end

function AbilityAction_AddBuff:OnDo(tbParams)
    self.AbilityHelper:ForeachAliveTargetPawns(function(tbCharacter)
        local nInstanceId = tbCharacter.BuffComponentServer:AddBuffWithInstigator(self.tbNewBuffInstigator, self.nBuffId, self.nOverlapCount, self.nLevel)
        table.insert(self.tbBuffInfos, {tbCharacter, nInstanceId})
    end, tbParams)
end

function AbilityAction_AddBuff:OnUndo(tbParams)
    for i,v in ipairs(self.tbBuffInfos) do
        local tbCharacter = v[1]
        local nInstanceId = v[2]
        tbCharacter.BuffComponentServer:RemoveBuffByInstanceId(self.nBuffId, nInstanceId)
    end
    self.tbBuffInfos = {}
end

return AbilityAction_AddBuff

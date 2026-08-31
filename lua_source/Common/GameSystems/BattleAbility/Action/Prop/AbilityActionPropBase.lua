-----------------------------------------------------
--File Name    : AbilityActionPropBase.lua
--Author       : Song Fuhao
--Create Time  : 2018-07-24
--Description  :
-----------------------------------------------------
local luaclass = require("luaclass")
local AbilityActionBase = require("AbilityActionBase")
local AbilityActionPropBase = luaclass("AbilityActionPropBase", AbilityActionBase)

local PropertyWrapperType = require("PropertyWrapperType")
local PropUtil = require("PropUtil")

AbilityActionPropBase.tbOverlapIdMap = nil

function AbilityActionPropBase:GetWrapperName()
    return nil
end

function AbilityActionPropBase:GetValue(tbCharacter)
    return self.tbInitParams.Value
end

function AbilityActionPropBase:GetOverlapType()
    return PropertyWrapperType.TYPE_ADD
end

function AbilityActionPropBase:GetTargetType()
    return self.nTargetType
end

function AbilityActionPropBase:Create(...)
    AbilityActionPropBase.super.Create(self, ...)
    self.tbOverlapIdMap = {}
end

function AbilityActionPropBase:OnDo(tbParams)
    self.AbilityHelper:ForeachAliveTargetPawns(function(tbCharacter)
        local nOverlapId = PropUtil.PropOverlapWithType(tbCharacter, self:GetTargetType(), self:GetOverlapType(), self:GetWrapperName(), self:GetValue(tbCharacter))
        table.insert(self.tbOverlapIdMap, {tbCharacter, nOverlapId})
    end, tbParams)
end

function AbilityActionPropBase:OnUndo(tbParams)
    for i,v in ipairs(self.tbOverlapIdMap) do
        local tbCharacter = v[1]
        local nOverlapId = v[2]
        PropUtil.RemovePropOverlapWithType(tbCharacter, self:GetTargetType(), self:GetWrapperName(), nOverlapId)
    end
end

return AbilityActionPropBase
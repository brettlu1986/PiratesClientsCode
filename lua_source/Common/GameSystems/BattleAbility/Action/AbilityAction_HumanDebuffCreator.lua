-----------------------------------------------------
--File Name    : AbilityAction_HumanDebuffToggle.lua
--Author       : Zuo Kun
--Create Time  : 2020-04-27
--Description  : 人debuff 发生器
-----------------------------------------------------
local luaclass = require("luaclass")
local AbilityActionBase = require("AbilityActionBase")
local AbilityAction_HumanDebuffCreator = luaclass("AbilityAction_HumanDebuffCreator", AbilityActionBase)

local function AddBuff(self, tbParams)
    local tbTaker = tbParams.tbTaker
    if not tbTaker then 
        return 
    end 

    tbTaker.BuffComponentServer:AddBuffById(self.nValue)
end


function AbilityAction_HumanDebuffCreator:OnCreate(Owner, tbInitParams)
    self.nValue = tbInitParams.Value
end

function AbilityAction_HumanDebuffCreator:OnDo(tbParams)
    self.AbilityHelper:ForeachAliveTargetPawns(function(tbCharacter)
        AddBuff(self, tbParams)
    end, tbParams)
end


return AbilityAction_HumanDebuffCreator

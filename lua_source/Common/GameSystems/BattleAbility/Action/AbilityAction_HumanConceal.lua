-----------------------------------------------------
--File Name    : AbilityAction_HumanConceal.lua
--Author       : Zuo Kun
--Create Time  : 2020-03-02
--Description  : 人隐蔽
-----------------------------------------------------
local luaclass = require("luaclass")
local AbilityActionBase = require("AbilityActionBase")
local AbilityAction_HumanConceal = luaclass("AbilityAction_HumanConceal", AbilityActionBase)

function AbilityAction_HumanConceal:OnDo(tbParams)
    self.AbilityHelper:ForeachAliveTargetPawns(function(tbCharacter)
        local tbHumanConcealComponent = tbCharacter.HumanConcealComponent
        if tbHumanConcealComponent then
            tbHumanConcealComponent:StartConceal()
        end
    end, tbParams)
end

function AbilityAction_HumanConceal:OnUndo(tbParams)
    self.AbilityHelper:ForeachAliveTargetPawns(function(tbCharacter)
        local tbHumanConcealComponent = tbCharacter.HumanConcealComponent
    if tbHumanConcealComponent then
            tbHumanConcealComponent:EndConceal()
        end
    end, tbParams)    
end

return AbilityAction_HumanConceal

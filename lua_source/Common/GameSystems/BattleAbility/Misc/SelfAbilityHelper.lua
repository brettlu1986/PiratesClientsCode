-----------------------------------------------------
--File Name    : SelfAbilityHelper.lua
--Author       : Song Fuhao
--Create Time  : 2017-09-25
--Description  : BattleAbility(Buff和Skill)的一些共同逻辑、数据写在这个里面
-----------------------------------------------------
local luaclass = require("luaclass")
local SelfAbilityHelper = luaclass("SelfAbilityHelper")

function SelfAbilityHelper:ForeachTargetPawns(fnCallback, tbParams)
    local tbTargetPawns = tbParams.tbTargetPawns
    if tbTargetPawns then
        for i,v in ipairs(tbTargetPawns) do
            if v then
                fnCallback(v)
            end
        end
    end
end

function SelfAbilityHelper:ForeachAliveTargetPawns(fnCallback, tbParams)
    local tbTargetPawns = tbParams.tbTargetPawns
    if tbTargetPawns then
        for i,v in ipairs(tbTargetPawns) do
            if v and (not v:IsDead()) then
                fnCallback(v)
            end
        end
    end
end

return SelfAbilityHelper

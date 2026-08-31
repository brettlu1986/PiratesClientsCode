-----------------------------------------------------
--File Name    : AbilityAction_LeakingProofProb.lua
--Author       : Song Fuhao
--Create Time  : 2018-10-11
--Description  : 修改漏水抗性
-----------------------------------------------------
local luaclass = require("luaclass")
local AbilityActionPropBase = require("AbilityActionPropBase")
local AbilityAction_LeakingProofProb = luaclass("AbilityAction_LeakingProofProb", AbilityActionPropBase)

function AbilityAction_LeakingProofProb:GetWrapperName()
    return require("PropName").nLeakingProofProb
end

return AbilityAction_LeakingProofProb

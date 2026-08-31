-----------------------------------------------------
--File Name    : AbilityAction_BurningProofProb.lua
--Author       : Song Fuhao
--Create Time  : 2018-10-11
--Description  : 修改点火抗性
-----------------------------------------------------
local luaclass = require("luaclass")
local AbilityActionPropBase = require("AbilityActionPropBase")
local AbilityAction_BurningProofProb = luaclass("AbilityAction_BurningProofProb", AbilityActionPropBase)

function AbilityAction_BurningProofProb:GetWrapperName()
    return require("PropName").nBurningProofProb
end

return AbilityAction_BurningProofProb

-----------------------------------------------------
--File Name    : InteractionRegister.lua
--Author       : Zuo Kun
--Create Time  : 2017-03-27
--Description  : 交互辅助类
-----------------------------------------------------
local luaclass = require("luaclass")
local InteractionRegister = luaclass("InteractionRegister")


function InteractionRegister:RegisterAllInteraction( InteractionSystem )
    InteractionSystem:RegisterInteraction(require("InteractionCamera"))
    InteractionSystem:RegisterInteraction(require("InteractionHeadDialog"))
    InteractionSystem:RegisterInteraction(require("InteractionHeadPortraitDialog"))
    InteractionSystem:RegisterInteraction(require("InteractionNoPortrait"))
    InteractionSystem:RegisterInteraction(require("InteractionPortrait"))
    InteractionSystem:RegisterInteraction(require("InteractionExplore"))
    InteractionSystem:RegisterInteraction(require("InteractionMatinee"))
    InteractionSystem:RegisterInteraction(require("InteractionBattlePortrait"))
end

return InteractionRegister
local luaclass = require("luaclass")

local SocietyGuardBattleStepClass = require("SocietyGuardBattleStep")
local SocietyGuardBattleStep_C = luaclass("SocietyGuardBattleStep_C", SocietyGuardBattleStepClass)

function SocietyGuardBattleStep_C:Start()
    SocietyGuardBattleStep_C.super.Start(self)

    local testGamePlayerSelfHelper = require("GamePlayerSelfHelper")
    local InteractionHelper = require("InteractionHelper")
    local target = testGamePlayerSelfHelper:Get()
    InteractionHelper:CreatePortraitHeadDialog(self.tbTemplateData.nHeadHintDialogId, nil, target)
end

return SocietyGuardBattleStep_C

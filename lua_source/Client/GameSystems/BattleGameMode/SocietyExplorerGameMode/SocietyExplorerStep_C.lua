local luaclass = require("luaclass")

local SocietyExplorerStepClass = require("SocietyExplorerStep")
local SocietyExplorerStep_C = luaclass("SocietyExplorerStep_C", SocietyExplorerStepClass)
-- local ClientEventDef = require("ClientEventDef")

function SocietyExplorerStep_C:Start()
    SocietyExplorerStep_C.super.Start(self)
    -- self.SelfEventHelper:RegisterEvent(ClientEventDef.EV_PLAYERSELF_READY, self, self.OnPlayersReady)
    local testGamePlayerSelfHelper = require("GamePlayerSelfHelper")
    local InteractionHelper = require("InteractionHelper")
    local target = testGamePlayerSelfHelper:Get()
    InteractionHelper:CreatePortraitHeadDialog(self.HeadHintDialogId, nil, target)
end

function SocietyExplorerStep_C:OnPlayersReady()
end

return SocietyExplorerStep_C

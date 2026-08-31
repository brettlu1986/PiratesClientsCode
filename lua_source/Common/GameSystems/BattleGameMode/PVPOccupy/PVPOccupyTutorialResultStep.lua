-- 处理新手指引竞技场结算之前的交互行为

local luaclass = require("luaclass")
local BattleStepBaseClass = require("BattleStepBase")
local PVPOccupyTutorialResultStep = luaclass("PVPOccupyTutorialResultStep", BattleStepBaseClass)

local BattleInteractionHelper = require("BattleInteractionHelper")

PVPOccupyTutorialResultStep.nDialogId = nil

function PVPOccupyTutorialResultStep:SetParams(nDialogId)
    self.nDialogId = nDialogId
end

function PVPOccupyTutorialResultStep:Start()
    PVPOccupyTutorialResultStep.super.Start(self)

    if self.nDialogId > 0 then
        BattleInteractionHelper:ShowDialog(self.nDialogId)
    end

    self:Complete()
end

return PVPOccupyTutorialResultStep

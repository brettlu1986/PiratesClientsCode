local luaclass = require("luaclass")
local BattleActionBase = require("BattleActionBase")
local BattleGuideAction = luaclass("BattleGuideAction", BattleActionBase)

local BattleOperationHelper = require("BattleOperationHelper")
local GuideSystem = require("GuideSystem")

BattleGuideAction.nGroup = nil
BattleGuideAction.nStep = nil

function BattleGuideAction:Parse(tbJsonData)
    self.nGroup = tbJsonData.Group
    self.nStep  = tbJsonData.Step
    return self.nGroup > 0 and self.nStep > 0
end

function BattleGuideAction:Execute()
    local szLog = string.format("Guide nGroup: %d nStep: %d", 
        self.nGroup, self.nStep)
    BattleOperationHelper:PrintLog(self, szLog)
    GuideSystem:GoToStep(self.nGroup, self.nStep)

    return true
end

return BattleGuideAction
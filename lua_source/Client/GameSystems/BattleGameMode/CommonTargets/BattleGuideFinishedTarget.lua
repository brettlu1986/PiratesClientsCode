-- 直接结束的Target

local luaclass = require("luaclass")
local BattleTargetBaseClass = require("BattleTargetBase")
local BattleGuideFinishedTarget = luaclass("BattleGuideFinishedTarget", BattleTargetBaseClass)

local EventManager = require("EventManager")
local ClientEventDef = require("ClientEventDef")

BattleGuideFinishedTarget.nModuleId = -1
BattleGuideFinishedTarget.nGroupId = -1
BattleGuideFinishedTarget.nStepId = -1

function BattleGuideFinishedTarget:Init()
    BattleGuideFinishedTarget.super.Init(self)
    self.szName = "BattleGuideFinishedTarget"
end

local function OnGuideFinished(self, nModuleId, nGroupId, nStepId)
    if(nModuleId == self.nModuleId
        and nGroupId == self.nGroupId
        and nStepId == self.nStepId) then
        self:Complete()
    end
end

function BattleGuideFinishedTarget:RegisterEvent()
    EventManager:BindEventMethod(ClientEventDef.EV_UI_GUIDE_END_STEP, self, OnGuideFinished)
end

function BattleGuideFinishedTarget:UnregisterEvent()
    EventManager:UnBindEventMethod(ClientEventDef.EV_UI_GUIDE_END_STEP, self, OnGuideFinished)
end

function BattleGuideFinishedTarget:Parse(tbJsonData)
    self.nModuleId = tbJsonData.ModuleId
    self.nGroupId = tbJsonData.GroupId
    self.nStepId = tbJsonData.StepId
    return self.nModuleId ~= nil
        and self.nGroupId ~= nil
        and self.nStepId ~= nil
end

return BattleGuideFinishedTarget
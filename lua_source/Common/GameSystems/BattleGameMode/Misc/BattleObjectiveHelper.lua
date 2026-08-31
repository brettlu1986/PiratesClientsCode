local BattleObjectiveHelper = {}

local D2CHelper = require("D2CHelper")
local DungeonDataTable = require("DungeonDataTable")
local Proto = require("DungeonCommonProtoNames")

BattleObjectiveHelper.rObjective = nil
BattleObjectiveHelper.tbObjectivePanel = nil
BattleObjectiveHelper.tbObjectiveToast = nil
BattleObjectiveHelper.nStepIndex = nil

function BattleObjectiveHelper:Init(nDungeonId, rObjective)
    local tbTemplate = DungeonDataTable:GetTemplate(nDungeonId)
    self.tbObjectivePanel = tbTemplate.tbObjectivePanel
    self.tbObjectiveToast = tbTemplate.tbObjectiveToast
    self.rObjective = rObjective
    self.nStepIndex = 0
end

function BattleObjectiveHelper:Uninit()
    self.tbObjectivePanel = nil
    self.tbObjectiveToast = nil
    self.rObjective = nil
    self.nStepIndex = 0
end

function BattleObjectiveHelper:ObjectiveStepForward()
    log("BattleObjectiveHelper:ObjectiveStepForward")
    local rObjective = self.rObjective
    if rObjective then
        self:SetObjectiveStepIndex(self.nStepIndex + 1, true)
    else
        logwarning("BattleObjectiveHelper:ObjectiveStepForward failed. rObjective not set")
    end
end

function BattleObjectiveHelper:SetObjectiveStepIndex(nStepIndex, bRep)
    local rObjective = self.rObjective
    if rObjective then
        if(nStepIndex <= #self.tbObjectivePanel) then
            self.nStepIndex = nStepIndex
            self:SendObjectiveInfo(self.tbObjectivePanel[nStepIndex], bRep)
        end
        if(nStepIndex <= #self.tbObjectiveToast) then
            D2CHelper:MulticastBattleToast(self.tbObjectiveToast[nStepIndex], nil, nil, nil, Proto.BattleToastInfo_EToastType.SPECIAL)
        end
    end
end

function BattleObjectiveHelper:SendObjectiveInfo(nId, bRep, szParam0, szParam1, szParam2)
    log("BattleObjectiveHelper:Send", nId, bRep, szParam0, szParam1, szParam2)
    local rObjective = self.rObjective
    if rObjective then
        rObjective.nId = nId
        rObjective.szParam0 = szParam0
        rObjective.szParam1 = szParam1
        rObjective.szParam2 = szParam2
        if bRep == true then
            rObjective.Rep()
        end
    else
        logwarning("BattleObjectiveHelper:SetObjective failed. rObjective not set")
    end
end

function BattleObjectiveHelper:RepObjective()
    local rObjective = self.rObjective
    if rObjective then
        rObjective.Rep()
    else
        logwarning("BattleObjectiveHelper:RepObjective failed. rObjective not set.")
    end
end

return BattleObjectiveHelper
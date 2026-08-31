-- 输赢结果结算

local luaclass = require("luaclass")
local BattleStepBaseClass = require("BattleStepBase")
local BattlePlayerResultStep = luaclass("BattlePlayerResultStep", BattleStepBaseClass)
local BattleTimerTargetClass = require("BattleTimerTarget")
local D2CHelper = require("D2CHelper")
local BattleTeamSystem = require("BattleTeamSystem")

BattlePlayerResultStep.TimerTarget = nil
BattlePlayerResultStep.rResultStep = nil
BattlePlayerResultStep.bSendResultToHub = true
--是否停船
BattlePlayerResultStep.bStopShip = true 

local nInvincibleBufferId = 5002

local function SetAllShipInvincible()
    BattleTeamSystem:VisitAllMembers(function (tbCharacter)
        if tbCharacter.BuffComponentServer then
            tbCharacter.BuffComponentServer:AddBuffById(nInvincibleBufferId)
        end
    end)
end

function BattlePlayerResultStep:Init()
    BattlePlayerResultStep.super.Init(self)

    self.szName = "BattlePlayerResultStep"
    self.TimerTarget = self:CreateTarget(BattleTimerTargetClass)
end

function BattlePlayerResultStep:Start()
    -- 结算阶段事件
    SetAllShipInvincible()
    
    -- 停船
    if self.bStopShip then
        D2CHelper:MulticastStopMove()
    end
    BattlePlayerResultStep.super.Start(self)
end

function BattlePlayerResultStep:SetParams(rBattlePlayerResultStep, nTime, bSendResultToHub)
    self.rResultStep = rBattlePlayerResultStep
    rBattlePlayerResultStep.nStepTime = nTime
    self.TimerTarget:SetTime(nTime)
    self.bSendResultToHub = bSendResultToHub
end

-- 同步Step信息
function BattlePlayerResultStep:RepStepInfo(bRepNow)    
    if(bRepNow) then
        self.rResultStep.RepNow()
    else
        self.rResultStep.Rep()
    end
    BattlePlayerResultStep.super.RepStepInfo(self, bRepNow)
end

-- 子类必须重载，将当前状态的快照写入replicate属性中，这里可根据情况调用rep，这函数会在新玩家登入时调用
function BattlePlayerResultStep:SnapshotToReplicatedProperty()
    self:RepStepInfo()
    return true
end

return BattlePlayerResultStep

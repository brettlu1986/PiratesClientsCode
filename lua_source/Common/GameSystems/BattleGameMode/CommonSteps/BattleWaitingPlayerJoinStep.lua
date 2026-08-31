--等待玩家进入step，过了时间并且有玩家就会结束

local luaclass = require("luaclass")
local BattleStepBaseClass = require("BattleStepBase")
local BattleWaitingPlayerJoinStep = luaclass("BattleWaitingPlayerJoinStep", BattleStepBaseClass)

local BattleTimerTargetClass = require("BattleTimerTarget")
local EventManager = require("EventManager")
local CommonEventDef = require("CommonEventDef")
local DelayTimer = require("DelayTimer")

local BattleGameModeSystem = dynamic_require("BattleGameModeSystem")

BattleWaitingPlayerJoinStep.TimerTarget = nil
BattleWaitingPlayerJoinStep.nMaxCount = 0
BattleWaitingPlayerJoinStep.tbLoginPlayerIds = nil
BattleWaitingPlayerJoinStep.nDelayCompleteTime = 2
BattleWaitingPlayerJoinStep.TimerHandler = nil
BattleWaitingPlayerJoinStep.bSetCheckFunc = false


function BattleWaitingPlayerJoinStep:Init()
    BattleWaitingPlayerJoinStep.super.Init(self)

    self.szName = "BattleWaitingPlayerJoinStep"
    self.TimerTarget = self:CreateTarget(BattleTimerTargetClass)
end

function BattleWaitingPlayerJoinStep:SetParams(rTimeStepInfo, nTime, nMaxPlayerCount, nDelayCompleteTime)
    self.rTimeStepInfo = rTimeStepInfo
    rTimeStepInfo.nStepTime = nTime
    self.TimerTarget:SetTime(nTime)
    self.nMaxCount = nMaxPlayerCount
    if(nDelayCompleteTime) then
        self.nDelayCompleteTime = nDelayCompleteTime
    end
    self.tbPlayerIds = {}
end

function BattleWaitingPlayerJoinStep:ClearTimer()
    if(self.TimerHandler) then
        DelayTimer:ClearTimer(self.TimerHandler)
        self.TimerHandler = nil
    end
end

function BattleWaitingPlayerJoinStep:OnPlayerLogin(tbGamePlayer)
    local tbPlayerIds = self.tbPlayerIds
    local nCount = #tbPlayerIds
    local nPlayerId = tbGamePlayer.nPlayerId
    for i=1, nCount do
        if(tbPlayerIds[i] == nPlayerId) then
            return
        end
    end
    table.insert(tbPlayerIds, tbGamePlayer.nPlayerId)
    if(self.TimerHandler == nil and nCount + 1 >= self.nMaxCount) then
        self.TimerHandler = DelayTimer:DelayRun(function()
            self.TimerHandler = nil
            self:Complete()
        end, self.nDelayCompleteTime)
    end
end

function BattleWaitingPlayerJoinStep:Start()
    self.nCurrentCount = 0

    BattleWaitingPlayerJoinStep.super.Start(self)
end

function BattleWaitingPlayerJoinStep:RegisterEvent()
    BattleWaitingPlayerJoinStep.super.RegisterEvent(self)

    EventManager:BindEventMethod(CommonEventDef.EV_GAME_MODE_ON_PLAYER_LOGIN, self, self.OnPlayerLogin)

    -- 截获GameMode checkLogout函数
    local GameMode = BattleGameModeSystem:GetGameMode()
    if(not self.bSetCheckFunc and GameMode and GameMode.SetCheckAllPlayerLogoutFunc) then
        self.bSetCheckFunc = true
        GameMode:SetCheckAllPlayerLogoutFunc(function() return false end)
    end
end

function BattleWaitingPlayerJoinStep:UnregisterEvent()
    BattleWaitingPlayerJoinStep.super.UnregisterEvent(self)

    EventManager:UnBindEventMethod(CommonEventDef.EV_GAME_MODE_ON_PLAYER_LOGIN, self, self.OnPlayerLogin)
    self:ClearTimer()

    local GameMode = BattleGameModeSystem:GetGameMode()
    if(self.bSetCheckFunc and GameMode and GameMode.SetCheckAllPlayerLogoutFunc) then
        self.bSetCheckFunc = false
        GameMode:SetCheckAllPlayerLogoutFunc(nil)
    end    
end

function BattleWaitingPlayerJoinStep:Complete()    
    self.tbPlayerIds = nil

    BattleWaitingPlayerJoinStep.super.Complete(self)
end

function BattleWaitingPlayerJoinStep:CheckComplete(BattleTarget)
    if(#self.tbPlayerIds == 0) then
        self.TimerHandler = DelayTimer:RunNextTick(function()
            self.TimerHandler = nil
            EventManager:OnFireEvent(CommonEventDef.EV_GAME_MODE_ON_NO_PLAYER_ENTER)
        end)
        return false
    end
    return true
end

function BattleWaitingPlayerJoinStep:RepStepInfo(bRepNow)
    if(bRepNow) then
        self.rTimeStepInfo.RepNow()
    else
        self.rTimeStepInfo.Rep()
    end
    BattleWaitingPlayerJoinStep.super.RepStepInfo(self, bRepNow)
end

function BattleWaitingPlayerJoinStep:SnapshotToReplicatedProperty()
    self:RepStepInfo()
    return true
end

return BattleWaitingPlayerJoinStep
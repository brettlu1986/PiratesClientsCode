-- 保底方案回收副本step

local luaclass = require("luaclass")
local BattleTargetActionStep = require("BattleTargetActionStep")
local BattleReleaseDungeonStep = luaclass("BattleReleaseDungeonStep", BattleTargetActionStep)

local CommonEventDef = require("CommonEventDef")
local DelayTimer = require("DelayTimer")
local BotAISystem = dynamic_require("BotAISystem")
local GameObjectTypeDef = require("GameObjectTypeDef")
local BattleGameModeSystem = dynamic_require("BattleGameModeSystem")
local GameObjectSystem = dynamic_require("GameObjectSystem")


BattleReleaseDungeonStep.bLastCheckResult = false
BattleReleaseDungeonStep.tbTimer = nil
BattleReleaseDungeonStep.nCheckTime = 120

function BattleReleaseDungeonStep:Init()
    BattleReleaseDungeonStep.super.Init(self)
    self.szName = "BattleReleaseDungeonStep"
end

function BattleReleaseDungeonStep:Parse(tbJsonData)
    if(not BattleReleaseDungeonStep.super.Parse(self, tbJsonData)) then
        return false
    end

    self.nCheckTime = tbJsonData.nCheckTime
    return true
end

local function ClearTimer(self)
    if self.tbTimer ~= nil then
        DelayTimer:ClearTimer(self.tbTimer)
        self.tbTimer = nil
    end
end

local function CheckAllRealPlayerLogout(self)
    local bRet = true
    local tbGameMode = BattleGameModeSystem:GetGameMode()
    local tbPlayers = tbGameMode.tbPlayers
    for nIndex, tbPlayer in ipairs(tbPlayers) do
        if not BotAISystem:IsBot(tbPlayer) then
            bRet = false
            break
        end
    end
    
    return bRet
end

local function OnFinalCheck(self)
    if self.bLastCheckResult then
        local bCheckResult = CheckAllRealPlayerLogout(self)

        if bCheckResult then
            --强制所有人走结算流程
            local tbGameMode = BattleGameModeSystem:GetGameMode()
            if tbGameMode and tbGameMode.OnForceReleaseDungeon then
                tbGameMode:OnForceReleaseDungeon()
            end
        end
    end

    self.bLastCheckResult = false
    ClearTimer(self)
end

local function OnPlayerLogin(self,tbPlayer)
    if tbPlayer and tbPlayer.ObjectType == GameObjectTypeDef.PlayerSelf and not BotAISystem:IsBot(tbPlayer) then
        self.bLastCheckResult = false
        ClearTimer(self)
    end
end

local function InterCheck(self,tbPlayer)
    if not self.tbTimer and tbPlayer and tbPlayer.ObjectType == GameObjectTypeDef.PlayerSelf and not BotAISystem:IsBot(tbPlayer) then
        local bCheckResult = CheckAllRealPlayerLogout(self)

        if bCheckResult then
            self.bLastCheckResult = true
            self.tbTimer = DelayTimer:DelayRun(function() OnFinalCheck(self) end,self.nCheckTime)
        end
    end
end

local function OnPlayerBattleEnd(self,tbPlayer)
    InterCheck(self,tbPlayer)
end

local function OnPostPlayerLogout(self,nPlayerId,nGroupIndex)
    local tbPlayer = GameObjectSystem:FindPlayerByPlayerId(nPlayerId)
    InterCheck(self,tbPlayer)
end

function BattleReleaseDungeonStep:RegisterEvent()
    self.SelfEventHelper:RegisterEvent(CommonEventDef.EV_GAME_MODE_ON_PLAYER_LOGIN, self, OnPlayerLogin)
    self.SelfEventHelper:RegisterEvent(CommonEventDef.EV_GAME_MODE_ON_PLAYER_RELOGIN, self, OnPlayerLogin)
    self.SelfEventHelper:RegisterEvent(CommonEventDef.EV_PLAYER_BATTLE_END, self, OnPlayerBattleEnd)
    self.SelfEventHelper:RegisterEvent(CommonEventDef.EV_BATTLE_PLAYER_POST_LOGOUT, self, OnPostPlayerLogout)
end

function BattleReleaseDungeonStep:Start()
    BattleReleaseDungeonStep.super.Start(self)
end

function BattleReleaseDungeonStep:Uninit()
    BattleReleaseDungeonStep.super.Uninit(self)
    ClearTimer(self)
end

function BattleReleaseDungeonStep:ForceStop()
    BattleReleaseDungeonStep.super.ForceStop(self)
end

function BattleReleaseDungeonStep:OnCompleted()
    BattleReleaseDungeonStep.super.OnCompleted(self)
end

function BattleReleaseDungeonStep:RepStepInfo(bRepNow)
    BattleReleaseDungeonStep.super.RepStepInfo(self, bRepNow)
end

-- 子类必须重载，将当前状态的快照写入replicate属性中，这里可根据情况调用rep，这函数会在新玩家登入时调用
function BattleReleaseDungeonStep:SnapshotToReplicatedProperty()
    self:RepStepInfo()
    return true
end

return BattleReleaseDungeonStep
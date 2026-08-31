local luaclass = require("luaclass")
local BattleStepBaseClass = require("BattleStepBase")
local FFAGameModeStep = luaclass("FFAGameModeStep", BattleStepBaseClass)
local GameObjectSystem = dynamic_require("GameObjectSystem")
local GameObjectTypeDef = require("GameObjectTypeDef")
local BattleGameModeSystem = dynamic_require("BattleGameModeSystem")
local BotAISystem = dynamic_require("BotAISystem")

local EventManager = require("EventManager")
local CommonEventDef = require("CommonEventDef")

local Timer = require("Timer")

local nPlayerCountCollectInterval = 5
FFAGameModeStep.PlayerCountTimer = nil
FFAGameModeStep.rFFAInfo = nil

function FFAGameModeStep:Start()
    FFAGameModeStep.super.Start(self)
    EventManager:OnFireEvent(CommonEventDef.EV_BATTLE_TEAM_BOT_START)

    if not self.PlayerCountTimer then
        self.PlayerCountTimer = Timer.NewTimerMethod(self, self.CollectPlayerCountInfo,
            nPlayerCountCollectInterval, true)
    end

    local GameMode = BattleGameModeSystem:GetGameMode()
    GameMode:SetCheckAllPlayerLogoutFunc(function()
        return not BotAISystem:IsAllRealPlayerLogout()
    end)
end

function FFAGameModeStep:SetParams(tbGameState)
    self.rFFAInfo = tbGameState.rFFAInfo
end

function FFAGameModeStep:CollectPlayerCountInfo()
    local rFFAInfo = self.rFFAInfo
    local nCount = 0
    local tbObjects = GameObjectSystem:GetAllByObjectType(GameObjectTypeDef.PlayerSelf)
    for Object, _ in pairs(tbObjects) do
        if (not Object:IsDead()) then
            nCount = nCount + 1
        end
    end
    if nCount ~= rFFAInfo.nAlivePlayerCount then
        rFFAInfo.nAlivePlayerCount = nCount
        rFFAInfo.Rep()
    end
end

function FFAGameModeStep:Init()
    FFAGameModeStep.super.Init(self)

    self.szName = "FFAGameModeStep"
end

-- 子类必须重载，将当前状态的快照写入replicate属性中，这里可根据情况调用rep，这函数会在新玩家登入时调用
function FFAGameModeStep:SnapshotToReplicatedProperty()
    return true
end

function FFAGameModeStep:Uninit()
    if self.PlayerCountTimer then
        self.PlayerCountTimer:Clear()
        self.PlayerCountTimer = nil
    end

    local GameMode = BattleGameModeSystem:GetGameMode()
    GameMode:SetCheckAllPlayerLogoutFunc(nil)

    FFAGameModeStep.super.Uninit(self)
end

return FFAGameModeStep
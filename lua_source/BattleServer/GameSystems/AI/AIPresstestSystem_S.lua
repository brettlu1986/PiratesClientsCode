local luaclass   = require("luaclass")
local AIPresstestSystem  = require("AIPresstestSystem")
local AIPresstestSystem_S  = luaclass("AIPresstestSystem_S", AIPresstestSystem)
local StringUtil = require("StringUtil")
local GlobalVariableSystem = dynamic_require("GlobalVariableSystem")
local EventManager = require("EventManager")
local CommonEventDef = require("CommonEventDef")
local BattleGameModeSystem = dynamic_require("BattleGameModeSystem")
local BotSpawner = require("BotSpawner")
local SelfTimerHelperClass = require("SelfTimerHelper")
local GameObjectSystem = dynamic_require("GameObjectSystem")
local GameObjectTypeDef = require("GameObjectTypeDef")
local BattleTeamSystem = require("BattleTeamSystem")

AIPresstestSystem_S.tbTimerHelper = nil

local nSpawnBotTime = 2
local nSkipWaitTime = 20
local nSkipSelectionTime = 25
local nBotAIGroupId = 8

local CMD_ARG_NAME = "-aistresstest="

local function LOG(...)
    log("CJ->AIPresstestSystem:", ...)
end

local function SetBoolValue(tbKeyName, bValue)
    local BattleBlackboard = require("BattleBlackboard")
    if BattleBlackboard:IsDefined(tbKeyName) then
        BattleBlackboard:SetBool(tbKeyName ,bValue)
    end
end

local function OnDead(self, tbGameObject)
    LOG("player dead:", tbGameObject.szName)
    local tbObjects = GameObjectSystem:GetAllByObjectType(GameObjectTypeDef.PlayerSelf)
    local bFinished = true
    local nTeamId = -1
    for Object, _ in pairs(tbObjects) do
        if not Object:IsDead() and tbGameObject ~= Object then
            local nCurentTeamId = BattleTeamSystem:FindTeamId(Object)
            LOG("team id ", nCurentTeamId)
            if nCurentTeamId ~= nTeamId then
                if nTeamId > 0 then
                    bFinished = false
                    break
                else
                    nTeamId = nCurentTeamId
                end
            end
        end
    end
    if bFinished then
        LOG("reset stress test")
        local tbGameMode = BattleGameModeSystem:GetGameMode()
        if tbGameMode then
            tbGameMode:OnAllPlayerLogoutWithEvent()
        end
    end
end

function AIPresstestSystem_S:Init()
    local szCommandLine = KismetSystemLibrary.GetCommandLine()
    local tbCmdArgs = StringUtil.Split(szCommandLine, " ")
    local szArgValue = ""
    for _,v in ipairs(tbCmdArgs) do
        if StringUtil.StartsWith(v, CMD_ARG_NAME) then
            szArgValue = string.sub(v, #CMD_ARG_NAME + 1, -1)
            break
        end
    end
    LOG("InitByCmdArgs: ", CMD_ARG_NAME, szArgValue)
    if szArgValue ~= "" then
        self.nNumAgnet = tonumber(szArgValue) or 0
        self.bEnabled = self.nNumAgnet > 0
        LOG("enabled, num agent:", self.bEnabled, self.nNumAgnet)
        if self.bEnabled then
            self:StartTest()
        end
    else
        LOG("enabled:", self.bEnabled)
    end
end

function AIPresstestSystem_S:GameStart()
    LOG("game start")
    if (BattleGameModeSystem:GetGameMode().Setting) then
        BattleGameModeSystem:GetGameMode().Setting.bNeverCheckLoginOut = true
    end
    self.tbTimerHelper:NewTimer(function()
        LOG("spawn bot")
        BotSpawner.Spawn(self.nNumAgnet , nBotAIGroupId, 10)
    end, nSpawnBotTime, false)
    self.tbTimerHelper:NewTimer(function()
        LOG("skip wait")
        SetBoolValue("SkipFFAWaitTime", true)
    end, nSkipWaitTime, false)
    self.tbTimerHelper:NewTimer(function()
        LOG("skip selection")
        SetBoolValue("SkipFFASelectionPoint", true)
        SetBoolValue("SkipPlayFFAMatinee", true)
    end, nSkipSelectionTime, false)
end

function AIPresstestSystem_S:GameEnd()
    if self.tbTimerHelper then
        self.tbTimerHelper:ClearAllTimer()
        self.tbTimerHelper = nil
    end
end

function AIPresstestSystem_S:StartTest()
    LOG("start ai press test")
    self.tbTimerHelper = SelfTimerHelperClass()
    EventManager:BindEventMethod(CommonEventDef.EV_GAME_MODE_START_PLAY, self, self.GameStart)
    EventManager:BindEventMethod(CommonEventDef.EV_GAME_MODE_END_PLAY, self, self.GameEnd)
    EventManager:BindEventMethod(CommonEventDef.EV_GAME_OBJECT_ON_PAWN_DEAD, self, OnDead)
    GlobalVariableSystem.EnableDLAgent = true
end

function AIPresstestSystem:Uninit()
    EventManager:UnBindEventMethod(CommonEventDef.EV_GAME_MODE_START_PLAY, self, self.GameStart)
    EventManager:UnBindEventMethod(CommonEventDef.EV_GAME_MODE_END_PLAY, self, self.GameEnd)
    EventManager:UnBindEventMethod(CommonEventDef.EV_GAME_OBJECT_ON_PAWN_DEAD, self, OnDead)
end

return AIPresstestSystem_S()
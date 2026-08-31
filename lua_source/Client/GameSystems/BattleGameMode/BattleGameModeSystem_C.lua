local luaclass = require("luaclass")
local BattleGameModeSystem = require("BattleGameModeSystem")
local BattleGameModeSystem_C = luaclass("BattleGameModeSystem_C", BattleGameModeSystem)

local GlobalVariableSystem = dynamic_require("GlobalVariableSystem")
local NetworkManager = dynamic_require("NetworkManager")
local ProtoDC = require("DungeonCommonProtoNames")
local Proto   = require("ClientProtoNames")
local UIUtils = require("UIUtils")
local UIDialogQuitDungeonHelper = require("UIDialogQuitDungeonHelper")
local EventManager = require("EventManager")
local ClientEventDef = require("ClientEventDef")
local CommonEventDef = require("CommonEventDef")
-- local GlobalVariableSystem_C = require("GlobalVariableSystem_C")
-- local ProcedureTool = require("ProcedureTool")
local UITextDef = require("UITextDef")
local DisconnectType = require("DisconnectTypeNew")
local ProcedureTool = require("ProcedureTool")
local DelayTimer = require("DelayTimer")

local UNRESPOSE_QUIT_DELAY = 5

BattleGameModeSystem_C.bRetraveling = false
BattleGameModeSystem_C.tbDelayHandle = nil

BattleGameModeSystem_C.QUIT_REASON =
{
    QUIT_BUTTON = ProtoDC.c2d_QuitDungeon_QuitReason.QUIT_BUTTON,
    BACK_TO_PORT = ProtoDC.c2d_QuitDungeon_QuitReason.BACK_TO_PORT,
}

local function DestroyDelayTimer(self)
    if self.tbQuitDungeonTimer then
        DelayTimer:ClearTimer(self.tbQuitDungeonTimer)
        self.tbQuitDungeonTimer = nil
    end
end

local function OnGameStateBeginPlay(self, pGameState)
    if GlobalVariableSystem:IsDedicatedClient() then
        self:GetGameStatePropertyBinder():DefinePropertiesWhenGameStateReady(self.tbGameState)
    end
end

function BattleGameModeSystem_C:Init()
    BattleGameModeSystem_C.super.Init(self)
    EventManager:BindEventMethod(ClientEventDef.EV_EXIT_LOADING, self, self.OnSceneLoadEnd)
    EventManager:BindEventMethod(CommonEventDef.EV_GAME_STATE_ON_BEGIN_PLAY, self, OnGameStateBeginPlay)
end

function BattleGameModeSystem_C:Uninit()
    DestroyDelayTimer(self)
    BattleGameModeSystem_C.super.Uninit(self)
    EventManager:UnBindEventMethod(ClientEventDef.EV_EXIT_LOADING, self, self.OnSceneLoadEnd)
    EventManager:UnBindEventMethod(CommonEventDef.EV_GAME_STATE_ON_BEGIN_PLAY, self, OnGameStateBeginPlay)

    self.bRetraveling = false
end

function BattleGameModeSystem_C:OnSceneLoadEnd()
    if(self.tbGameMode) then
        log("BattleGameModeSystem StartFirstStep")
        self.tbGameMode:StartFirstStep()
        EventManager:OnFireEvent(CommonEventDef.EV_GAME_MODE_START_PLAY)
    end
end

-- 玩家主动退出副本
function BattleGameModeSystem_C:RequestQuitDungeon(nQuitReason)
    log("BattleGameModeSystem:QuitDungeon", nQuitReason)
    local rJsonMainStepInfo = self.tbGameState and self.tbGameState.rJsonMainStepInfo
    if rJsonMainStepInfo and rJsonMainStepInfo.bCanNotLeaveDungeon then
        -- 对应不能离开的提示
        local nQuitDungeonType = self.tbGameState.rGameStateBaseInfo.nQuitDungeonType
        local szMessage = UIDialogQuitDungeonHelper:GetDungeonQuitDialogLimitMessage(nQuitDungeonType)
        if szMessage then
            UIUtils.ShowToast(szMessage)
        end
    else
        NetworkManager:GetHubServerProxy():SendPacket(Proto.c2s_LeaveDungeon)
        if self.tbQuitDungeonTimer == nil then
            log("quit dungeon start timer")
            local fnUnresponseQuit = function()
                DestroyDelayTimer(self)
                log("UIFFABattleStatistics quit dungeon over timer and return to start game")
                local l10nText = UITextDef.DISCONNECT_SERVER_UNKNOWN
                UIUtils.ShowDisconnectDialog(l10nText, UITextDef.L10N_OK, function() 
                    ProcedureTool:ReturnToStartGame()
                end, DisconnectType.with_lobby_config)
            end
            self.tbQuitDungeonTimer = DelayTimer:DelayRun(fnUnresponseQuit, UNRESPOSE_QUIT_DELAY)
        end            
    end
end

function BattleGameModeSystem_C:StartPlay()
    -- 单机副本等loading完在开始执行step 等待EV_EXIT_LOADING事件处理OnSceneLoadEnd
end

function BattleGameModeSystem_C:OnRecvInvalidData(tbGameObject, szInfo)
    if tbGameObject == self.tbGameState then
        return
    end

    if(tbGameObject) then
        error(szInfo..", "..require("dkjson").encode(tbGameObject:GetDebugInfo()))
    else
        error(szInfo)
    end
end

function BattleGameModeSystem_C:SetDungeonId(nDungeonId)
    self.nDungeonId = nDungeonId
end

function BattleGameModeSystem_C:GetDungeonId()
    return self.nDungeonId
end


return BattleGameModeSystem_C()

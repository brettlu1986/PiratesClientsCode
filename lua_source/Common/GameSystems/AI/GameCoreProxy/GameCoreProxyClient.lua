local luaclass = require("luaclass")
local GameCoreProxyClient   = luaclass("GameCoreProxyClient")

local GameCoreProxyNetwork  = require("GameCoreProxyNetwork")
local ServerProtoNames      = require("GameCoreServerProtoNames")
local Proto                 = require("GameCoreClientProtoNames")
local GlobalVariableSystem  = dynamic_require("GlobalVariableSystem")
local Timer                 = require("Timer")
local CommonEventDef        = require("CommonEventDef")
local BattleTeamSystem      = require("BattleTeamSystem")
local AgentStatisticsSystem = require("AgentStatisticsSystem")
local AIHelper              = require("AIHelper")
local GameObjectSystem      = dynamic_require("GameObjectSystem")
local BattleGameModeSystem  = dynamic_require("BattleGameModeSystem")
local DelayTimer            = require("DelayTimer")
local SelfTimerHelperClass  = require("SelfTimerHelper")
local SelfEventHelperClass  = require("SelfEventHelper")
local GameObjectTypeDef     = require("GameObjectTypeDef")
local StringUtil            = require("StringUtil")
local GameCoreAgentDistribution = require("GameCoreAgentDistribution")
local GameCoreAgentLevel    = require("GameCoreAgentLevel")
local GameCoreVariable      = require("GameCoreVariable")
local SpawnerDef            = require("SpawnerDef")
local EventManager          = require("EventManager")


GameCoreProxyClient.Network = nil
GameCoreProxyClient.tbAgents = nil
GameCoreProxyClient.bStarted = false
GameCoreProxyClient.nTickInterval = GameCoreVariable.nDefaultTickInterval
GameCoreProxyClient.tbPoisonCirlce = nil
GameCoreProxyClient.tbOverridePoisonCircleData = nil
GameCoreProxyClient.nRunningSpeed = 1
GameCoreProxyClient.szCCSGameId = nil
GameCoreProxyClient.nAISdkStartTimer = nil
GameCoreProxyClient.SelfTimerHelper = nil
GameCoreProxyClient.SelfEventHelper = nil
GameCoreProxyClient.OnServerDeadDeleagte = nil
GameCoreProxyClient.bEnterTransportStep = false
GameCoreProxyClient.bAutoOpenDlAgent = true
GameCoreProxyClient.nDlAgentMin = 0
GameCoreProxyClient.tbChangeToAgentTimer = nil
GameCoreProxyClient.nBTBotCount = 0
GameCoreProxyClient.bSendFPS = false
GameCoreProxyClient.tbRealPlayers = nil
GameCoreProxyClient.tbAirDrops = nil
GameCoreProxyClient.tbFogData = nil
GameCoreProxyClient.bItemSpawned = false

local SHRINK_TIMER = "shrink"
local WAIT_TIMER = "wait"

local CMD_ARG_NAME = "-dlagentmin="

local AGENT_LEVEL_STRATEGY = "from_config"

--local fnGetFPS = ExtendBlueprintFunctions.GetFPS


local tbPacketProcessor = {
    { Packet = ServerProtoNames.s2c_fire,   Processor = require("GameCorePacketProcessorFire") },
    { Packet = ServerProtoNames.s2c_move,   Processor = require("GameCorePacketProcessorMove") },
    { Packet = ServerProtoNames.s2c_focus,  Processor = require("GameCorePacketProcessorFocus") },
    { Packet = ServerProtoNames.s2c_pick,   Processor = require("GameCorePacketProcessorPickItem") },
    { Packet = ServerProtoNames.s2c_crouch, Processor = require("GameCorePacketProcessorCrouch") },
    { Packet = ServerProtoNames.s2c_jump,   Processor = require("GameCorePacketProcessorJump") },
    { Packet = ServerProtoNames.s2c_crawl,  Processor = require("GameCorePacketProcessorCrawl") },
    { Packet = ServerProtoNames.s2c_stand,  Processor = require("GameCorePacketProcessorStand") },
    { Packet = ServerProtoNames.s2c_switchWeapon,  Processor = require("GameCorePacketProcessorSwitchWeapon") },
    { Packet = ServerProtoNames.s2c_setSyncInterval,  Processor = require("GameCorePacketProcessorSyncInterval") },
    { Packet = ServerProtoNames.s2c_run,  Processor = require("GameCorePacketProcessorRun") },
    { Packet = ServerProtoNames.s2c_consumeItem,  Processor = require("GameCorePacketProcessorConsumeItem") },
    { Packet = ServerProtoNames.s2c_dropItem,  Processor = require("GameCorePacketProcessorDropItem") },
    { Packet = ServerProtoNames.s2c_reload,  Processor = require("GameCorePacketProcessorReload") },
    { Packet = ServerProtoNames.s2c_directMove,   Processor = require("GameCorePacketProcessorDirectMove") },
    { Packet = ServerProtoNames.s2c_linetrace,   Processor = require("GameCorePacketProcessorLineTrace") },
    { Packet = ServerProtoNames.s2c_jumpWall,   Processor = require("GameCorePacketProcessorJumpWall") },
    { Packet = ServerProtoNames.s2c_buildItem,   Processor = require("GameCorePacketProcessorBuildItem") },
    { Packet = ServerProtoNames.s2c_rescue,   Processor = require("GameCorePacketProcessorRescue") },
    { Packet = ServerProtoNames.s2c_joyStickInput,   Processor = require("GameCorePacketProcessorJoyStick") },
    { Packet = ServerProtoNames.s2c_hello,   Processor = require("GameCorePacketProcessorHello") },
    { Packet = ServerProtoNames.s2c_changeDisplay,   Processor = require("GameCorePacketProcessorChangeDisplay") },
    { Packet = ServerProtoNames.s2c_stopMeleeAttack,   Processor = require("GameCorePacketProcessorStopMeleeAttack") },
    { Packet = ServerProtoNames.s2c_switchCarronadeEffect,   Processor = require("GameCorePacketProcessorSwitchCarronadeEffect") },
    { Packet = ServerProtoNames.s2c_switchDoor,   Processor = require("GameCorePacketProcessorSwitchDoor") },
    { Packet = ServerProtoNames.s2c_holdThrownWeapon,   Processor = require("GameCorePacketProcessorHoldThrownWeapon") },
    { Packet = ServerProtoNames.s2c_unholdThrownWeapon,   Processor = require("GameCorePacketProcessorUnholdThrownWeapon") },
    { Packet = ServerProtoNames.s2c_throwAttack,   Processor = require("GameCorePacketProcessorThrowAttack") },
    { Packet = ServerProtoNames.s2c_setShipPosture,   Processor = require("GameCorePacketProcessorSetShipPosture") },
    { Packet = ServerProtoNames.s2c_configSight,   Processor = require("GameCorePacketProcessorConfigSight") },
    { Packet = ServerProtoNames.s2c_changeVehicleState,   Processor = require("GameCorePacketProcessorChangeVehicleState") },
    { Packet = ServerProtoNames.s2c_setAim,   Processor = require("GameCorePacketProcessorSetAim") },
    { Packet = ServerProtoNames.s2c_equipItem,   Processor = require("GameCorePacketProcessorEquipItem") },
    { Packet = ServerProtoNames.s2c_unequipItem,   Processor = require("GameCorePacketProcessorUnequipItem") },
}

local tbTrainingPacketProcessor = {
    { Packet = ServerProtoNames.s2c_addBot, Processor = require("GameCorePacketProcessorAddBot") },
    { Packet = ServerProtoNames.s2c_addBTBot, Processor = require("GameCorePacketProcessorAddBTBot") },
    { Packet = ServerProtoNames.s2c_addItem,  Processor = require("GameCorePacketProcessorAddItem") },
    { Packet = ServerProtoNames.s2c_spawnItem,  Processor = require("GameCorePacketProcessorSpawnItem") },
    { Packet = ServerProtoNames.s2c_setPoisonCircle,  Processor = require("GameCorePacketProcessorChangePoisonCircleSetting") },
    { Packet = ServerProtoNames.s2c_resetDungeon,  Processor = require("GameCorePacketProcessorResetDungeon") },
    { Packet = ServerProtoNames.s2c_gameSpeed,  Processor = require("GameCorePacketProcessorToggleGameSpeed") },
    { Packet = ServerProtoNames.s2c_teleport,   Processor = require("GameCorePacketProcessorTeleport") },
    { Packet = ServerProtoNames.s2c_ping,   Processor = require("GameCorePacketProcessorPing") },
    { Packet = ServerProtoNames.s2c_execCmd,   Processor = require("GameCorePacketProcessorExecCmd") },
}

local tbCCSPacketProcessor = {
    { Packet = ServerProtoNames.GameStartResponse, Callback = "CCSSDK_GameStart" },
    { Packet = ServerProtoNames.GameStopResponse,  Callback = "CCSSDK_GameStop" },
    { Packet = ServerProtoNames.AgentCreateResponse,  Callback = "CCSSDK_AgentCreated" },
    { Packet = ServerProtoNames.AgentDestroyResponse,  Callback = "CCSSDK_AgentDestroyed" },
}


local function LOG(...)
    log("CJ->GameCoreProxyClient:", ...)
end

local function LOG_AI_SDK(...)
    log("ai sdk log:", ...)
end

local function BindProcesser(self, tbProcessor)
    for _,v in ipairs(tbProcessor) do
        local tbProcessorPackage = v.Processor
        if tbProcessorPackage then
            tbProcessorPackage:Init(v.Packet)
            local funcPacketPorcessor = function (tbPacket)
                tbProcessorPackage:Process(tbPacket)
            end
            self.Network:BindFunc(v.Packet, funcPacketPorcessor)
        else
            logerror("invalid game core proxy processor:",v.Packet)
        end
    end
end

local function BindCallback(self, tbCallbacks)
    for _,v in ipairs(tbCallbacks) do
        local cb = self[v.Callback]
        if cb then
            self.Network:BindMethod(v.Packet, self, cb)
        else
            logerror("invalid game core proxy callback ",v.Packet, v.Callback)
        end
    end
end

local function BindPacket(self)
    BindProcesser(self, tbPacketProcessor)
    BindCallback(self, tbCCSPacketProcessor)
    if GlobalVariableSystem.bAIGameCoreTrainingMode then
        BindProcesser(self, tbTrainingPacketProcessor)
    end
end

local function InitPoisonCirlce(self)
    local tbPoisonCirlce = {}
    tbPoisonCirlce.nState = 0
    tbPoisonCirlce.nNextX = 0
    tbPoisonCirlce.nNextY = 0
    tbPoisonCirlce.nNextRadius = 1000000
    tbPoisonCirlce.nCurrentRadius = 1000000
    tbPoisonCirlce.nCurrentX = 0
    tbPoisonCirlce.nCurrentY = 0
    tbPoisonCirlce.nTime = 0
    self.tbPoisonCirlce = tbPoisonCirlce
end

local function GetServerName()
    local szHost = ExtendBlueprintFunctions.GetHost(GWorld)
    local szPort = ExtendBlueprintFunctions.GetPort(GWorld)
    LOG("host and port ", szHost, szPort)
    if #szHost <= 0 then
        LOG_AI_SDK("can not get host.., try random number")
        return "fallback server " .. math.random(1, 10000000)
    else
        return szHost .. ":" .. szPort
    end

end

local function NotifyAISDKGameStart(self)
  --notify ai sdk game start
    local c2a_GameStartRequest = { }
    c2a_GameStartRequest.game_server_name = GetServerName()
    c2a_GameStartRequest.dungeon_id = tostring(BattleGameModeSystem.nDungeonId)
    c2a_GameStartRequest.max_agent = 100
    self:Send(Proto.GameStartRequest, c2a_GameStartRequest)
    LOG_AI_SDK("send game start:", c2a_GameStartRequest.game_server_name, c2a_GameStartRequest.dungeon_id)
end

local function NotifyAISDKGameEnd(self)
    if self.szCCSGameId then
        --notify ai sdk game stop
        local c2a_GameStopRequest = { }
        c2a_GameStopRequest.game_id = self.szCCSGameId
        self:Send(Proto.GameStopRequest, c2a_GameStopRequest)
        LOG_AI_SDK("send game end")
    end
end

local function NotifyAIAgentCreate(self, nServerInstanceId, nLevel, bHasRealPlayerTeammate)
    if self.szCCSGameId then
        --notify ai sdk game stop
        local c2a_AgentCreateRequest = { }
        local tbAgentList = { }
        table.insert(tbAgentList, {
            id = nServerInstanceId,
            level = nLevel or 0,
            style = Proto.AgentStyle.E_STYLE_NONE,
            has_real_player_ally = bHasRealPlayerTeammate,
        })
        c2a_AgentCreateRequest.game_id = self.szCCSGameId
        c2a_AgentCreateRequest.agent_list = tbAgentList
        self:Send(Proto.AgentCreateRequest, c2a_AgentCreateRequest)
        LOG_AI_SDK("send agent create ", nServerInstanceId, nLevel, bHasRealPlayerTeammate)
    end
end

local function NotifyAIAgentDestroy(self, nServerInstanceId)
    if self.szCCSGameId then
        --notify ai sdk game stop
        local c2a_AgentDestroyRequest = { }
        local tbIdList = { }
        table.insert(tbIdList, nServerInstanceId)
        c2a_AgentDestroyRequest.game_id = self.szCCSGameId
        c2a_AgentDestroyRequest.id_list = tbIdList
        self:Send(Proto.AgentDestroyRequest, c2a_AgentDestroyRequest)
        LOG_AI_SDK("send agent destroy ", nServerInstanceId)
    end
end

local function OnAgentDestroyed(self, tbAgent)
    for i,v in ipairs(self.tbAgents) do
        if v == tbAgent then
            NotifyAIAgentDestroy(self, tbAgent.tbAgent:GetServerInstanceId())
            break
        end
    end
end

local function OnAllPlayerLoginOut(self)
    NotifyAISDKGameEnd(self)
end

local function OnCreateAirDrop(self, tbBoxItem)
    table.insert(self.tbAirDrops, tbBoxItem)
    LOG("add air drop")
end

local function OnAirDropLanded(self, tbGameTrigger)
    local tbBoxItem = nil
    for i,v in ipairs(self.tbAirDrops) do
        if tbGameTrigger == v:GetSceneActor() then
            tbBoxItem = v
            break
        end
    end
    if tbBoxItem then
        for i,v in ipairs(self.tbAgents) do
            v:AddAirDrops(tbBoxItem)
        end
    end
end

function GameCoreProxyClient:InitNetwork(pGameCoreProxy)
    InitPoisonCirlce(self)
    self.Network = GameCoreProxyNetwork()
    self.Network:Init(pGameCoreProxy.GameCoreProxy)
    BindPacket(self)
    LOG("init network and bind event")
end


function GameCoreProxyClient:OnPoisonCircleInfo(rFFAPoisonCircleInfo)
    if self.bStarted then
        local POISONCIRCLE_WAIT = 1
        local POISONCIRCLE_SHRINK = 2
        --local POISONCIRCLE_FINISH = 3
        local tbPoisonCirlce = self.tbPoisonCirlce
        tbPoisonCirlce.nState = rFFAPoisonCircleInfo.nStageId
        tbPoisonCirlce.nNextX = rFFAPoisonCircleInfo.nNextX
        tbPoisonCirlce.nNextY = rFFAPoisonCircleInfo.nNextY
        tbPoisonCirlce.nNextRadius = rFFAPoisonCircleInfo.nNextRadius
        tbPoisonCirlce.nCurrentRadius = rFFAPoisonCircleInfo.nCurrentRadius
        tbPoisonCirlce.nCurrentX = rFFAPoisonCircleInfo.nCurrentX
        tbPoisonCirlce.nCurrentY = rFFAPoisonCircleInfo.nCurrentY
        Timer.StopOwnerTimer(self, SHRINK_TIMER)
        Timer.StopOwnerTimer(self, WAIT_TIMER)
        if rFFAPoisonCircleInfo.nStageId == POISONCIRCLE_SHRINK then
            local nCurrentShrinkTime = math.floor(rFFAPoisonCircleInfo.nShrinkEndTimeStamp - GlobalVariableSystem:GetLocalTime())
            tbPoisonCirlce.nTime = nCurrentShrinkTime
            tbPoisonCirlce.nTotolTime = nCurrentShrinkTime
            if nCurrentShrinkTime > 0 then
                Timer.StartOwnerTimer(self, SHRINK_TIMER, function()
                    self.tbPoisonCirlce.nTime = self.tbPoisonCirlce.nTime - 1
                    if self.tbPoisonCirlce.nTime <= 0 then
                        Timer.StopOwnerTimer(self, SHRINK_TIMER)
                    end
                end, 1, true )
            end
        elseif rFFAPoisonCircleInfo.nStageId == POISONCIRCLE_WAIT then
            local nCurrentWaitTime = math.floor(rFFAPoisonCircleInfo.nWaitEndTimeStamp - GlobalVariableSystem:GetLocalTime())
            tbPoisonCirlce.nTime = nCurrentWaitTime
            tbPoisonCirlce.nTotolTime = nCurrentWaitTime
            if nCurrentWaitTime > 0 then
                Timer.StartOwnerTimer(self, WAIT_TIMER, function()
                    self.tbPoisonCirlce.nTime = self.tbPoisonCirlce.nTime - 1
                    if self.tbPoisonCirlce.nTime <= 0 then
                        Timer.StopOwnerTimer(self, WAIT_TIMER)
                    end
                end, 1, true )
            end
        end
    end
end

function GameCoreProxyClient:GetPoisonCircleInfo(tbPacket)
    local tbPoisonCirlce = self.tbPoisonCirlce
    if tbPoisonCirlce then
        tbPacket.state = tbPoisonCirlce.nState
        tbPacket.next_x = tbPoisonCirlce.nNextX
        tbPacket.next_y = tbPoisonCirlce.nNextY
        tbPacket.next_radius = tbPoisonCirlce.nNextRadius
        tbPacket.cur_radius = tbPoisonCirlce.nCurrentRadius
        tbPacket.cur_x = tbPoisonCirlce.nCurrentX
        tbPacket.cur_y = tbPoisonCirlce.nCurrentY
        tbPacket.time = tbPoisonCirlce.nTime
        tbPacket.total_time = tbPoisonCirlce.nTotolTime
    end
end


function GameCoreProxyClient:EnableDebug(bEnable)
    if self.Network then
        self.Network:EnableDebug(bEnable)
    end
end

local function InitByCmdArgs(self)
    local szCommandLine = KismetSystemLibrary.GetCommandLine()
    local tbCmdArgs = StringUtil.Split(szCommandLine, " ")
    local szArgValue = ""
    for _,v in ipairs(tbCmdArgs) do
        if StringUtil.StartsWith(v, CMD_ARG_NAME) then
            szArgValue = string.sub(v, #CMD_ARG_NAME + 1, -1)
            break
        end
    end
    log("GameCoreProxyClient InitByCmdArgs: ", CMD_ARG_NAME, szArgValue)
    if szArgValue ~= "" then
        self.bAutoOpenDlAgent = true
        self.nDlAgentMin = tonumber(szArgValue)
        log("GameCoreProxyClient nDlAgentMin: ", self.nDlAgentMin)
    else
        self.bAutoOpenDlAgent = false
    end
end

function GameCoreProxyClient:OnBotTeamBattleEnd(tbPacket)
    for i,v in ipairs(tbPacket.FFATeamResult) do
        local tbAgent = self:GetAgent(v.nInstanceId)
        if tbAgent then
            v.nAIStyle = tbAgent.nStyle
            v.nAILevel = tbAgent.nAILevel
            v.nDeadStyle = tbAgent.nDeadTemplateType
            v.nDeadReason = tbAgent.nDeadReason
            LOG("add info in OnBotTeamBattleEnd:",v.nInstanceId, v.nAIStyle, v.nAILevel, v.nDeadStyle, v.nDeadReason)
        end
    end
    self:Send(Proto.c2s_notifyStatisticsData, tbPacket)
    log("[DEBUG OnBotTeamBattleEnd]", t2s(tbPacket))
end

function GameCoreProxyClient:Init()
    self.tbAgents = { }
    self.tbRealPlayers = { }
    self.tbAirDrops = { }
    self.tbFogData = { }
    self.bStarted = false
    self.nBTBotCount = 0
    self.SelfEventHelper = SelfEventHelperClass()
    self.SelfTimerHelper = SelfTimerHelperClass()
    if GlobalVariableSystem:IsDedicatedServer() then
        InitByCmdArgs(self)
        local SelfEventHelper = self.SelfEventHelper
        SelfEventHelper:RegisterEvent(CommonEventDef.EV_GAME_MODE_PRE_START_PLAY, self, self.GamePreStart)
        SelfEventHelper:RegisterEvent(CommonEventDef.EV_GAME_MODE_START_PLAY, self, self.GameStart)
        SelfEventHelper:RegisterEvent(CommonEventDef.EV_GAME_MODE_END_PLAY, self, self.GameEnd)
        SelfEventHelper:RegisterEvent(CommonEventDef.EV_FFA_TEAM_WIN, self, self.PlayerWin)
        SelfEventHelper:RegisterEvent(CommonEventDef.EV_FFA_POISONCIRCLE_INFO_CHANGED,  self, self.OnPoisonCircleInfo)
        SelfEventHelper:RegisterEvent(CommonEventDef.EV_BOT_TEAM_BATTLE_END, self, self.OnBotTeamBattleEnd)
    end
end


function GameCoreProxyClient:OnPoisonCircleInit(tbPoisonCircleData)
    if self.tbOverridePoisonCircleData then
        for i,v in ipairs(self.tbOverridePoisonCircleData) do
            local nPoisonCircleIndex = v.index
            local nX = v.x
            local nY = v.y
            local nRadius = v.radius
            local nShrinkTime = v.shrink_time
            local nWaitTime = v.wait_time
            local tbPoisonCircle = tbPoisonCircleData[nPoisonCircleIndex]
            if tbPoisonCircle then
                tbPoisonCircle.ShrinkTime = nShrinkTime
                tbPoisonCircle.Radius = nRadius
                tbPoisonCircle.WaitTime = nWaitTime
                local tbPoint = {}
                tbPoint.X = nX
                tbPoint.Y = nY
                tbPoint.Z = 0
                tbPoisonCircle.Transform = tbPoint
                if nPoisonCircleIndex ~= 1 then
                    tbPoisonCircleData[nPoisonCircleIndex - 1].NextTransform = tbPoint
                    tbPoisonCircleData[nPoisonCircleIndex - 1].NextRadius = nRadius
                end
            end
        end
    end
end

function GameCoreProxyClient:OnAIBattleLogicStart(tbGameObject, ...)
    local BotAISystem = dynamic_require("BotAISystem")
    if self:IsEnabled() and BotAISystem:IsBot(tbGameObject) then
        local GameCoreHelper = require("GameCoreHelper")
        local nLevel = GameCoreAgentLevel:GetAgentLevel(tbGameObject)
        LOG("agent ai level:", tbGameObject.szName, nLevel)
        GameCoreHelper:ChangeBotToDLAgent(tbGameObject, nLevel)
    end
end

function GameCoreProxyClient:OnPlayerLogin(tbGamePlayer)
    local BotAISystem = dynamic_require("BotAISystem")
    if self.bAutoOpenDlAgent and (not self.bEnterTransportStep) and (not BotAISystem:IsBot(tbGamePlayer)) then
        local tbObjects = GameObjectSystem:GetAllByObjectType(GameObjectTypeDef.PlayerSelf)
        local nPlayerSelfCount = 0
        for v, _ in pairs(tbObjects) do
            if not AIHelper.IsAIControlled(v) then
                nPlayerSelfCount = nPlayerSelfCount + 1
            end
        end
        log("GameCoreProxyClient:OnPlayerLogin", nPlayerSelfCount, self.nDlAgentMin)
        if nPlayerSelfCount >= self.nDlAgentMin then
            GlobalVariableSystem.EnableDLAgent = true
            log("GameCoreProxyClient:OnPlayerLogin DLAgent set true!" , nPlayerSelfCount, self.nDlAgentMin)
        else
            GlobalVariableSystem.EnableDLAgent = false
            log("GameCoreProxyClient:OnPlayerLogin DLAgent set false!", nPlayerSelfCount, self.nDlAgentMin)
        end
        self:NotifyGameCoreStateChanged()
    end
end

function GameCoreProxyClient:OnEnterTransportStep()
    self.bEnterTransportStep = true
    if not self:IsEnabled() then
        LOG("OnEnterTransportStep: GameCore is disabled.")
        self:GameEnd()
    end
end

function GameCoreProxyClient:OpenNetLog(bOpen)
    if self.Network then
        self.Network:OpenNetLog(bOpen)
    end
end

local function OnSpawnSmoke(self, pLocation, nRadius, nExistTime)
    local pSmokeManager = CommonShell.GetCommon(GWorld):GetAISmokeManager()
    if pSmokeManager then
        LOG("add smoke ",pLocation.X, pLocation.Y, pLocation.Z, nRadius, nExistTime)
        pSmokeManager:AddSmoke(pLocation, nRadius, nExistTime)
    end
end

local function OnSpawnFogTrigger(self, tbFogTrigger)
    self.tbFogData.trigger = tbFogTrigger
    LOG("spawn fog")
    self:UpdateFog()
    if self.tbFogUpdateTiemr then
        self.SelfTimerHelper:ClearTimer(self.tbFogUpdateTiemr)
        self.tbFogUpdateTiemr = nil
    end
    self.tbFogUpdateTiemr = self.SelfTimerHelper:NewTimerMethod(self, self.UpdateFog, 1, true)
end

local function OnSpawnTypeOver(self, nSpawnType)
    if nSpawnType == SpawnerDef.SpawnerType.ITEMDROP then
        self.bItemSpawned = true
        LOG("spawned item over, ready to go")
    end
end


function GameCoreProxyClient:UpdateFog()
    local tbTrigger = self.tbFogData.trigger
    if tbTrigger and tbTrigger.pUEActor then
        local X, Y, Z = tbTrigger:GetLocationXYZ()
        local nRadius = tbTrigger.nRadius
        local tbFogData = self.tbFogData
        tbFogData.x = X
        tbFogData.y = Y
        tbFogData.z = Z
        tbFogData.radius = nRadius
    end
end

function GameCoreProxyClient:GameStart()
    if GlobalVariableSystem:IsDedicatedServer() then
        local pGameCoreProxy = ServerShell.GetServer(GWorld):GetAIGameCoreProxy()
        if pGameCoreProxy:Start() then
            self:InitNetwork(pGameCoreProxy)
            GameCoreAgentDistribution:Init()
            GameCoreAgentLevel:InitStrategy(AGENT_LEVEL_STRATEGY)
            self.bStarted = true
            self.bEnterTransportStep = false
            AgentStatisticsSystem:Clear()
            if GlobalVariableSystem.bAIGameCoreTrainingMode then
                self:StartTraining()
            end
            local SelfEventHelper = self.SelfEventHelper
            SelfEventHelper:RegisterEvent(CommonEventDef.EV_POISONCIRCLE_DATA_INIT,  self, self.OnPoisonCircleInit)
            SelfEventHelper:RegisterEvent(CommonEventDef.EV_AI_BATTLELOGIC_START, self, self.OnAIBattleLogicStart)
            SelfEventHelper:RegisterEvent(CommonEventDef.EV_GAMECORE_AGENT_DESTROY, self, OnAgentDestroyed)
            SelfEventHelper:RegisterEvent(CommonEventDef.EV_GAME_MODE_PRE_ON_ALL_PLAYER_LOGOUT, self, OnAllPlayerLoginOut)
            SelfEventHelper:RegisterEvent(CommonEventDef.EV_GAME_MODE_ON_PLAYER_LOGIN, self, self.OnPlayerLogin)
            SelfEventHelper:RegisterEvent(CommonEventDef.EV_ENTER_TRANSPORT_STEP, self, self.OnEnterTransportStep)
            SelfEventHelper:RegisterEvent(CommonEventDef.EV_CREATE_AIRDROP_BOX, self, OnCreateAirDrop)
            SelfEventHelper:RegisterEvent(CommonEventDef.EV_FFA_AIRDROP_END, self, OnAirDropLanded)
            SelfEventHelper:RegisterEvent(CommonEventDef.EV_SPAWN_SMOKE, self, OnSpawnSmoke)
            SelfEventHelper:RegisterEvent(CommonEventDef.EV_SPAWN_FOG_TRIGGER, self, OnSpawnFogTrigger)
            SelfEventHelper:RegisterEvent(CommonEventDef.EV_SPAWN_TYPE_OVER , self, OnSpawnTypeOver)

            self.OnServerDeadDeleagte = SelfEventHelper:RegisterCppDelegate(pGameCoreProxy.GameCoreProxy.OnServerDead, self, self.OnServerDead)

            self.nAISdkStartTimer = DelayTimer:DelayRun(function()
                self.nAISdkStartTimer = nil
                NotifyAISDKGameStart(self)
            end, 1)

            self.bItemSpawned = false
            LOG("GameCoreProxyClient->start")
        end
    end
end

function GameCoreProxyClient:GamePreStart()
    if GlobalVariableSystem:IsDedicatedServer() then
        local pGameCoreProxy = ServerShell.GetServer(GWorld):GetAIGameCoreProxy()
        if pGameCoreProxy:Enabled() then
            GlobalVariableSystem.bEnableAIGameCore = true
            GlobalVariableSystem.bAIGameCoreTrainingMode = pGameCoreProxy:TrainingMode()
            if GlobalVariableSystem.bAIGameCoreTrainingMode then
                local bSpawnNpc = ExtendBlueprintFunctions.HasCommandLineParam("spawnnpc")
                LOG("bSpawnNpc:", bSpawnNpc)
                local BattleBlackboard = require("BattleBlackboard")
                if not bSpawnNpc then
                    BattleBlackboard:SetBool("INTER_GM_Ignore_Spawn_Npc", true)
                end
                BattleBlackboard:SetBool("INTER_GM_Ignore_Spawn_Bot", true)
            end
            LOG("GameCoreProxyClient->pre start")
        end
    end
end

function GameCoreProxyClient:Possess(tbGameObject, nLevel)
    local tbAgent = require("GameCoreBotAgent")()
    tbAgent:Init()
    local nNumAgent = #self.tbAgents
    local nId = nNumAgent + 1
    table.insert(self.tbAgents, tbAgent)
    if not tbAgent:Possessed(nId, tbGameObject) then
        logerror("change to agent fail...", tbGameObject.szMapName, nId)
    else
        local bHasRealPlayerTeammate = AIHelper:HasRealPlayerTeammate(tbGameObject)
        NotifyAIAgentCreate(self, tbAgent.tbAgent:GetServerInstanceId(), nLevel, bHasRealPlayerTeammate)
    end
end

local function ClearBots(self)
    for i,v in ipairs(self.tbAgents) do
        v:Destroy()
    end
    self.tbAgents = { }
    for i,v in ipairs(self.tbRealPlayers) do
        v:Destroy()
    end
    self.tbRealPlayers = { }
end


function GameCoreProxyClient:OnServerDead()
    LOG("server dead.")
    -- ai server is dead. let bebavior tree controls bot
    if not GlobalVariableSystem.bAIGameCoreTrainingMode then
        GlobalVariableSystem.bEnableAIGameCore = false
        GameCoreAgentDistribution:Reset()
        for _,v in ipairs(self.tbAgents) do
            v:ShowName(false)
            local tbGameObject = v:GetGameObject()
            if tbGameObject:IsAlive() then
                local AIComponent = tbGameObject.SAIComponent
                AIComponent:StopAI()
                AIComponent:StartAI()
                AIComponent:SetAutoStartAI(true)
            end
        end
        ClearBots(self)
    end
end

function GameCoreProxyClient:GameEnd()
    GameCoreAgentDistribution:UnInit()
    if GlobalVariableSystem:IsDedicatedServer() then
        self.SelfTimerHelper:ClearAllTimer()
        if self.nAISdkStartTimer then
            self.nAISdkStartTimer:Clear()
            self.nAISdkStartTimer = nil
        end
        if self.bStarted then
            NotifyAISDKGameEnd(self)
            local pGameCoreProxy = ServerShell.GetServer(GWorld):GetAIGameCoreProxy()
            pGameCoreProxy:Stop()
            self.bStarted = false
            self.szCCSGameId = nil
            ClearBots(self)
            GameCoreAgentLevel:Uninit()
            local SelfEventHelper = self.SelfEventHelper
            SelfEventHelper:UnregisterCppDelegate(self.OnServerDeadDeleagte)
            SelfEventHelper:UnregisterEvent(CommonEventDef.EV_POISONCIRCLE_DATA_INIT)
            SelfEventHelper:UnregisterEvent(CommonEventDef.EV_AI_BATTLELOGIC_START)
            SelfEventHelper:UnregisterEvent(CommonEventDef.EV_GAMECORE_AGENT_DESTROY)
            SelfEventHelper:UnregisterEvent(CommonEventDef.EV_GAME_MODE_PRE_ON_ALL_PLAYER_LOGOUT)
            SelfEventHelper:UnregisterEvent(CommonEventDef.EV_GAME_MODE_ON_PLAYER_LOGIN)
            SelfEventHelper:UnregisterEvent(CommonEventDef.EV_ENTER_TRANSPORT_STEP)
            SelfEventHelper:UnregisterEvent(CommonEventDef.EV_CREATE_AIRDROP_BOX)
            SelfEventHelper:UnregisterEvent(CommonEventDef.EV_FFA_AIRDROP_END)
            SelfEventHelper:UnregisterEvent(CommonEventDef.EV_SPAWN_SMOKE)
            SelfEventHelper:UnregisterEvent(CommonEventDef.EV_SPAWN_FOG_TRIGGER)
            SelfEventHelper:UnregisterEvent(CommonEventDef.EV_SPAWN_TYPE_OVER)
            LOG("GameCoreProxyClient->end")
        end
    end
end


function GameCoreProxyClient:PlayerWin(nTeamId)
    if self.Network and self.bStarted and self.szCCSGameId then
        local tbPacket = { }
        local tbWinners = { }
        local tbWinerMembers = BattleTeamSystem:GetTeamMembers(nTeamId)
        for _, tbWinnerPlayer in ipairs(tbWinerMembers) do
            if not tbWinnerPlayer:IsDead() then
                table.insert(tbWinners, tbWinnerPlayer.nServerInstanceId)
            end
        end
        tbPacket.winners = tbWinners
        self:Send(Proto.c2s_gameFinish, tbPacket)

        NotifyAISDKGameEnd(self)
    end
end



function GameCoreProxyClient:Uninit()
    if self.SelfEventHelper then
        self.SelfEventHelper:UnregisterAll()
        self.SelfEventHelper = nil
    end
    if self.SelfTimerHelper then
        self.SelfTimerHelper:ClearAllTimer()
        self.SelfTimerHelper = nil
    end
    Timer.StopOwnerTimer(self, SHRINK_TIMER)
    Timer.StopOwnerTimer(self, WAIT_TIMER)
    ClearBots(self)
    if self.Network then
        self.Network:Uninit()
        self.Network = nil
    end
    self.tbAgents = { }
    self.tbOverridePoisonCircleData = nil
end

function GameCoreProxyClient:Send(szPacketType, tbPacket)
    if self.Network then
        self.Network:SendPacket(szPacketType, tbPacket)
    end
end

local function SetBoolValue(tbKeyName, bValue)
    local BattleBlackboard = require("BattleBlackboard")
    if BattleBlackboard:IsDefined(tbKeyName) then
        BattleBlackboard:SetBool(tbKeyName ,bValue)
    end
end

function GameCoreProxyClient:IsAgent(tbGameObject)
    for _,v in ipairs(self.tbAgents) do
        if v.tbAgent == tbGameObject then
            return true
        end
    end
    return false
end

function GameCoreProxyClient:StartTraining()
    self.szCCSGameId = "TrainingServer"
    if BattleGameModeSystem:GetGameMode().Setting then
        BattleGameModeSystem:GetGameMode().Setting.bNeverCheckLoginOut = true
    end

    SetBoolValue("SkipFFAWaitTime", true)
    SetBoolValue("SkipFFASelectionPoint", true)
    SetBoolValue("SkipPlayFFAMatinee", true)
    self.bSendFPS = ExtendBlueprintFunctions.HasCommandLineParam("fps")
end

function GameCoreProxyClient:GetCCSGameId()
    return self.szCCSGameId or ""
end

function GameCoreProxyClient:SyncRealPlayer(tbGameObject)
    if not self:IsEnabled() then
        return
    end
    for i,v in ipairs(self.tbRealPlayers) do
        if v:GetGameObject() == tbGameObject then
            return
        end
    end
    LOG("sync real player:", tbGameObject.szName)
    local tbGameCoreRealPlayer = require("GameCoreRealPlayer")()
    table.insert(self.tbRealPlayers, tbGameCoreRealPlayer)
    tbGameCoreRealPlayer:Create(tbGameObject)
end

function GameCoreProxyClient:IsEnabled()
    return GlobalVariableSystem.bEnableAIGameCore and GlobalVariableSystem.EnableDLAgent and self.szCCSGameId
end
------------------------------------------------------------------------------------------------
local function LogCCSResponse(tbPacket, nPacketID)
    if tbPacket.result.code ~= ServerProtoNames.OperationResultCode.E_RESULT_OK then
        LOG_AI_SDK("recieved error from ccs ai sdk: ", tbPacket.result.code, tbPacket.result.msg, nPacketID)
    end
end

function GameCoreProxyClient:CCSSDK_GameStart(tbPacket, _, nPacketID)
    LogCCSResponse(tbPacket, nPacketID)
    if tbPacket.result.code == ServerProtoNames.OperationResultCode.E_RESULT_OK then
        self.szCCSGameId = (tbPacket.game_id)
        LOG_AI_SDK("recv game start -> ", self.szCCSGameId)
    elseif tbPacket.result.code == ServerProtoNames.OperationResultCode.E_RESULT_TIMEOUT then   -- timeout
        NotifyAISDKGameStart(self)
        LOG_AI_SDK("timeout resend game start")
    elseif tbPacket.result.code == ServerProtoNames.OperationResultCode.E_RESULT_OVERLOAD then   -- ai server is too busy
        LOG_AI_SDK("recv game start too busy")
    end
    self:NotifyGameCoreStateChanged()
end

function GameCoreProxyClient:NotifyGameCoreStateChanged()
    EventManager:OnFireEvent(CommonEventDef.EV_GAMECORE_STATUS_CHANGED, self:IsEnabled())
end

function GameCoreProxyClient:CCSSDK_GameStop(tbPacket, _, nPacketID)
    LogCCSResponse(tbPacket, nPacketID)
    LOG_AI_SDK("recv game stop", tbPacket.result.msg)
end

function GameCoreProxyClient:CCSSDK_AgentCreated(tbPacket, _, nPacketID)
    LogCCSResponse(tbPacket, nPacketID)
    if tbPacket.agent_list then
        for i,v in ipairs(tbPacket.agent_list) do
            local tbAgent = self:GetAgent(v.id)
            tbAgent:SetAIStyle(v.style)
            tbAgent:SetAILevel(v.level)
        end
    end
    LOG_AI_SDK("recv agent create ", tbPacket.result.msg)
end

function GameCoreProxyClient:CCSSDK_AgentDestroyed(tbPacket, _, nPacketID)
    LogCCSResponse(tbPacket, nPacketID)
    LOG_AI_SDK("recv agent destroy ",tbPacket.result.msg)
end
------------------------------------------------------------------------------------------------
function GameCoreProxyClient:AddBot(X, Y, Z, nTeamid, bAutoTeleport, nLevel)
    local tbAgent = require("GameCoreBotAgent")()
    tbAgent:Init()
    local nNumAgent = #self.tbAgents
    local nId = nNumAgent + 1
    table.insert(self.tbAgents, tbAgent)
    if not tbAgent:Create(nId, X, Y, Z, nTeamid, bAutoTeleport) then
        logerror("create bot agent fail...", nId)
    else
        local bHasRealPlayerTeammate = AIHelper:HasRealPlayerTeammate(tbAgent:GetGameObject())
        NotifyAIAgentCreate(self, tbAgent.tbAgent:GetServerInstanceId(), nLevel, bHasRealPlayerTeammate)
    end
end

function GameCoreProxyClient:GetAgent(nServerInstanceId)
    for i,v in ipairs(self.tbAgents) do
        if v.tbAgent.nServerInstanceId == nServerInstanceId then
            return v
        end
    end
    log("try to get agent but fail ", nServerInstanceId)
end

function GameCoreProxyClient:SetSyncInterval(nInterval)
    if self.bStarted and self.nTickInterval ~= nInterval then
        self.nTickInterval = math.max(0.01, nInterval)
        for i,v in ipairs(self.tbAgents) do
            v:EndTick()
            v:StartTick()
        end
        LOG("set interval to ", self.nTickInterval)
    end
end

function GameCoreProxyClient:ChangePoisonCircleSetting(tbPoisonCircleSetting)
    if tbPoisonCircleSetting.index > 0 then
        self.tbOverridePoisonCircleData = self.tbOverridePoisonCircleData or {}
        local tbNewPoisonCircleData = { }
        tbNewPoisonCircleData.index = tbPoisonCircleSetting.index
        tbNewPoisonCircleData.x = tbPoisonCircleSetting.x
        tbNewPoisonCircleData.y = tbPoisonCircleSetting.y
        tbNewPoisonCircleData.radius = tbPoisonCircleSetting.radius
        tbNewPoisonCircleData.shrink_time = tbPoisonCircleSetting.shrink_time
        tbNewPoisonCircleData.wait_time = tbPoisonCircleSetting.wait_time
        table.insert( self.tbOverridePoisonCircleData, tbNewPoisonCircleData )
    else
        SetBoolValue("GMCancelPoisonCircleStartTime" ,true)
    end
end

function GameCoreProxyClient:ResetDungeon()
    local tbGameMode = BattleGameModeSystem:GetGameMode()
    if tbGameMode then
        tbGameMode:OnAllPlayerLogoutWithEvent()
    end
end

function GameCoreProxyClient:ToggleGameSpeed(nSpeed)
    self.nRunningSpeed = nSpeed
    GameplayStatics.SetGlobalTimeDilation(GWorld, nSpeed)
end


return GameCoreProxyClient()
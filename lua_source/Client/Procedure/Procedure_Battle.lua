local luaclass = require("luaclass")
local ProcedureBase = require("ProcedureBase")
local Procedure_Battle = luaclass("Procedure_Battle", ProcedureBase)

local SelfEventHelper = require("SelfEventHelper")()
local ClientEventDef = require("ClientEventDef")
--local UIDef = require("UIDef")
local UIManager = require("UIManager")
local ManagerRoot = require("ManagerRoot")
local ManagerGroupDef = require("ManagerGroupDef")
local LoadingSystem = require("LoadingSystem")
local SoundManager = require("SoundManager")
local GlobalVariableSystem = require("GlobalVariableSystem_C")
local EventManager = require("EventManager")
local GameObjectSystem = require("GameObjectSystem_C")
local GameWorldSystem = require("GameWorldSystem")
local BattleGameModeSystem = dynamic_require("BattleGameModeSystem")
local DelayTimer = require("DelayTimer")
local Timer = require("Timer")
local NetworkManager = require("NetworkManager_C")
local PrepareLocalDungeonDataHelper = require("PrepareLocalDungeonDataHelper")
local BGMHelper = require("BGMHelper")
local Proto = require("ClientProtoNames")
local GamePlayerSelfHelper = require("GamePlayerSelfHelper")
-- local HandlerManagerHelper = require("HandlerManagerHelper")
local UIStateDef = require("UIStateDef")
local ChannelSDKSystem = require("ChannelSDKSystem")

local UninitCheckSystem = require("UninitCheckSystem")
local ProcedureTool = require("ProcedureTool")
local UEClientActorHelper = require("UEClientActorHelper")
local UIDef = require("UIDef")
local ReconnectIni = require("ReconnectIni")

local EMPTY_STEP_DELAY_TIME = 0.5

Procedure_Battle.bEnterFailed = false
Procedure_Battle.WaitEvent = nil
Procedure_Battle.tbRecieveEvent = {}
Procedure_Battle.EmptyStepTimer = nil

-- 进入超时的处理
local function DestroyWaitListner(self)
    if(self.EnterTimer) then
        DelayTimer:ClearTimer(self.EnterTimer)
        self.EnterTimer = nil
    end
    SelfEventHelper:UnregisterEvent(ClientEventDef.EV_BATTLE_DISCONNECTED)
end

local function ClearEmptyStepTimer(self)
    if self.EmptyStepTimer then
        DelayTimer:ClearTimer(self.EmptyStepTimer)
        self.EmptyStepTimer = nil
    end
end

local function DisconnectFromDungeon(self)
    log("Procedure_Battle,DisconnectFromDungeon,EnterWildWorld")
    self.bEnterFailed = true
    NetworkManager:GetHubServerProxy():SendPacket(Proto.c2s_TravelDungeonFailed)
    ClientShell.GetClient(GWorld):GetDungeonShell():DisconnectFromDungeonServer(false)
    LoadingSystem:ClearSteps()

    -- ProcedureTool:EnterWildWorld(nil, "OnDisconnectTimeout",
    --     nil, nil, false, nil, true)
    ProcedureTool:EnterLobby()
end

local function CreateWaitListner(self)
    self.EnterTimer = DelayTimer:DelayRun(function()
        self.EnterTimer = nil
        DestroyWaitListner(self)
        -- 进入超时了，发包给服务器
        log("Procedure_Battle,Dungeon enter time out")
        DisconnectFromDungeon(self)
    end, GlobalVariableSystem.DungeonEnterMaxWaitTime)
end

local function OpenUI(self)
    local Param = {
            nDungeonId = self.Param.nDungeonId
        }
    UIManager:PushState(UIStateDef.StateName.UI_BATTLE_STATE, Param, true)
    --HandlerManagerHelper:SwitchMode(Enum_HandlerMode.ShipCommonMode)
    BGMHelper:PlayDungeonBGM(BattleGameModeSystem.nDungeonId)
end

--loading step
local function WaitEnterDungeonStep(self, bReceivedEvent, szTargetIP, nToken, nPlayerId, nDungeonId, szPlayerName, szDungeonSessionId, nEncryptionSeed)
    log("Procedure_Battle WaitEnterDungeonStep, bReceivedEvent=", bReceivedEvent, szTargetIP, nToken, nPlayerId, nDungeonId, szPlayerName, szDungeonSessionId, nEncryptionSeed)
    if bReceivedEvent then
        DestroyWaitListner(self)
        local tbParam = self.Param
        if szTargetIP and nToken and nPlayerId then
            tbParam.szTargetIp = szTargetIP
            tbParam.nToken = nToken
            tbParam.nPlayerId = nPlayerId
            tbParam.szPlayerName = szPlayerName
            tbParam.szDungeonSessionId = szDungeonSessionId
            tbParam.nEncryptionSeed = nEncryptionSeed
            BattleGameModeSystem:SetDungeonId(tbParam.nDungeonId)
            BattleGameModeSystem:SetDungeonSessionId(tbParam.szDungeonSessionId)
        end
        LoadingSystem:StepNext(tbParam.bQuickBattleLoading)
    else
        CreateWaitListner(self)
    end
end

local function WaitReplicationCRCChecked(self, bReceivedEvent)
    if(bReceivedEvent) then
        LoadingSystem:StepNext(self.Param.bQuickBattleLoading)
    end
end

local function TryEnterDungeonStep(self, bReceivedEvent)
    log("Procedure_Battle TryEnterDungeonStep, bReceivedEvent=", bReceivedEvent)

    if bReceivedEvent then
        DestroyWaitListner(self)
        OpenUI(self)
        LoadingSystem:StepNext(self.Param.bQuickBattleLoading)
    else
        CreateWaitListner(self)
        -- if not self.Param.bRetraveling then
            self:ClientTravel()
        -- end
    end
end

local function ProcessPendingPacketOffStep(self)
    -- 因为pending的packet里可能还包含切场景，所以必须要让整个loading过程完成，所以必须在loading结束后再pending false
    -- log("Procedure_Battle ProcessPendingPacket set pending true")
    -- clienttravel过程中收到S2C_LeaveDungeon因为pending所以没有处理，导致必须等180秒后才能返回大厅
    -- NetworkManager:SetPending(true)
    if NetworkManager.RPCNetworkProxy then
        log("Procedure_Battle set rpc pending true")
        NetworkManager.RPCNetworkProxy:SetPending(true)
    end
    log("ProcessPendingPacketOffStep", self.Param.bQuickBattleLoading)
    LoadingSystem:StepNext(self.Param.bQuickBattleLoading)

end

local function ProcessPendingPacketOnStep(self)
    -- 因为pending的packet里可能还包含切场景，所以必须要让整个loading过程完成，所以必须在loading结束后再pending false
    -- log("Procedure_Battle ProcessPendingPacket set pending false")
    -- NetworkManager:SetPending(false)
    if NetworkManager.RPCNetworkProxy then
        log("Procedure_Battle set rpc pending false")
        NetworkManager.RPCNetworkProxy:SetPending(false)
    end

    LoadingSystem:StepNext(self.Param.bQuickBattleLoading)
end

local function WaitingAllTeamMemberEnterStep(self, bReceivedEvent)
    log("Procedure_Battle WaitingAllTeamMemberEnterStep, bReceivedEvent=", bReceivedEvent)
    if bReceivedEvent then
        SelfEventHelper:UnregisterEvent(ClientEventDef.EV_GAME_STATE_ON_RECV_TEAM_INFOS)
        LoadingSystem:StepNext()    -- 万一与ds断线，那么下一帧在处理
    end
end

-- 如果进入失败，那么不关loading，等服务器回包处理
local function CheckEnterFailedStep(self, bRecieveEvent)
    log("Procedure_Battle CheckEnterFailedStep, bRecieveEvent=", bRecieveEvent)
    if bRecieveEvent then
        DestroyWaitListner(self)
        -- 进入超时了，发包给服务器
        DisconnectFromDungeon(self)
    elseif not self.bEnterFailed then
        LoadingSystem:StepNext(self.Param.bQuickBattleLoading)
    end
end
-- local CheckStandOnFloor = nil
-- local function OnUEMovementChanged(self, pUEActor, PrevMovementMode, PrevCustomMode)
--     CheckStandOnFloor(self)
-- end

-- function CheckStandOnFloor(self)
--     local PlayerSelf = GamePlayerSelfHelper:Get()
--     local CurrentMovementMode = PlayerSelf.pUEActor.CharacterMovement.MovementMode
--     if CurrentMovementMode ~= EMovementMode.MOVE_Falling then
--         if self.MovementChanged then
--             SelfEventHelper:UnregisterCppDelegate(self.MovementChanged)
--             self.MovementChanged = nil
--         end
--         LoadingSystem:StepNext()
--     elseif not self.MovementChanged then
--         DelayTimer:DelayRun(function()
--             LoadingSystem:StepNext()
--         end, 10)
--         self.MovementChanged = SelfEventHelper:RegisterCppDelegate(PlayerSelf.pUEActor.MovementModeChangedDelegate, self, OnUEMovementChanged)
--     end
-- end

local function ClosePreOpenUI(self)
    UIManager:CloseWnd(UIDef.UI_WORLD_MAP)
    UIManager:CloseWnd(UIDef.UI_PICKUP_ITEM)
    UIManager:CloseWnd(UIDef.UI_PICKUP_BOX)

    if GlobalVariableSystem:IsInTrainingCamp(BattleGameModeSystem.nDungeonId)
        or GlobalVariableSystem:IsStandaloneServer() then
        UIManager:CloseWnd(UIDef.UI_FFA_SELECT_BORNPOINT)
    end

    -- 恢复timeout时间
    ClientShell.GetClient(GWorld):SetClientConnectionTimeOut(ReconnectIni.nDungeonDefaultSendReconnectInfoTime)
    LoadingSystem:StepNext(true)
end

local function WaitEmptyStep(self)
    log("Procedure_Battle WaitEmptyStep")
    self.EmptyStepTimer = DelayTimer:DelayRun(function() LoadingSystem:StepNext(true) end, EMPTY_STEP_DELAY_TIME)
end

local function WaitLoadingAnim(self, bRecieveEvent, szUIName, szAnimName)
    log("Procedure_Battle WaitLoadingAnim:bRecieveEvent, szUIName, szAnimName=",bRecieveEvent, szUIName, szAnimName)
    if bRecieveEvent and szUIName == UIDef.UI_LOADING  and szAnimName == "animBGChangeIn" then
        LoadingSystem:StepNext(true)
    end
end

local function RegisterLoadStep(self, StepMethod, Event)
    local tbEventParam = {}
    if Event then
        SelfEventHelper:RegisterEventFunc(Event, function(...)
            self.tbRecieveEvent[Event] = true
            tbEventParam = {...}
            if self.WaitEvent == Event then
                StepMethod(self, true, ...)
            end
        end)
    end

    LoadingSystem:AddStepMethod(self, function()
        self.WaitEvent = Event
        StepMethod(self, Event == nil or self.tbRecieveEvent[Event] == true, table.unpack(tbEventParam))
    end)
end

local function PrepareLoading(self)
    LoadingSystem:ClearSteps()

    local tbParam = self.Param
    local bQuickLoading = tbParam.bQuickBattleLoading

    -- 等待loading上动效播放完成，暂时没用
    if tbParam.bWaitLoadingReady then
        RegisterLoadStep(self, WaitLoadingAnim,                 ClientEventDef.EV_UI_ANIMATION_END)
    end

    if(not tbParam.bStandalone) then
        -- 联网本
        if(not bQuickLoading) then
            RegisterLoadStep(self, WaitEnterDungeonStep,            ClientEventDef.EV_ENTER_DUNGEON)
        end
        RegisterLoadStep(self, ProcessPendingPacketOffStep)
        RegisterLoadStep(self, TryEnterDungeonStep,                 ClientEventDef.EV_PLAYERSELF_READY)
        RegisterLoadStep(self, ProcessPendingPacketOnStep)
        RegisterLoadStep(self, WaitReplicationCRCChecked,           ClientEventDef.EV_REPLICATION_CRC_CHECK_SUCCESS)
        RegisterLoadStep(self, WaitingAllTeamMemberEnterStep,       ClientEventDef.EV_GAME_STATE_ON_RECV_TEAM_INFOS)
        RegisterLoadStep(self, CheckEnterFailedStep,                ClientEventDef.EV_BATTLE_DISCONNECTED)
    else
        -- 单机本
        if(not bQuickLoading) then
            RegisterLoadStep(self, WaitEmptyStep)
        end
        RegisterLoadStep(self, ProcessPendingPacketOffStep)
        RegisterLoadStep(self, TryEnterDungeonStep,                 ClientEventDef.EV_PLAYERSELF_READY)
        RegisterLoadStep(self, ProcessPendingPacketOnStep)
    end
    RegisterLoadStep(self, ClosePreOpenUI)
    if(not bQuickLoading) then
        --空的step，等loading条走完再关
        RegisterLoadStep(self, WaitEmptyStep)
    end
    -- RegisterLoadStep(self, CheckStandOnFloor)

    LoadingSystem:Start(tbParam, true, true, tbParam.szLoadingWnd)
end

function Procedure_Battle:Begin()
    Procedure_Battle.super.Begin(self)

    -- 延长超时时间防止loading过慢
    ClientShell.GetClient(GWorld):SetClientConnectionTimeOut(ReconnectIni.nDungeonLoadingSendReconnectInfoTime)

    GlobalVariableSystem:SetEnterDungeonTime(GlobalVariableSystem:GetServerTimeUtc())

    local tbParam = self.Param
    self.bEnterFailed = false
    self.tbRecieveEvent = {}
    self.WaitEvent = nil
    GlobalVariableSystem:SetInDungeon(true)
    GlobalVariableSystem:SetStandalone(tbParam.bStandalone or false)
    ClientShell.GetClient(GWorld):SetGameStatus(GlobalVariableSystem:IsStandalone()
        and EPiratesGameStatus.BATTLE_STANDALONE or EPiratesGameStatus.BATTLE_CLIENT)

    if(tbParam.bStandalone) then
        -- 单机本的playerself创建走gamemode createPlayerSelf
        PrepareLocalDungeonDataHelper:PrepareLocalDungeonData(tbParam)
    else
        GameObjectSystem:RestorePlayerSelfObject(true, -1000)
        GamePlayerSelfHelper:Get():OnEnterBattle()
    end

    ManagerRoot:InitGroup(ManagerGroupDef.nBattleGroupID)
    BattleGameModeSystem:SetDungeonId(tbParam.nDungeonId)
    BattleGameModeSystem:SetDungeonSessionId(tbParam.szDungeonSessionId)
    CommonShell.GetCommon(GWorld):GetInputManager():CloseGestureSelfTouchListen()
    EventManager:OnFireEvent(ClientEventDef.EV_ENTER_PROCEDURE_BATTLE, tbParam.bRetraveling, tbParam.bStandalone)
    PrepareLoading(self)
end

function Procedure_Battle:End(tbParams)
    -- 关闭移动端虚拟键盘
    ExtendBlueprintFunctions.HideVirtualKeyboard()
    GlobalVariableSystem:SetEnterDungeonTime(nil)
    -- 防止进行了ProcessPendingPacketOffStep 但是没进行ProcessPendingPacketOnStep 就切procedure了
    log("Procedure_Battle End set pending false")
    NetworkManager:ClearRPCPendingPackets()
    NetworkManager:SetPending(false)
    local bRetraveling = false

    if tbParams then
        bRetraveling = tbParams.bRetraveling
    end
    EventManager:OnFireEvent(ClientEventDef.EV_LEAVE_PROCEDURE_BATTLE, bRetraveling)
    CommonShell.GetCommon(GWorld):GetInputManager():OpenGestureSelfTouchListen()

    UIManager:PopAllState()

    DestroyWaitListner(self)
    GameObjectSystem:DestroyAll()
    GameWorldSystem:DestroyWorld()
    SoundManager:StopBackgroundMusic()
    SelfEventHelper:UnregisterAll()

    ManagerRoot:UninitGroup(ManagerGroupDef.nBattleGroupID)
    BattleGameModeSystem:SetDungeonId(nil)
	BattleGameModeSystem:SetDungeonSessionId(nil)
    GlobalVariableSystem:SetInDungeon(false)
    GlobalVariableSystem:SetStandalone(true)
    UEClientActorHelper:ClearAllObjectVisibleFactors()

    -- 检查并清理timer
    Timer.CheckAndClearAllTimer()

    UninitCheckSystem:ExecCheck()
    LoadingSystem:ClearSteps()

    GlobalVariableSystem.nDungeonToken = -1
    GlobalVariableSystem.szLastTravelParam = nil
    GlobalVariableSystem.bCancelMerge = false

    KismetSystemLibrary.ExecuteConsoleCommand(GWorld, "xsj.usepawnlocforwc 1", nil)

    ClientShell.GetClient(GWorld):SetGameStatus(EPiratesGameStatus.NONE)
    Procedure_Battle.super.End(self)
end

function Procedure_Battle:Uninit()
    SelfEventHelper:UnregisterAll()
    DestroyWaitListner(self)
    ClearEmptyStepTimer(self)
    Procedure_Battle.super.Uninit(self)
end

function Procedure_Battle:ClientTravel()
    local tbParam = self.Param

    local szParams = ""

    if tbParam.bRetraveling then
        szParams = tbParam.szLastTravelParam
    else
        szParams = tbParam.szTargetIp
        -- This player id should be the id assigned by dungeon rather than hub playerId.
        -- Dungeon has already built the relationship between
        -- dungeon player id and hubserver player id in player prepare phase
        if tbParam.nPlayerId ~= nil then
            szParams = szParams .. "?PlayerID=".. tbParam.nPlayerId
        end
        if tbParam.nToken ~= nil then
            szParams = szParams .. "?GameToken=".. tbParam.nToken
        end
        if(tbParam.nDungeonId ~= nil) then
            szParams = szParams .. "?DungeonId=" .. tbParam.nDungeonId
        end
        if tbParam.szPlayerName ~= nil then
            szParams = szParams .. "?PlayerName=" .. tbParam.szPlayerName
        end
        local szVersion = GlobalVariableSystem:GetResVersion()
        local ePlatform = ChannelSDKSystem:GetProtoPlatformEnum()
        if tonumber(szVersion) == 0 then
            log("version is 0 ")
        elseif szVersion ~= nil then
            szParams = szParams .. "?Version=" .. szVersion .. "?Platform=" .. ePlatform
        end
    end

    -- 必须在travel前设置
    local nEncryptionSeed = tbParam.nEncryptionSeed
    NetworkManager:GetRPCNetworkProxy():SetPacketEncryptionEnabled(nEncryptionSeed ~= nil and nEncryptionSeed ~= 0, nEncryptionSeed or 0)

    log("TravelToServerMap "..szParams)
    ClientShell.GetClient(GWorld):ClientTravel(szParams, false)

    GlobalVariableSystem.nDungeonToken = tbParam.nToken
    GlobalVariableSystem.szLastTravelParam = szParams
end

return Procedure_Battle

local BattleGameModeSystem = dynamic_require("BattleGameModeSystem")
local ParachutingNewIni = require("ParachutingNewIni")
local TransporterDataTable = require("TransporterDataTable")
local GameObjectSystem = dynamic_require("GameObjectSystem")
local EventManager = require("EventManager")
local CommonEventDef = require("CommonEventDef")
local GameObjectTypeDef = require("GameObjectTypeDef")
local GlobalVariableSystem = dynamic_require("GlobalVariableSystem")
local Timer = require("Timer")
-- local BattleBlackboard = require("BattleBlackboard")
local ProtoDR = require("DungeonRepProtoNames")
local DelayTimer = require("DelayTimer")
local AIHelper = require("AIHelper")

local szTransporterTag = "Transporter"
local LAUNCH_BOT_INTERVAL = 0.2
local LAUNCH_TIME_DIFFERENCE = 15
local LAUNCH_BOT_COUNT_PER = 1
local LAUNCH_PLAYER_TIME = 3

local SelectionPointHelper
local BattleTransporterHelper = {}

BattleTransporterHelper.tbGroups = nil
BattleTransporterHelper.tbLaunchBots   = nil
BattleTransporterHelper.tbTransporters = nil

BattleTransporterHelper.tbLaunchBotsTimer = nil
BattleTransporterHelper.tbDelayLaunchTimer= nil
BattleTransporterHelper.nDelayLauchTime   = nil
BattleTransporterHelper.pBotBornLocation  = nil

--GM跳过跳伞
BattleTransporterHelper.tbGMSkipParachutePlayers = nil
BattleTransporterHelper.tbGMSkipTimer            = nil

local function ForceChangeToHuman()
    local tbObjects = GameObjectSystem:GetAllByObjectType(GameObjectTypeDef.PlayerSelf)
    for Object, _ in pairs(tbObjects) do
        if Object:IsShip() then
            local nHumanId = Object.tbPrepareInfo.nHumanId
            local tbTransform = {}
            tbTransform.X = Object.Location.X
            tbTransform.Y = Object.Location.Y
            tbTransform.Z = Object.Location.Z
            BattleGameModeSystem:GetGameMode():ChangeToHuman(Object, nHumanId, tbTransform)
        end
    end
end

local function CarryPlayers(self)
    local tbPointInfos = SelectionPointHelper:GetSelectionData()

    -- carry players
    local tbObj, pTransporterActor, szTransporterName
    for i, v in ipairs(self.tbTransporters) do
        pTransporterActor = v.pUEActor-- GameObjectSystem:FindByUniqueId(v.nUniqueId)
        if isvalidhandle(pTransporterActor) then
            szTransporterName = KismetSystemLibrary.GetDisplayName(pTransporterActor)
            for nInstanceId, tbPoint in pairs(tbPointInfos) do
                if tbPoint.nTransporterId == v.nTransporterId then
                    tbObj = GameObjectSystem:FindByInstanceId(nInstanceId)
                    if tbObj == nil or tbObj.pUEActor == nil then
                        logerror("[transporter] StartTransport not find player", nInstanceId)
                    else
                        if not AIHelper:ShouldSkipParachute(tbObj) then
                            if not self.tbGMSkipParachutePlayers[nInstanceId] then
                                log("[transporter] StartTransport and carry player:", szTransporterName, tbObj.szName, tbObj.nPlayerId, v.nTransporterId)
                                pTransporterActor:CarryPlayer(tbObj.pUEActor, tbPoint.nX, tbPoint.nY)
                            end
                        end
                    end
                end
            end
            pTransporterActor:CarryEnd()
        else
            logerror("FFAParachutingStep StartTransport not find transporter ", v.nTransporterId, v.nUniqueId)
        end
    end

    if pTransporterActor ~= nil then
        PiratesReplicationBPHelpers.SetEnableLimitPlayerNum(pTransporterActor, false)
    end
end

local function ClearLaunchBotDatas(self)
    self.tbLaunchBots = nil
    if self.tbDelayLaunchTimer ~= nil then
        DelayTimer:ClearTimer(self.tbDelayLaunchTimer)
        self.tbDelayLaunchTimer = nil
    end
    if self.tbLaunchBotsTimer ~= nil then
        self.tbLaunchBotsTimer:Clear()
        self.tbLaunchBotsTimer = nil
    end
end

local function BotParachingEnd(self, GridTypeManager, tbBot, nX, nY, nZ)
    if tbBot == nil then
        return
    end
    -- toggle bot replicate on ,because some bots is turned off in standbyzone
    if tbBot:IsHuman() then
        tbBot.pUEActor:SetActorIsReplicates(true)
        log("SetActorIsReplicates true ", tbBot.szName)
    end
    local nRegionType = GridTypeManager:GetRegionType(nX, nY)
    if nRegionType == EPiratesGridRegionType.Rock then
        local bRet, pNewLoction = GridTypeManager:GetClosestPositionOfRegionType(nX, nY, EPiratesGridRegionType.Ocean)
        if bRet then
            log("bot lua parachuting on rock start: ", nX, nY)
            nX = pNewLoction.X
            nY = pNewLoction.Y
            nZ = 0
            nRegionType = GridTypeManager:GetRegionType(nX, nY)
            log("bot lua parachuting on rock end: ", nX, nY)
        else
            error(string.format("BattleTransporterHelper Bot GetClosestPositionOfRegionType Failed %d, %s:", tbBot.nPlayerId, tbBot.szName))
        end
    end

    local pLocation = self.pBotBornLocation
    pLocation.X = nX
    pLocation.Y = nY
    pLocation.Z = nZ
    local bIsShip = nRegionType == EPiratesGridRegionType.Ocean
    log("bot lua parachuting end :", tbBot.nPlayerId, tbBot.szName, enumtoint(nRegionType), nX, nY, nZ)
    EventManager:OnFireEvent(CommonEventDef.EV_FFA_PARACHUTION_END, tbBot, bIsShip, true, pLocation)
end

local function VerifyLaunchBots(self)
    if self.tbLaunchBots == nil then
        return
    end
    local GridTypeManager = CommonShell.GetCommon(GWorld):GetGridTypeManager()

    local nCurTime = GlobalVariableSystem:GetLocalTime()
    local nCount = 0
    for i = #self.tbLaunchBots, 1, -1 do
        local tbLaunchInfo = self.tbLaunchBots[i]
        local nValue = tbLaunchInfo.nLaunchTime - nCurTime
        if nValue <= 0 or math.abs(nValue) <= LAUNCH_TIME_DIFFERENCE then
            nCount = nCount + 1
            local tbBot = GameObjectSystem:FindByInstanceId(tbLaunchInfo.nInstanceId)
            BotParachingEnd(self, GridTypeManager, tbBot, tbLaunchInfo.nX, tbLaunchInfo.nY, tbLaunchInfo.nZ)
            table.remove(self.tbLaunchBots, i)
            log("bot launch")
            if nCount >= LAUNCH_BOT_COUNT_PER then
                break
            end
        else
            break
        end
    end

    log("carry bot count ", #self.tbLaunchBots)
    if #self.tbLaunchBots <= 0 then
        ClearLaunchBotDatas(self)
    end
end

local function CarryBots(self)
    local nLaunchBotTime = ParachutingNewIni.tbLaunch.nBotTime
    local fnCalcLaunchTime = function(nX, nY)
        local nTime = math.random(-100, 100) / 100
        return nLaunchBotTime + nTime
    end
    local tbObjs = {}
    local tbAllObjs = GameObjectSystem:GetAllByObjectType(GameObjectTypeDef.PlayerSelf)
    local nCurTime = GlobalVariableSystem:GetLocalTime()
    for v, _ in pairs(tbAllObjs) do
        local nInstanceId = v:GetServerInstanceId()
        if AIHelper:ShouldSkipParachute(v) then
            local nX, nY, nZ = SelectionPointHelper:GetBornPos(nInstanceId)
            if nX and nY and nZ then
                nZ = nZ + 100
                local nLaunchTime = fnCalcLaunchTime(nX, nY)
                local nTimeStamp = nCurTime + fnCalcLaunchTime(nX, nY)
                table.insert(tbObjs, {nInstanceId = nInstanceId, nLaunchTime = nTimeStamp,
                    nX = nX, nY = nY, nZ = nZ})
                if self.nDelayLauchTime == 0 or nLaunchTime < self.nDelayLauchTime then
                    self.nDelayLauchTime = nLaunchTime
                end
                log("carry bot ", v.szName, nInstanceId, nX, nY, nZ, nTimeStamp)
            else
                logwarning("not carry bot ", nInstanceId)
            end
        end
    end

    local fnSort = function(a, b)
        if a.nLaunchTime > b.nLaunchTime then
            return false
        elseif b.nLaunchTime > a.nLaunchTime then
            return false
        else
            return a.nInstanceId > b.nInstanceId
        end
    end
    table.sort(tbObjs, fnSort)

    self.tbLaunchBots = tbObjs
end

local function CarryPlayer(self)
    ForceChangeToHuman()
    CarryPlayers(self)
    CarryBots(self)
end

local function LaunchBots(self)
    log("LaunchBots time ", self.nDelayLauchTime)
    local fnLaunch = function()
        if self.tbLaunchBotsTimer == nil then
            self.tbLaunchBotsTimer = Timer.NewTimer(function()
                VerifyLaunchBots(self)
            end,
            LAUNCH_BOT_INTERVAL, true)
        end
    end
    if self.nDelayLauchTime > 0 then
        if self.tbDelayLaunchTimer == nil then
            self.tbDelayLaunchTimer = DelayTimer:DelayRun(function()
                    fnLaunch()
                end, self.nDelayLauchTime)
        end
    else
        fnLaunch()
    end
end

local function ClearSkipParachuteTimer(self)
    if self.tbGMSkipTimer then
        self.tbGMSkipTimer:Clear()
        self.tbGMSkipTimer = nil
    end
end

local function OnHandleLaunchPlayers(self)
    for nInstanceId, _ in pairs(self.tbGMSkipParachutePlayers) do
        local tbPlayer = GameObjectSystem:FindByInstanceId(nInstanceId)
        if tbPlayer then
            local GridTypeManager = CommonShell.GetCommon(GWorld):GetGridTypeManager()
            local pLocation = tbPlayer:GetLocation()
            local nX = pLocation.X
            local nY = pLocation.Y
            local nZ = pLocation.Z

            local nRegionType = GridTypeManager:GetRegionType(nX, nY)
            local bIsShip = nRegionType == EPiratesGridRegionType.Ocean
            EventManager:OnFireEvent(CommonEventDef.EV_FFA_PARACHUTION_END, tbPlayer, bIsShip, true, Vector{X = nX, Y = nY, Z = nZ})
        end
    end

    self.tbGMSkipParachutePlayers = {}
    ClearSkipParachuteTimer(self)
end

local function LaunchSkipParachutePlayer(self)
    if next(self.tbGMSkipParachutePlayers) ~= nil then
        if self.tbGMSkipTimer == nil then
            self.tbGMSkipTimer = Timer.NewTimer(function()
                OnHandleLaunchPlayers(self)
            end, LAUNCH_PLAYER_TIME, false)
        end
    end
end

local function OnFFAProcessStateChanged(self, nState)
    if nState == ProtoDR.rFFAProcessState_EState.MATINEE then
        CarryPlayer(self)
    elseif nState == ProtoDR.rFFAProcessState_EState.PARACHUTING then
        LaunchBots(self)
        LaunchSkipParachutePlayer(self)
    end
end

function BattleTransporterHelper:Init(tbJsonData)
    self.tbGroups = {}
    self.tbGMSkipParachutePlayers = {}
    self.nDelayLauchTime = 0
    self.pBotBornLocation= Vector{X = 0, Y = 0, Z = 0}

    if not tbJsonData then
        return
    end

    local Groups = tbJsonData.TransportNodes
    if Groups then
        for _, v in ipairs(Groups) do
            local tbTempPoints = {}
            tbTempPoints.TransporterId = v.TransporterId
            tbTempPoints.PathNodes = v.PathNodes
            tbTempPoints.StartNode = v.PathNodes[1]
            tbTempPoints.EndNode = v.PathNodes[#v.PathNodes]
            self.tbGroups[v.PathId] = tbTempPoints
        end
    end

    SelectionPointHelper = require("SelectionPointHelper")
    EventManager:BindEventMethod(CommonEventDef.EV_FFA_PROCESS_STATE_CHANGED, self, OnFFAProcessStateChanged)
end

function BattleTransporterHelper:Uninit()
    EventManager:UnBindEventMethod(CommonEventDef.EV_FFA_PROCESS_STATE_CHANGED, self, OnFFAProcessStateChanged)

    self.pBotBornLocation = nil
    SelectionPointHelper = nil
    ClearLaunchBotDatas(self)
    ClearSkipParachuteTimer(self)

    self.tbGroups = nil
    self.tbGMSkipParachutePlayers = nil
    self.nDelayLauchTime = nil
end

function BattleTransporterHelper:GetAll()
    return self.tbGroups
end

function BattleTransporterHelper:InitTransportPath()
    local tbTransports = self:GetAll()
    local tbInfos = {}
    for _, v in pairs(tbTransports) do
        local nTransporterId = v.TransporterId
        local tbPathNodes = {}
        for _, Node in ipairs(v.PathNodes) do
            table.insert(tbPathNodes, {nX = Node.X, nY = Node.Y})
        end
        local tbInfo = {nTransporterId = nTransporterId, Node = tbPathNodes}
        table.insert(tbInfos, tbInfo)
    end

    local tbGameState = BattleGameModeSystem:GetGameState()

    local tbPacket = {Infos = tbInfos}
    tbGameState.rFFANewTransportInfos:Set(tbPacket)
end

function BattleTransporterHelper:CreateTransport()
    local tbTransport = ParachutingNewIni.tbTransport
    local tbLaunch = ParachutingNewIni.tbLaunch
    local tbParachuteNoOpen = ParachutingNewIni.tbParachuteNoOpen
    local tbParachuteOpen = ParachutingNewIni.tbParachuteOpen
    local tbNewTarget = ParachutingNewIni.tbNewTarget
    local tbRelevantDistance = ParachutingNewIni.tbRelevantDistance
    -- local bUseNewTarget = BattleBlackboard:GetBool("ParachutingNewTarget")
    -- local bNewLaunch = BattleBlackboard:GetBool("TransporterNewLaunch")

    local tbGameMode = BattleGameModeSystem:GetGameMode()
    local tbMapSize = tbGameMode.tbJsonTableFile.tbContainer.MapSize[1]
    local nMapSize = math.max(math.ceil(tbMapSize.GamePlayWidth / 2), math.ceil(tbMapSize.GamePlayHeight / 2))
    self.tbTransporters = {}

    local tbTransports = BattleTransporterHelper:GetAll()
    for _, v in pairs(tbTransports) do
        local nTransporterId = v.TransporterId
        local tbStartNode = v.StartNode
        local tbPathNodes = {}
        local tbTransporterData = TransporterDataTable:GetTemplate(nTransporterId)
        if tbTransporterData ~= nil then
            local tbTransporter = GameObjectSystem:CreateDummyInGameMode(tbTransporterData.nDummyId,
            tbStartNode, nil, szTransporterTag..nTransporterId)
            if(tbTransporter == nil or tbTransporter.pUEActor == nil) then
                error(string.format("Spawn new transporter failed, id: %d", nTransporterId))
            else
                for i, Node in ipairs(v.PathNodes) do
                    if i > 1 then
                        tbTransporter.pUEActor:AddPathNode(Node.X, Node.Y)
                        table.insert(tbPathNodes, {nX = Node.X, nY = Node.Y})
                    end
                end
                tbTransporter.pUEActor:SetTransporterInfo(
                    nTransporterId,
                    tbTransport.nTransportTime,
                    nMapSize / tbTransport.nTriggerTime,
                    tbNewTarget.nTargetDistance,
                    tbTransporterData.nLaunchTime
                )
                tbTransporter.pUEActor:SetParachutingInfo(
                    tbLaunch.nLaunchHeight,
                    tbLaunch.nOperateHeight,
                    tbLaunch.nOpenParachuteMaxHeight,
                    tbLaunch.nOpenParachuteMinHeight,
                    tbLaunch.nLaunchTime,
                    tbLaunch.nPreTopHeight,
                    tbLaunch.nPreOpenParachuteHeight,

                    tbParachuteNoOpen.nNormalFallSpeed,
                    tbParachuteNoOpen.nMaxFallSpeed,
                    tbParachuteNoOpen.nMinFallSpeed,
                    tbParachuteNoOpen.nTranslationSpeed,
                    -- tbParachuteNoOpen.nAcceleration,
                    -- tbParachuteNoOpen.nRockerM,
                    tbParachuteNoOpen.nFallDecaySpeed,
                    tbParachuteNoOpen.nTranslationDecaySpeed,
                    tbParachuteNoOpen.nDegree,

                    tbParachuteOpen.nTranslationMaxAngleSpeed,
                    tbParachuteOpen.nTranslationMinAngleSpeed,
                    tbParachuteOpen.nTranslationNormalSpeed,
                    tbParachuteOpen.nTranslationMaxSpeed,
                    tbParachuteOpen.nTranslationMinSpeed,
                    tbParachuteOpen.nNormalFallSpeed,
                    tbParachuteOpen.nFrontFallSpeed,
                    tbParachuteOpen.nBackFallSpeed,
                    tbParachuteOpen.nFrontFallDecay,
                    tbParachuteOpen.nBackFallDecay,
                    tbParachuteOpen.nForwardAngle,
                    tbParachuteOpen.nNoOperateFallSpeed,
                    tbParachuteOpen.nNoOperateTranslationSpeed,

                    tbParachuteOpen.nRotationRate,
                    tbParachuteOpen.nRemoveParachuteHeight,
                    tbParachuteOpen.nPlayDropAniHeight,
                    tbParachuteOpen.nDropRollAniTranslationSpeed,
                    tbRelevantDistance.nInAirDistance)

                table.insert(self.tbTransporters, {nTransporterId = nTransporterId, nUniqueId = tbTransporter:GetUEActorUniqueId(),
                    pUEActor = tbTransporter.pUEActor})
            end
        else
            error(string.format("Spawn new transporter failed, invalid transporterid: %d", nTransporterId))
        end
    end
end

function BattleTransporterHelper:GetTransporters()
    return self.tbTransporters
end

function BattleTransporterHelper:PlayerSkipParachute(nInstanceId, bSkip)
    self.tbGMSkipParachutePlayers[nInstanceId] = bSkip
end

return BattleTransporterHelper
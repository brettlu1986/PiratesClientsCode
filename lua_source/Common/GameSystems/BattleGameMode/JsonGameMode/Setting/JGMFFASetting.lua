local luaclass = require("luaclass")
local JGMCommonSetting = dynamic_require("JGMCommonSetting")
local JGMFFASetting = luaclass("JGMFFASetting", JGMCommonSetting)

local DungeonQuitDialogType = require("DungeonQuitDialogType")
local GlobalVariableSystem = dynamic_require("GlobalVariableSystem")
local ProtoDR = require("DungeonRepProtoNames")
local ProtoDC = require("DungeonCommonProtoNames")
local GameObjectSystem = dynamic_require("GameObjectSystem")
local TemplateTypeDef = require("TemplateTypeDef")
local BattleBlackboard = require("BattleBlackboard")
local BattleOperationDef = dynamic_require("BattleOperationDef")
local CommonEventDef = require("CommonEventDef")
local EventManager = require("EventManager")
local GameObjectTypeDef = require("GameObjectTypeDef")
local SpawnerSystem = require("SpawnerSystem")
local BattleTransformPointHelper = require("BattleTransformPointHelper")
local NetworkManager = dynamic_require("NetworkManager")
local BattleTeamSystem = require("BattleTeamSystem")
local BattleTransporterHelper = require("BattleTransporterHelper")
local BotAISystem = dynamic_require("BotAISystem")
local SelectionPointHelper = require("SelectionPointHelper")
local BattleGameModeSystem = dynamic_require("BattleGameModeSystem")
local BattleTemplateActorSystem = dynamic_require("BattleTemplateActorSystem")
local PlayerStatsHelper = require("PlayerStatsHelper")
local D2CHelper = require("D2CHelper")
local BattleAbilityDefine = require("BattleAbilityDefine")
local ParachutingNewIni = require("ParachutingNewIni")
local SpawnerDef = require("SpawnerDef")
local BattleDataStatisticsSystem = dynamic_require("BattleDataStatisticsSystem")
local AIVariableSystem = require("AIVariableSystem")
local BattleFFANoobHelper = require("BattleFFANoobHelper")
local BattleFFAReLoginHelper = require("BattleFFAReLoginHelper")
local FFAOptimizationHelper = require("FFAOptimizationHelper")
local BattleResultSystem = dynamic_require("BattleResultSystem")
local BattleFFAAdditionalSuccessHelper = require("BattleFFAAdditionalSuccessHelper")
local BattleAdditionalSuccessResultDef = require("BattleAdditionalSuccessResultDef")
-- local BattleLandSystem = dynamic_require("BattleLandSystem")
local AIHelper    = require("AIHelper")
local TeamWatchServerHelper = require("TeamWatchServerHelper")
local HumanVehicleHelper = require("HumanVehicleHelper")
local HumanVehicleStateDef = require("HumanVehicleStateDef")
local DamageTypeEx = require("DamageTypeEx")
local AIOceanGridSystem = require("AIOceanGridSystem")
local PropNameGameState = require("PropNameGameState")
local BattlePrepareSystem = require("BattlePrepareSystem")
-- local Timer = require("Timer")
-- local ResourceManager = require("ResourceManager")

JGMFFASetting.nPlayerCount = 0                    -- 玩家总数
JGMFFASetting.nTeamCount = 0                      -- 队伍总数
JGMFFASetting.nPlayerAlive = 0                    -- 活着的玩家
JGMFFASetting.bWaitStage = true                   -- 等待流程
JGMFFASetting.nTeamModeId = 1                     -- 副本匹配模式id

JGMFFASetting.nCountDownTime = 90                 -- 倒计时时间
JGMFFASetting.nSelectionPointLockTime = 85        -- 选点锁定时间
JGMFFASetting.nSelectionPointPopTime = 60         -- 选点弹出时间
JGMFFASetting.nStopAcceptingPlayerTime = 50       -- 禁止进入倒计时时间
JGMFFASetting.nTotalPlayerCount = 101             -- 开启计时玩家+机器人数
JGMFFASetting.nRealPlayerCount = 101              -- 开启计时玩家数
JGMFFASetting.nBotCount = 0                       -- 加机器人数
JGMFFASetting.nMaxCDWaitTime = 3600               -- 触发倒计时最多等待时间，单位秒

JGMFFASetting.bWin = false                        -- 是否有玩家吃鸡
JGMFFASetting.nCoreAreaRadius=100000              --中心区域半径
JGMFFASetting.bCoreAreaOpen  = false              --中心区域是否已经开放
JGMFFASetting.tbQuitDungeonPlayerIdMaps = nil     --主动退出副本的玩家PlayerIds, Key:TeamId, Value:PlayerIds
JGMFFASetting.nTimeToPopSelctionPoint = 0
JGMFFASetting.bBattleBegin = false
JGMFFASetting.bNeverCheckLoginOut = false
JGMFFASetting.bKillingRealTeam = false

local function DefineGameStatePropertiesDefaultValues(self, tbGameState)
    tbGameState.nFFACountDownEndTime:Set(0)
    tbGameState.nFFAAlivePlayerCount:Set(0)
    tbGameState.nFFATeamModeId:Set(0)
    tbGameState.bFFAWaitStage:Set(true)
    tbGameState.nFFAProcessState:Set(-1)
    tbGameState.rFFANewTransportInfos:Set(nil)
    tbGameState.rFFAPoisonCircleInfo:Set(nil)
end

local function SetPlayerQuitDungeon(self, nTeamId, nPlayerId)
    self.tbQuitDungeonPlayerIdMaps[nTeamId] = self.tbQuitDungeonPlayerIdMaps[nTeamId] or {}
    self.tbQuitDungeonPlayerIdMaps[nTeamId][nPlayerId] = true
end

local function IsPlayerQuitDungeon(self, nTeamId, nPlayerId)
    if self.tbQuitDungeonPlayerIdMaps[nTeamId] then
        return self.tbQuitDungeonPlayerIdMaps[nTeamId][nPlayerId]
    end

    return nil
end

--计算当前存活的人数
local function GetPlayerAliveNum(self)
    local nCount = 0
    local tbObjects = GameObjectSystem:GetAllByObjectType(GameObjectTypeDef.PlayerSelf)

    for Object, _ in pairs(tbObjects) do
        local nInstanceId = Object:GetServerInstanceId()
        local bPlayerBattleEnd  = BattleResultSystem:IsPlayerBattleEnd(nInstanceId)
        if not bPlayerBattleEnd then
                nCount = nCount + 1
        end
    end

    return nCount
end

local function RepFFAInfo(self, nPlayerCount)
    local tbGameState = self.tbGameMode.tbGameState
    tbGameState.nFFAAlivePlayerCount:Set(nPlayerCount)
end

local function UpdateAlivePlayerCount(self)
    self.nPlayerAlive = GetPlayerAliveNum(self)
    RepFFAInfo(self, self.nPlayerAlive)
end

local function GetSelectionPointPopTime()
    return BattleBlackboard:GetNumber("SelectionPointPopTime")
end

--把没有登录进来的玩家强制模拟登录流程，创建好角色
local function SpawnPlayerWhichNotLogin(self)
    local tbAllPlayerIds = {}
    local tbPlayers = GameObjectSystem:GetAllByObjectType(GameObjectTypeDef.PlayerSelf)
    for tbPlayer, _ in pairs(tbPlayers) do
        tbAllPlayerIds[tbPlayer:GetPlayerId()] = true
    end

    local tbPlayerPrepareInfoMap = BattlePrepareSystem:GetAllPlayerPrepareInfos()
    for nPlayerId, tbPrepareInfo in pairs(tbPlayerPrepareInfoMap) do
        local nTeamId = tbPrepareInfo.nGroupIndex
        local bBot    = tbPrepareInfo:IsBot()

        --没有逃跑，没有Login的真人玩家
        if not bBot and
           not tbAllPlayerIds[nPlayerId] and 
           not IsPlayerQuitDungeon(self, nTeamId, nPlayerId) then

            local tbPlayer = BattleGameModeSystem:CreatePlayerSelf(tbPrepareInfo, nil, nil, 0)
            if not tbPlayer then
                error("SpawnPlayerWhichNotLogin CreatePlayerSelf return nil, nPlayerId:" .. nPlayerId)
            end
        
            local bRet = BattleGameModeSystem:SpawnPlayerPawn(tbPlayer, false)
            if not bRet then
                logerror("SpawnPlayerWhichNotLogin SpawnPlayerPawn return nil, nPlayerId:" .. nPlayerId)
            end
        
            BattleGameModeSystem:OnPlayerLogin(tbPlayer)
            BattleGameModeSystem:OnPlayerLogout(tbPlayer)
        end
    end
end

local function OnFFAProcessStateChanged(self, nState)
    if nState == ProtoDR.rFFAProcessState_EState.COUNTDOWN then
        local nTime = GetSelectionPointPopTime()
        self.nTimeToPopSelctionPoint = nTime + GlobalVariableSystem:GetLocalTime()

        self.tbGameMode.tbGameState.nFFACountDownEndTime:Set(self.nTimeToPopSelctionPoint)

        self.tbGameMode:SetBattleStartTimestamp()
        self.bBattleBegin = true
        EventManager:OnFireEvent(CommonEventDef.EV_LOG_BATTLE_BEGIN)

    elseif nState == ProtoDR.rFFAProcessState_EState.SELECTION then
        SpawnPlayerWhichNotLogin(self)

    elseif nState == ProtoDR.rFFAProcessState_EState.PARACHUTING then
        -- 开始统计
        BattleDataStatisticsSystem:Activate()

        if(GlobalVariableSystem.bEnableTemplateActor) then
            BattleTemplateActorSystem:SwitchToDefaultRegion(true)
        end
    end
end

local function OnFFAWatchMateTips(self, tbPlayer, nInstanceId)
    local tbDeadResult = BattleResultSystem:GetPlayerResultData(nInstanceId)
    local nKillCount = 0
    if tbDeadResult and tbDeadResult.nKillCount then
        nKillCount = tbDeadResult.nKillCount
    end

    local tbWatchObject = GameObjectSystem:FindByInstanceId(nInstanceId)

    local tbPrepareInfo = tbWatchObject.tbPrepareInfo
    if tbPrepareInfo == nil then
        log("[watch battle], tbPrepareInfo nil")
    else
        if tbPrepareInfo.tbSeason == nil then
            log("[watch battle], tbPrepareInfo.tbSeason nil")
        end
    end

    local tbPacket = {}
    tbPacket.nInstanceId = nInstanceId
    tbPacket.nKillCount = nKillCount

    if tbPrepareInfo and tbPrepareInfo.tbSeason then
        local tbSeasonInfo = tbPrepareInfo.tbSeason
        tbPacket.nGames = tbSeasonInfo.matches
        tbPacket.nKills = tbSeasonInfo.kill
        tbPacket.nWins = tbSeasonInfo.wins
        tbPacket.nTopTens = tbSeasonInfo.topTen
    else
        tbPacket.nGames = 0
        tbPacket.nKills = 0
        tbPacket.nWins = 0
        tbPacket.nTopTens = 0
    end

    NetworkManager:GetRPCNetworkProxy():SendToClient(tbPlayer:GetUEControllerUniqueId(), ProtoDC.d2c_FFAWatchMateTips, tbPacket)
end

local function OnDisconnectWithHub(self)
    local tbGameMode = self.tbGameMode
    if tbGameMode ~= nil then
        log("JGMFFASetting OnDisconnectWithHub. Force to SetCheckAllPlayerLogoutFunc back to normal.")
        tbGameMode:SetCheckAllPlayerLogoutFunc(nil)
    end
end

-- 玩家重伤
local function OnPawnDyingChanged(self, tbGameObject, bIsDying)
    -- 发送重伤提示
    if bIsDying then
        local szKillerName = nil
        local tbKillerActor = nil
        local tbDeadActorComponent = tbGameObject:GetCurrentPropertyComponent()
        local nDamageType = nil
        local nKillerInstanceId = nil
        if tbDeadActorComponent then
            tbKillerActor = tbDeadActorComponent:GetLastDamageCauser()
            nDamageType = tbDeadActorComponent:GetLastDamageType()
            local tbDeadExtraData = tbDeadActorComponent:GetLastDamageExtraData()
            if tbKillerActor then
                szKillerName = tbKillerActor.szName
                nKillerInstanceId = tbKillerActor:GetServerInstanceId()
            end

            D2CHelper:MulticastKillToast(ProtoDC.d2c_BattleKillToast_EType.INJURY,
                szKillerName, tbGameObject.szName,
                nKillerInstanceId, tbGameObject:GetServerInstanceId(),
                nDamageType,
                tbDeadExtraData and tbDeadExtraData.nWeaponTemplateId or nil)
        end
    end
end

local function DefineBlackboardKey(self)
    -- GM控制停止所有选点条件
    BattleBlackboard:DefineBool("INTER_GM_StopSelectPointCondition", false)
    -- GM控制跳过生成NPC
    BattleBlackboard:DefineBool("INTER_GM_Ignore_Spawn_Npc", false)
    -- GM控制跳过生成Bot
    BattleBlackboard:DefineBool("INTER_GM_Ignore_Spawn_Bot", false)

    -- 机器人数量
    BattleBlackboard:DefineNumber("BotCount", self.nBotCount)
    -- 倒计时开始 玩家进入数量
    BattleBlackboard:DefineNumber("PlayerLoginCount", self.nRealPlayerCount)
    -- 倒计时开始 玩家机器人进入数量
    BattleBlackboard:DefineNumber("TotalPlayerCount", self.nTotalPlayerCount)
    -- 倒计时时间
    BattleBlackboard:DefineNumber("CountDownTime", self.nCountDownTime)
    BattleBlackboard:DefineNumber("SelectionPointLockTime", self.nSelectionPointLockTime)
    BattleBlackboard:DefineNumber("SelectionPointPopTime", self.nSelectionPointPopTime)
    -- 停止进入游戏倒计时时间
    BattleBlackboard:DefineNumber("StopAcceptingPlayerTime", self.nStopAcceptingPlayerTime)
    BattleBlackboard:DefineNumber("INTER_MaxCDWaitTime", self.nMaxCDWaitTime)
    BattleBlackboard:DefineBool("INTER_Noob", false)
    -- 跳伞新目标点
    BattleBlackboard:DefineBool("ParachutingNewTarget", ParachutingNewIni.tbNewTarget.nTargetDistance > 0)
    -- 航线船是否同时发射
    BattleBlackboard:DefineBool("TransporterNewLaunch", ParachutingNewIni.tbNewTarget.IsSameTimeLaunch)

end

local function GetReadyRegionInfo(self)
    local szReadyRegionTag = "ReadyRegion" 
    local tbTransform = BattleTransformPointHelper:FindByTag(szReadyRegionTag)
    if tbTransform then
        if tbTransform.StartPoint and tbTransform.EndPoint then
            local W = tbTransform.EndPoint.X - tbTransform.StartPoint.X
            local H = tbTransform.EndPoint.Y - tbTransform.StartPoint.Y
            return math.abs(W), math.abs(H), 
                (tbTransform.EndPoint.X + tbTransform.StartPoint.X) / 2, 
                (tbTransform.EndPoint.Y + tbTransform.StartPoint.Y) / 2
        end
    end
    error("GetReadyRegionInfo failed")
end

local function InitProcessData(self)
    self.nBotCount = BattleGameModeSystem:GetGameInitData().nBotCount
    if self.nBotCount then
        BattleBlackboard:SetNumber("BotCount", self.nBotCount)
    end
    self.nRealPlayerCount = BattleGameModeSystem:GetGameInitData().nCountDownRealPlayerCount
    if self.nRealPlayerCount then
        BattleBlackboard:SetNumber("PlayerLoginCount", self.nRealPlayerCount)
    end

    self.nTotalPlayerCount = BattleGameModeSystem:GetGameInitData().nCountDownTotalPlayerCount
    if self.nTotalPlayerCount then
        BattleBlackboard:SetNumber("TotalPlayerCount", self.nTotalPlayerCount)
    end

    self.nCountDownTime = BattleGameModeSystem:GetGameInitData().nCountDownTime
    if self.nCountDownTime then
        BattleBlackboard:SetNumber("CountDownTime", self.nCountDownTime)
    end

    self.nSelectionPointLockTime = BattleGameModeSystem:GetGameInitData().nSelectionPointLockTime
    if self.nSelectionPointLockTime then
        BattleBlackboard:SetNumber("SelectionPointLockTime", self.nSelectionPointLockTime)
    end

    self.nSelectionPointPopTime = BattleGameModeSystem:GetGameInitData().nSelectionPointPopTime
    if self.nSelectionPointPopTime then
        BattleBlackboard:SetNumber("SelectionPointPopTime", self.nSelectionPointPopTime)
    end

    self.nStopAcceptingPlayerTime = BattleGameModeSystem:GetGameInitData().nStopAcceptingPlayerTime
    if self.nStopAcceptingPlayerTime then
        BattleBlackboard:SetNumber("StopAcceptingPlayerTime", self.nStopAcceptingPlayerTime)
    end

    local nMaxCDTempTime = BattleGameModeSystem:GetGameInitData().nCountDownMaxWaitTime
    self.nMaxCDWaitTime = nMaxCDTempTime
    if self.nMaxCDWaitTime then
        BattleBlackboard:SetNumber("INTER_MaxCDWaitTime", self.nMaxCDWaitTime)
    end

    local bNoob = BattleGameModeSystem:GetGameInitData().bNoob or false
    BattleBlackboard:SetBool("INTER_Noob",bNoob)
    BattleFFANoobHelper:SetNoob(bNoob)

end

--重连玩家发送完Item后需要设置当前武器
local function OnBattleItemResetAfterReLogin(self, tbPlayer)
    BattleFFAReLoginHelper:BattleItemResetAfterReLogin(tbPlayer)
end

--通知埋点系统战斗结束了
local function NotifyLogEventSystemBattleEnd(self)
    if self.bBattleBegin then
        self.bBattleBegin = false
       EventManager:OnFireEvent(CommonEventDef.EV_LOG_BATTLE_END)
    end
end

--将所有真人以及其队友都强制结算
local function ForceAllRealTeamBattleEnd(self)
    local tbAllTeamsInfo = BattleTeamSystem:GetAllTeamInfo()

    --确保不会只有一个队伍
    local nBattleCount = 0
    for nTeamId, tbTeamInfo in pairs(tbAllTeamsInfo) do
        if not BattleResultSystem:IsTeamBattleEnd(nTeamId) then
            nBattleCount = nBattleCount + 1
        end
    end

    if nBattleCount <= 1 then
        return
    end

    for _, tbTeamInfo in pairs(tbAllTeamsInfo) do
        if self.bWin then
            break
        end

        local bExistRealPlayer = false
        for _, tbPlayer in pairs(tbTeamInfo.tbGameObjects) do
            if not BotAISystem:IsBot(tbPlayer) then
                bExistRealPlayer = true
                break
            end
        end

        if bExistRealPlayer then
            for _, tbPlayer in pairs(tbTeamInfo.tbGameObjects) do
                local nInstanceId = tbPlayer:GetServerInstanceId()
                local bPlayerBattleEnd = BattleResultSystem:IsPlayerBattleEnd(nInstanceId)
                if not bPlayerBattleEnd then
                    tbPlayer:KillSelf()
                end
            end
        end
    end
end

local function ForceReleaseDungeon(self)
    self.tbGameMode:OnAllPlayerLogoutWithEvent()
end

--副本要回收了，尝试LogBattleEnd
local function OnPreAllPlayerLogout(self)
    if not self.bKillingRealTeam and not self:IsWaitStage() then
        self.bKillingRealTeam = true
        ForceAllRealTeamBattleEnd(self)
    end

    NotifyLogEventSystemBattleEnd(self)
end

local function MarkPlayerBattleEnd(self,tbPlayer)
    BattleResultSystem:MarkPlayerBattleEnd(tbPlayer)

    local tbGameMode = self.tbGameMode
    if(tbGameMode:CheckAllPlayerLogout()) then
        ForceReleaseDungeon(self)
    end
end

-- 玩家死亡数据处理
local function OnPlayerDeadToast(self, tbDeadActor)
    local szKillerName = nil
    local tbKillerActor = nil
    local tbDeadActorComponent = tbDeadActor:GetCurrentPropertyComponent()
    local nDamageType = nil
    local tbDeadExtraData = nil
    local nKillerInstanceId = nil

    if tbDeadActorComponent then
        local nTeamId = BattleTeamSystem:FindTeamId(tbDeadActor)
        local nPlayerId = tbDeadActor:GetPlayerId()

        if IsPlayerQuitDungeon(self, nTeamId, nPlayerId) then
            nDamageType = DamageTypeEx.KILL_SELF --临时解决战斗区逃跑客户端击杀类型未知的问题，因为KillSelf是匿名的。将来逃跑不再自杀，到时候删除这里代码即可。
        else
            tbKillerActor = tbDeadActorComponent:GetLastDamageCauser()
            nDamageType = tbDeadActorComponent:GetLastDamageType()
            tbDeadExtraData = tbDeadActorComponent:GetLastDamageExtraData()
            if tbKillerActor then
                szKillerName = tbKillerActor.szName
                nKillerInstanceId = tbKillerActor:GetServerInstanceId()
                if tbKillerActor.ObjectType == GameObjectTypeDef.PlayerSelf then
                    local nKillerKillCount = PlayerStatsHelper:GetKillCountByPlayerId(tbKillerActor:GetPlayerId())
                    -- 击杀方提示
                    local tbKillerKillPacket = {}
                    tbKillerKillPacket.nKillCount = nKillerKillCount
                    TeamWatchServerHelper.NotifyViewersKillInfo(tbKillerActor, nKillerKillCount)
                    NetworkManager:GetRPCNetworkProxy():SendToClient(tbKillerActor:GetUEControllerUniqueId(), ProtoDC.d2c_FFAKillInfo, tbKillerKillPacket)
                end
            end
        end
    end

    D2CHelper:MulticastKillToast(ProtoDC.d2c_BattleKillToast_EType.KILL,
        szKillerName, tbDeadActor.szName,
        nKillerInstanceId, tbDeadActor:GetServerInstanceId(),
        nDamageType,
        tbDeadExtraData and tbDeadExtraData.nWeaponTemplateId or nil)
end

local function EnterPlayerResult(self, tbPlayer, bSendResultToClient, bAdditionalSuccess)
    if self:IsWaitStage() then
        return
    end

    UpdateAlivePlayerCount(self)
    local nCurPlayerRank = self.nPlayerAlive + 1
    if bAdditionalSuccess then
        nCurPlayerRank = 1
    end

    local bWin,nWinerTeamId = BattleResultSystem:EnterPlayerResult(tbPlayer, self.nTeamModeId, self.nPlayerCount, self.nTeamCount, nCurPlayerRank, bSendResultToClient, bAdditionalSuccess)
    if bWin then
        local tbWinerMembers = BattleTeamSystem:GetTeamMembers(nWinerTeamId)
        for _, tbWinnerPlayer in ipairs(tbWinerMembers) do
            local nInstanceId = tbWinnerPlayer:GetServerInstanceId()
            local bPlayerBattleEnd  = BattleResultSystem:IsPlayerBattleEnd(nInstanceId)
            if not bPlayerBattleEnd then
                self:OnFFAResult(tbWinnerPlayer)
                MarkPlayerBattleEnd(self, tbWinnerPlayer)
            end
        end

        self.bWin = true
        NotifyLogEventSystemBattleEnd(self)
        D2CHelper:MulticastGameOver()
        EventManager:OnFireEvent(CommonEventDef.EV_FFA_TEAM_WIN, nWinerTeamId)
    end
    -- BattleLandSystem:RecordChangeDisplay(tbPlayer, true)
end

local function OnAdditionalSuccessResult(self, nReturnCode, tbPlayer)
    if nReturnCode == BattleAdditionalSuccessResultDef.EXIT_BATTLE then
        MarkPlayerBattleEnd(self, tbPlayer)
        EnterPlayerResult(self, tbPlayer, true, true)
    end
end

local function InitTemplateActorRegions(self, tbGameMode)
    -- default region
    GlobalVariableSystem.bEnableTemplateActor = true
    local tbMapSize = tbGameMode.tbJsonTableFile.tbContainer.MapSize[1]
    BattleTemplateActorSystem:InitDefaultRegion(tbMapSize.GamePlayWidth, tbMapSize.GamePlayHeight, 0, 0)

    -- ready region
    local W, H, X, Y = GetReadyRegionInfo(self)
    local nRegionIndex = BattleTemplateActorSystem:CreateOtherRegion(
        W, H, X, Y)
    BattleTemplateActorSystem:SwitchRegion(nRegionIndex, false)
end

local function InitAIOceanGrid(tbGameMode)
    local tbMapSize = tbGameMode.tbJsonTableFile.tbContainer.MapSize[1]
    AIOceanGridSystem:InitMap(tbMapSize.GamePlayWidth, tbMapSize.GamePlayHeight, 0, 0)
end

function JGMFFASetting:Init(tbGameMode)
    assert(not GlobalVariableSystem:IsClient(), "Enter Dungeon mode error")

    if(not JGMFFASetting.super.Init(self, tbGameMode)) then
        return false
    end

    self.tbQuitDungeonPlayerIdMaps = {}
    InitTemplateActorRegions(self, tbGameMode)
    InitAIOceanGrid(tbGameMode)
    SelectionPointHelper:Init()
    BattleFFANoobHelper:Init()
    FFAOptimizationHelper:Init()
    BattleFFAAdditionalSuccessHelper:Init()

    self:DefineGameStateByType(PropNameGameState.PropType.TYPE_FFA)
    DefineGameStatePropertiesDefaultValues(self, tbGameMode:GetGameState())

    EventManager:BindEventMethod(CommonEventDef.EV_GAME_OBJECT_ON_PAWN_DEAD, self, self.OnPawnDead)
    EventManager:BindEventMethod(CommonEventDef.EV_FFA_PROCESS_STATE_CHANGED, self, OnFFAProcessStateChanged)
    EventManager:BindEventMethod(CommonEventDef.EV_GAME_OBJECT_ON_PAWN_DYING_CHANGED , self, OnPawnDyingChanged)
    EventManager:BindEventMethod(CommonEventDef.EV_WATCH_MATE_TIPS , self, OnFFAWatchMateTips)
    EventManager:BindEventMethod(CommonEventDef.EV_ON_DISCONNECT_WITH_HUB, self, OnDisconnectWithHub)
    EventManager:BindEventMethod(CommonEventDef.EV_BATTLE_PLAYER_POST_LOGOUT, self, self.OnPlayerPostLogout)
    EventManager:BindEventMethod(CommonEventDef.EV_BATTLE_ITEM_PICK_UP_FINISH_SERVER , self, self.OnItemPickUp)
    EventManager:BindEventMethod(CommonEventDef.EV_BATTLE_ITEM_RESET_AFTER_RELOGIN_SERVER , self, OnBattleItemResetAfterReLogin)
    EventManager:BindEventMethod(CommonEventDef.EV_GAME_MODE_PRE_ON_ALL_PLAYER_LOGOUT, self, OnPreAllPlayerLogout)
    EventManager:BindEventMethod(CommonEventDef.EV_ADDITIONALSUCCESS_RESULT, self, OnAdditionalSuccessResult)

    DefineBlackboardKey(self)
    InitProcessData(self)

    local nTeamModeId = BattleGameModeSystem:GetGameInitData().nTeamModeId
    self.nTeamModeId = nTeamModeId

    return true
end

function JGMFFASetting:Uninit()
    self.tbQuitDungeonPlayerIdMaps = nil
    SelectionPointHelper:Uninit()
    BattleFFANoobHelper:Uninit()
    FFAOptimizationHelper:Uninit()
    BattleFFAAdditionalSuccessHelper:Uninit()

    EventManager:UnBindEventMethod(CommonEventDef.EV_GAME_OBJECT_ON_PAWN_DEAD, self, self.OnPawnDead)
    EventManager:UnBindEventMethod(CommonEventDef.EV_FFA_PROCESS_STATE_CHANGED, self, OnFFAProcessStateChanged)
    EventManager:UnBindEventMethod(CommonEventDef.EV_GAME_OBJECT_ON_PAWN_DYING_CHANGED , self, OnPawnDyingChanged)
    EventManager:UnBindEventMethod(CommonEventDef.EV_WATCH_MATE_TIPS , self, OnFFAWatchMateTips)
    EventManager:UnBindEventMethod(CommonEventDef.EV_ON_DISCONNECT_WITH_HUB, self, OnDisconnectWithHub)
    EventManager:UnBindEventMethod(CommonEventDef.EV_BATTLE_PLAYER_POST_LOGOUT, self, self.OnPlayerPostLogout)
    EventManager:UnBindEventMethod(CommonEventDef.EV_BATTLE_ITEM_PICK_UP_FINISH_SERVER , self, self.OnItemPickUp)
    EventManager:UnBindEventMethod(CommonEventDef.EV_BATTLE_ITEM_RESET_AFTER_RELOGIN_SERVER , self, OnBattleItemResetAfterReLogin)
    EventManager:UnBindEventMethod(CommonEventDef.EV_GAME_MODE_PRE_ON_ALL_PLAYER_LOGOUT, self, OnPreAllPlayerLogout)
    EventManager:UnBindEventMethod(CommonEventDef.EV_ADDITIONALSUCCESS_RESULT, self, OnAdditionalSuccessResult)

    JGMFFASetting.super.Uninit(self)
end

function JGMFFASetting:GetQuitDungeonDialogType()
    return DungeonQuitDialogType.FFA
end

function JGMFFASetting:Parse(tbJsonData)
    self.nCoreAreaRadius = tbJsonData.CoreAreaMaxRadius
    BattleResultSystem:SetWinnerBuffId(tbJsonData.InvincibleBuffId)

    if(not JGMFFASetting.super.Parse(self, tbJsonData)) then
        return false
    end

    return true
end

local function SendWaitStageProto(self, bWaitStage)
    local tbGameState = self.tbGameMode.tbGameState
    tbGameState.bFFAWaitStage:Set(bWaitStage)
end

local function SendTeamModeInfoProto(self)
    local tbGameState = self.tbGameMode.tbGameState

    tbGameState.nFFATeamModeId:Set(self.nTeamModeId)
end

local function SpawnPlayerInBattle(self, tbPlayer)
    if tbPlayer.pUEActor == nil then
        logerror("ProcessNewFFA player invalid")
        return
    end
    local tbGameState = self.tbGameMode.tbGameState
    local nFFAProcessState = tbGameState.nFFAProcessState
    local nState = nFFAProcessState:Get()
    if nState == nil then
        log("player login no state ")
        return
    end
    if nState < ProtoDR.rFFAProcessState_EState.SELECTION_LOCK then
        log("player login state ", nState)
        return
    end

    -- 进入时已经过了自动选点
    local tbTransporters = BattleTransporterHelper:GetTransporters()
    log("player login and over auto select point", #tbTransporters)
    if #tbTransporters > 0 then
        SelectionPointHelper:RandomSpawnPlayer(tbPlayer, tbTransporters)
    end
end

local function RemoveAllPlayerBuffs(self)
    local tbObjects = GameObjectSystem:GetAllByObjectType(GameObjectTypeDef.PlayerSelf)

    for Object, _ in pairs(tbObjects) do
        if Object.BuffComponentServer then
               Object.BuffComponentServer:RemoveBuffExcludeGroupId(BattleAbilityDefine.BUFF_GROUP_TYPE.FROM_LOBBY)
        end
    end
end

function JGMFFASetting:OnItemPickUp(tbPlayer, tbItem)
    BattleFFANoobHelper:OnItemPickUp(tbPlayer, tbItem, self:IsWaitStage())
end

function JGMFFASetting:IsWaitStage()
   return self.bWaitStage
end

function JGMFFASetting:GetCoreAreaRadius()
    return self.nCoreAreaRadius
end

function JGMFFASetting:SetCoreAreaOpen()
    self.bCoreAreaOpen = true
end

function JGMFFASetting:IsCoreAreaOpen()
    return self.bCoreAreaOpen
end

local function GetAllOnlinePlayers(self)
    local tbPlayers = self.tbGameMode.tbPlayers
    local tbOnlinePlayers = {}
    for nIndex, tbPlayer in ipairs(tbPlayers) do
        local nCurInstanceId = tbPlayer:GetServerInstanceId()
        tbOnlinePlayers[nCurInstanceId] = true
    end

    return tbOnlinePlayers
end

--return bool
--当战斗标记为结束 并且 Logout的时候 则认为这个人员真正退出了。
--当所有真实玩家都标记战斗结束 并且 所有真实玩家都退出 的时候回收副本
local function OnFFACheckAllPlayerLogoutFunc(self)
    log("OnFFACheckAllPlayerLogoutFunc")
    if self.bNeverCheckLoginOut then
        logerror("this should only appear in game core ai mode, check login out")
        return false
    end

    local bRet = true
    local tbOnlinePlayers = GetAllOnlinePlayers(self)
    local tbObjects = GameObjectSystem:GetAllByObjectType(GameObjectTypeDef.PlayerSelf)
    for Object, _ in pairs(tbObjects) do
        if not BotAISystem:IsBot(Object) then
            local nInstanceId = Object:GetServerInstanceId()
            local bPlayerBattleEnd = BattleResultSystem:IsPlayerBattleEnd(nInstanceId)
            if not bPlayerBattleEnd or
               tbOnlinePlayers[nInstanceId] then
                log("There are players in battle or online, nInstanceId,name:", nInstanceId, Object.szName)
                 bRet = false
                 break
            end
        end
    end

    return bRet
end

local function ClearVehicle(tbPlayer)
    local GameVehicleComponent = tbPlayer.GameVehicleComponent
    if GameVehicleComponent then
        if GameVehicleComponent:GetVehicleState() == HumanVehicleStateDef.AttachToVehicle then
            HumanVehicleHelper.ClearVehicle(tbPlayer, true)
        end
    end
end

local function PrintDebugInfo(self)
    -- self.tbPrintTimer = Timer.NewTimer(function()
    --     ResourceManager:GC()
    --     KismetSystemLibrary.CollectGarbage()
    --     printLuaDebuginfo(0)
    --     logwarning(string.format("total player count = %d", self.nPlayerAlive))
    -- end, 1, true)
end

function JGMFFASetting:OnFFAResult(tbPlayer)
    ClearVehicle(tbPlayer)

    EventManager:OnFireEvent(CommonEventDef.EV_FFA_PLAYER_WIN, tbPlayer)
end

function JGMFFASetting:StartFirstStep()
end

function JGMFFASetting:OnStartStep(tbStep)
    log("JGMFFASetting:OnStartStep")
    if self.JsonMainStep == tbStep then
        self.bWaitStage = true
        BattleDataStatisticsSystem:Deactivate()

        AIVariableSystem:SetBattleStart(false)
        -- 关闭副本内伤害
        GlobalVariableSystem:SetDungeonDamageEnabled(false)

        SendWaitStageProto(self,true)

        -- Never deal with all player logout in waiting stage.
        log("GameMode:SetCheckAllPlayerLogoutFunc always return false.")
        self.tbGameMode:SetCheckAllPlayerLogoutFunc(function() return false end)

        -- 生成新航线
        log("InitTransportPathNew")
        BattleTransporterHelper:InitTransportPath()
        BattleTransporterHelper:CreateTransport()

        -- 地图上生成资源
        log("SpawnAllItemDrop")
        -- local tbTypes = {
        --     [SpawnerDef.SpawnerType.ITEMDROP] = true,
        --     [SpawnerDef.SpawnerType.VEHICLE] = true,
        --     [SpawnerDef.SpawnerType.DESTRUCTIBLEOBJECT] = true,
        -- }

        -- SpawnerSystem:AsyncSpawnAllByType(tbTypes)
        FFAOptimizationHelper:Optimize()

        if(GlobalVariableSystem.bEnableTemplateActor) then
            BattleTemplateActorSystem:FinishInit()
        end
    end

    BattleFFANoobHelper:NoobBotSetting()
    PrintDebugInfo(self)
    JGMFFASetting.super.OnStartStep(self, tbStep)
end

function JGMFFASetting:OnPlayerReLogin(tbPlayer)
    BattleFFAReLoginHelper:OnPlayerReLogin(tbPlayer, self)
end

function JGMFFASetting:OnSnapshotGameState()
    JGMFFASetting.super.OnSnapshotGameState(self)

    SendTeamModeInfoProto(self)
    UpdateAlivePlayerCount(self)
end

function JGMFFASetting:OnFindPlayerStart(tbPlayer)
    if(self.PlayerStartAction ~= nil) then
        BattleBlackboard:SetTable(BattleOperationDef.CurrentObject, tbPlayer)
        if(false == self.PlayerStartAction:Execute()) then
            error("PlayerStartAction execute failed")
        end

        local tbPlayerStart = BattleBlackboard:GetTable(BattleOperationDef.CurrentPoint)
        BattleBlackboard:SetTable(BattleOperationDef.CurrentPoint, nil)
        BattleBlackboard:SetTable(BattleOperationDef.CurrentObject, nil)
        if(tbPlayerStart) then
            return tbPlayerStart
        end
    end

    return nil
end

local function GetBornPos(self, tbGamePlayer)
    local tbGameState = self.tbGameMode.tbGameState
    local nFFAProcessState = tbGameState.nFFAProcessState
    local nState = nFFAProcessState:Get()
    local tbPlayerStart
    if nState ~= nil and nState >= ProtoDR.rFFAProcessState_EState.PARACHUTING then
        tbPlayerStart = SelectionPointHelper:GetInBattleBornPos(tbGamePlayer)
        BattleDataStatisticsSystem:RegisterCharacter(tbGamePlayer)
    end
    if tbPlayerStart == nil then
        return self:OnFindPlayerStart(tbGamePlayer)
    end
    return tbPlayerStart
end

function JGMFFASetting:OnSpawnPlayerPawn(tbGamePlayer, bPossess)
    local tbStartJsonData = GetBornPos(self, tbGamePlayer)
    if(tbStartJsonData == nil) then
        logerror("JGMFFASetting:OnPlayerSpawnPawn failed, OnFindPlayerStart is invalid", tbGamePlayer.nPlayerId)
        return false
    end

    local tbPlayerStart = { }
    tbPlayerStart.Transform = tbStartJsonData
    tbPlayerStart.CampType = 1

    local tbPrepareInfo = tbGamePlayer.tbPrepareInfo
    local tbSpawnInfo = {}
    tbSpawnInfo.tbStartJsonData = tbPlayerStart
    tbSpawnInfo.nTemplateType = TemplateTypeDef.HUMAN
    tbSpawnInfo.nTemplateId = tbPrepareInfo.nHumanId
    local bRet = GameObjectSystem:SpawnPlayerSelfUEActorInGameMode(tbGamePlayer, tbPrepareInfo, tbSpawnInfo, bPossess)
    if(not bRet) then
        logerror("JGMFFASetting:OnPlayerSpawnPawn failed, the returned gameobject is nil", tbGamePlayer.nPlayerId)
        return false
    end

    return true
end

function JGMFFASetting:OnPlayerLogin(tbPlayer)
    if( self.PlayerLoginAction ~= nil and  self.bStartedStep ) then
        BattleBlackboard:SetTable(BattleOperationDef.CurrentObject, tbPlayer)
         if(false == self.PlayerLoginAction:Execute()) then
            error("PlayerLoginAction execute failed")
        end
        BattleBlackboard:SetTable(BattleOperationDef.CurrentObject, nil)
    end
    self.nPlayerCount = self.nPlayerCount + 1
    UpdateAlivePlayerCount(self)
    self.nTeamCount = BattleTeamSystem:GetTeamCount()
    if not AIHelper.IsAIControlled(tbPlayer) then
        SpawnPlayerInBattle(self, tbPlayer)
    else
        log("ai do not need to be in plane ", tbPlayer.szName)
    end
    JGMFFASetting.super.OnPlayerLogin(self, tbPlayer)
    BattleFFAReLoginHelper:SendDungeonAndPlayerState(tbPlayer, false)
end

function JGMFFASetting:GameOver()
    return self.bWin
end

function JGMFFASetting:OnPawnDead(tbDeadActor)
    local nInstanceId = tbDeadActor:GetServerInstanceId()
    local bBattleEnd  = BattleResultSystem:IsPlayerBattleEnd(nInstanceId)
    if tbDeadActor.ObjectType == GameObjectTypeDef.PlayerSelf and not bBattleEnd then
        MarkPlayerBattleEnd(self, tbDeadActor)
        OnPlayerDeadToast(self, tbDeadActor)
        EnterPlayerResult(self, tbDeadActor, true)
    end
end

-- 等待阶段通知队伍有队友离开
local function TeammateLeave(tbGamePlayer)
    local tbTeamMembers = BattleTeamSystem:GetTeamMembersByPlayer(tbGamePlayer)
    for _, tbPlayer in ipairs(tbTeamMembers) do
        if tbPlayer ~= tbGamePlayer then
            NetworkManager:GetRPCNetworkProxy():SendToClient(tbPlayer:GetUEControllerUniqueId(), ProtoDC.d2c_FFATeammateLeave, {})
        end
    end
end

local function OnPlayerQuitDungeon(self, tbPlayer)
    local nWinerTeamId = BattleResultSystem:GetWinerTeamId()
    local nInstanceId = tbPlayer:GetServerInstanceId()
    local bBattleEnd  = BattleResultSystem:IsPlayerBattleEnd(nInstanceId)
    if tbPlayer.ObjectType == GameObjectTypeDef.PlayerSelf and
       not BotAISystem:IsBot(tbPlayer) and
       not bBattleEnd then
        local nTeamId = BattleTeamSystem:FindTeamId(tbPlayer)
        if nWinerTeamId ~= -1 and nTeamId == nWinerTeamId then --对战已经结束, 吃鸡的人不用记录逃跑和离线
            return
        end

        local nPlayerId = tbPlayer:GetPlayerId()
        if not IsPlayerQuitDungeon(self, nTeamId, nPlayerId) then
            SetPlayerQuitDungeon(self, nTeamId, nPlayerId)
            BattleResultSystem:MarkPlayerEscape(nInstanceId)
        end
    end
end

local function ProcessPlayerQuitDungeon(self, tbPlayer, nGroupIndex)
    if tbPlayer and tbPlayer.ObjectType == GameObjectTypeDef.PlayerSelf then
        local nPlayerId   = tbPlayer:GetPlayerId()
        local nInstanceId = tbPlayer:GetServerInstanceId()
        local bDestoryActor = false
        if self:IsWaitStage() then
            local bPlayerBattleEnd = BattleResultSystem:IsPlayerBattleEnd(nInstanceId)
            if bPlayerBattleEnd then --该玩家在集合区主动退出
                self.nTeamCount = BattleTeamSystem:GetTeamCount()
                self.nPlayerCount = self.nPlayerCount - 1
                TeammateLeave(tbPlayer)

                EventManager:OnFireEvent(CommonEventDef.EV_FFA_WAIT_STAGE_LEAVE_DUNGEON , tbPlayer)
                bDestoryActor = true
            end
        else
            --战斗区主动逃跑直接干掉结算
            local nTeamId = BattleTeamSystem:FindTeamId(tbPlayer)
            if IsPlayerQuitDungeon(self, nTeamId, nPlayerId) then
                EventManager:OnFireEvent(CommonEventDef.EV_FFA_BATTLE_STAGE_LEAVE_DUNGEON , tbPlayer)
                tbPlayer:KillSelf()
            end
        end

        if bDestoryActor then
            BattleTeamSystem:RemoveMember(tbPlayer, nGroupIndex)
            GameObjectSystem:DestroyPlayerSelfInGameMode(nInstanceId)
            BattleGameModeSystem:UninitPlayerState(nPlayerId, tbPlayer)

            UpdateAlivePlayerCount(self)
        end
    end
end

--清理掉所有在集合区已经标记为结束的玩家。因为安卓机在弱网环境下，Logout收到的慢，Lobby先通知了这个人请求离开，然后Logout可能开伞后才收到，
--这个地方做一个统一清理(不能在收到Lobby通知的时候清除，因为强制清除的话，客户端表现不太对，比如收到各种弹框，菊花等)。
local function RemoveAllBattleEndPlayers(self)
    local tbBattleEndList = BattleResultSystem:GetBattleEndPlayerList()

    for nInstanceId, bBattleEnd in pairs(tbBattleEndList) do
        if bBattleEnd then
            local nTeamId = -1
            local tbPlayer = GameObjectSystem:FindByInstanceId(nInstanceId)
            if tbPlayer and tbPlayer.BattleTeamComponent then
                nTeamId = tbPlayer.BattleTeamComponent.nTeamId
            end

            if nTeamId ~= -1 then
                ProcessPlayerQuitDungeon(self, tbPlayer, nTeamId)
            end
        end
    end
end

function JGMFFASetting:OnFFAWaitStageEnd()
    RemoveAllBattleEndPlayers(self)

    self.bWaitStage = false

    AIVariableSystem:SetBattleStart(true)
    -- 启用副本内伤害
    GlobalVariableSystem:SetDungeonDamageEnabled(true)

   RemoveAllPlayerBuffs(self)
   BattleFFANoobHelper:AddNoobSpecialBuffs()
   SendWaitStageProto(self, false)
   SendTeamModeInfoProto(self)
    -- Recover to normal player logout func.
    local tbGameMode = self.tbGameMode
    log("OnFFAWaitStageEnd")
    tbGameMode:SetCheckAllPlayerLogoutFunc(function() return OnFFACheckAllPlayerLogoutFunc(self) end)

    if(tbGameMode:CheckAllPlayerLogout()) then
        log("JGMFFASetting:OnFFAWaitStageEnd No player exists. Send out all player logout event.")
        ForceReleaseDungeon(self)
    end
end

function JGMFFASetting:OnPlayerPostLogout(nPlayerId, nGroupIndex)
    local tbPlayer = GameObjectSystem:FindPlayerByPlayerId(nPlayerId)
    ProcessPlayerQuitDungeon(self, tbPlayer, nGroupIndex)
end

function JGMFFASetting:NotifyPlayerLeave(tbPlayer)
    log("JGMFFASetting:NotifyPlayerLeave")

    OnPlayerQuitDungeon(self, tbPlayer)

    if self:IsWaitStage() then
        MarkPlayerBattleEnd(self, tbPlayer)
    end

    --如果此玩家已经Logout，则调用ProcessPlayerQuitDungeon
    local nInstanceId = tbPlayer:GetServerInstanceId()
    local bFind = false
    local tbOnlinePlayers = self.tbGameMode.tbPlayers
    for nIndex, tbCurPlayer in ipairs(tbOnlinePlayers) do
        local nCurInstanceId = tbCurPlayer:GetServerInstanceId()
        if nInstanceId == nCurInstanceId then
            bFind = true
            break
        end
    end

    if not bFind then
        local nTeamId = -1
        if tbPlayer and tbPlayer.BattleTeamComponent then
            nTeamId = tbPlayer.BattleTeamComponent.nTeamId
        end

        if nTeamId ~= -1 then
            ProcessPlayerQuitDungeon(self, tbPlayer, nTeamId)
        else
            logerror("JGMFFASetting:NotifyPlayerLeave nTeamId == -1 PlayerName:", tbPlayer.szName)
        end
    end
end

--踢人逻辑
function JGMFFASetting:OnKickPlayer(tbPlayer)
    log("JGMFFASetting:OnKickPlayer", tbPlayer.szName)
    OnPlayerQuitDungeon(self, tbPlayer)

    if self:IsWaitStage() then
        MarkPlayerBattleEnd(self, tbPlayer)
    end
end

--对所有没有标记BattleEnd的非死亡玩家强制KillSelf
function JGMFFASetting:OnForceReleaseDungeon()
    log("OnForceReleaseDungeon")
    ForceReleaseDungeon(self)
end

return JGMFFASetting
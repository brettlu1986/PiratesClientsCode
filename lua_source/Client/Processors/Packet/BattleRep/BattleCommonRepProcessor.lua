local luaclass = require("luaclass")
local NetMessageProcessorBase = require("NetMessageProcessorBase")
local BattleCommonRepProcessor = luaclass("BattleCommonRepProcessor", NetMessageProcessorBase)

local NetworkManager = dynamic_require("NetworkManager")
local Proto = require("DungeonRepProtoNames")
local BattleGameModeSystem = dynamic_require("BattleGameModeSystem")
local GlobalVariableSystem = require("GlobalVariableSystem_C")
local EventManager = require("EventManager")
local ClientEventDef = require("ClientEventDef")
local InteractionSystem = require("InteractionSystem")
local ToastSystem = require("ToastSystem")
local ResourceCacheSystem = require("ResourceCacheSystem")
--local ReplicatedPropertyGenerateSystem = require("ReplicatedPropertyGenerateSystem")
--local ReconnectSystem = require("ReconnectSystemNew")

--BattleCommonRepProcessor.pGameState = nil
BattleCommonRepProcessor.OnActorChannelOpenHandle = nil
BattleCommonRepProcessor.WaitingTeamMemberCreateHandle = nil

local bServer = false

-- 注册处理包
function BattleCommonRepProcessor:RegisterPackets()
    self.OnActorChannelOpenHandle = function(pGameState)
        self:OnGameStateActorChannelOpen(pGameState)
    end
    EventManager:BindEvent(ClientEventDef.EV_GAME_STATE_ON_ACTOR_CHANNEL_OPEN, self.OnActorChannelOpenHandle)

    self:BindMethod(Proto.rGameStateBaseInfo, self, self.OnRepGameStateBaseInfo)
    self:BindMethod(Proto.rNeededResources, self, self.OnRepNeededResources)
    self:BindMethod(Proto.rTeamScores, self, self.OnRepTeamScores)
    self:BindMethod(Proto.rStepRemainTime, self, self.OnRepStepRemainTime)
    self:BindMethod(Proto.rCurrentStepInfo, self, self.OnRepCurrentStepInfo)
    self:BindMethod(Proto.rBattleTimerStepInfo, self, self.OnRepBattleTimerStepInfo)
    self:BindMethod(Proto.rBattlePlayerResultStep, self, self.OnRepBattlePlayerResultStep)
    self:BindMethod(Proto.rCurrentObjective, self, self.OnRepCurrentObjective)
    self:BindMethod(Proto.rCurrentStatisticsDatas, self, self.OnRepCurrentStatisticsDatas)
    self:BindMethod(Proto.rTargetTrackInfoAndIsShow, self, self.OnRepTargetTrackInfoAndIsShow)
    self:BindMethod(Proto.rBattleSpecialToast, self, self.OnRepSpecialToast)
    self:BindMethod(Proto.rBattleNpcInteraction, self, self.OnRepNpcChangeInteraction)
    self:BindMethod(Proto.rJsonMainStepInfo, self, self.OnJsonMainStepInfo)
    self:BindMethod(Proto.rBotInfo, self, self.OnBotInfo)

end

-- 初始化
function BattleCommonRepProcessor:Init()
    BattleCommonRepProcessor.super.Init(self)

    bServer = GlobalVariableSystem:IsStandaloneServer()
    -- self.pGameState = nil
    self:SetBinder(NetworkManager:GetRPCNetworkProxy())
    self:RegisterPackets()
    return true
end

function BattleCommonRepProcessor:Uninit()
    -- self.pGameState = nil
    if(self.OnActorChannelOpenHandle) then
        EventManager:UnBindEvent(ClientEventDef.EV_GAME_STATE_ON_ACTOR_CHANNEL_OPEN, self.OnActorChannelOpenHandle)
        self.OnActorChannelOpenHandle = nil
    end
    self:UnbindGameObjectCreateEvent()

    BattleCommonRepProcessor.super.Uninit(self)
end

function BattleCommonRepProcessor:OnGameStateActorChannelOpen(pGameState)
    local _tbDungeonData, tbDugeonTypeData = BattleGameModeSystem:GetDungeonTemplateData()
    if(tbDugeonTypeData.szGameStateClass == nil) then
        return
    end

    BattleGameModeSystem:InitGameState(pGameState, tbDugeonTypeData.szGameStateClass)
end

-- function BattleCommonRepProcessor:GetUEGameState()
--     return self.pGameState
-- end

function BattleCommonRepProcessor:OnRepGameStateBaseInfo(tbPacket)
    if(bServer) then
        -- EventManager:OnFireEvent(ClientEventDef.EV_GAME_STATE_ON_RECV_BASE_INFO,
        --     BattleGameModeSystem:GetGameState().rGameStateBaseInfo)
        return
    end

    -- if(BattleGameModeSystem:GetGameState() ~= nil) then
    --     -- Server logic
    --     return
    -- end

    -- local nDungeonId = tbPacket.nDungeonId
    -- local _tbDungeonData, tbDugeonTypeData = BattleGameModeSystem:GetDungeonTemplateData(nDungeonId)
    -- if(tbDugeonTypeData.szGameStateClass == nil) then
    --     return
    -- end

    -- local pGameState = self:GetUEGameState()
    -- if(pGameState == nil) then
    --     error("BattleCommonRepProcessor:OnRepGameStateBaseInfo falied".. nDungeonId)
    --     return
    -- end

    -- BattleGameModeSystem.nDungeonId = nDungeonId
    --local tbGameState = BattleGameModeSystem:InitGameState(pGameState, tbDugeonTypeData.szGameStateClass)

    local tbGameState = BattleGameModeSystem:GetGameState()
    assert(tbGameState)

    tbGameState.rGameStateBaseInfo = tbPacket

    -- if(BattleGameModeSystem.bRetraveling) then
    --     BattleGameModeSystem.bRetraveling = false
    -- else
    --     if(not ReplicatedPropertyGenerateSystem:CheckReplicationCRC(tbGameState.pGameState)) then
    --         ReconnectSystem:OnRepPropTypeMismatch()
    --         return
    --     end
    -- end

    -- EventManager:OnFireEvent(ClientEventDef.EV_REPLICATION_CRC_CHECK_SUCCESS)

    --EventManager:OnFireEvent(ClientEventDef.EV_GAME_STATE_ON_RECV_BASE_INFO, tbPacket)
end

function BattleCommonRepProcessor:OnRepNeededResources(tbPacket)
    ResourceCacheSystem:CacheDungeonResources(tbPacket.tbResources)
end

function BattleCommonRepProcessor:OnGameObjectCreate(tbGameObject)
    self:UnbindGameObjectCreateEvent()
end

function BattleCommonRepProcessor:BindGameObjectCreateEvent()
    if(self.WaitingTeamMemberCreateHandle == nil) then
        self.WaitingTeamMemberCreateHandle = function(tbGameObject)
            self:OnGameObjectCreate(tbGameObject)
        end
        EventManager:BindEvent(ClientEventDef.EV_GAME_OBJECT_BEGIN_PLAY, self.WaitingTeamMemberCreateHandle)
    end
end

function BattleCommonRepProcessor:UnbindGameObjectCreateEvent()
    if(self.WaitingTeamMemberCreateHandle) then
        EventManager:UnBindEvent(ClientEventDef.EV_GAME_OBJECT_BEGIN_PLAY, self.WaitingTeamMemberCreateHandle)
        self.WaitingTeamMemberCreateHandle = nil
    end
end

function BattleCommonRepProcessor:OnRepTeamScores(tbPacket)
    local tbGameState = BattleGameModeSystem:GetGameState()
    if(not bServer) then
        tbGameState.rTeamScores = tbPacket
    end
    EventManager:OnFireEvent(ClientEventDef.EV_GAME_STATE_ON_RECV_TEAM_SCORES, tbPacket)
end

function BattleCommonRepProcessor:OnRepStepRemainTime(tbPacket)
    local tbGameState = BattleGameModeSystem:GetGameState()
    if(not bServer) then
        tbGameState.rStepRemainTime = tbPacket
    end
    EventManager:OnFireEvent(ClientEventDef.EV_GAME_STATE_ON_RECV_STEP_REMAIN_TIME, tbPacket)
end

function BattleCommonRepProcessor:OnRepCurrentStepInfo(tbPacket)
    local tbGameState = BattleGameModeSystem:GetGameState()
    if(not bServer) then
        tbGameState.rCurrentStepInfo = tbPacket
    end

    if(tbGameState.rGameStateBaseInfo) then
        EventManager:OnFireEvent(ClientEventDef.EV_GAME_STATE_ON_RECV_STEP_INFO, tbPacket)
    end
end

function BattleCommonRepProcessor:OnRepCurrentObjective(tbPacket)
    local tbGameState = BattleGameModeSystem:GetGameState()
    if(not bServer) then
        tbGameState.rCurrentObjective = tbPacket
    end
    EventManager:OnFireEvent(ClientEventDef.EV_GAME_STATE_ON_RECV_OBJECTIVE, tbPacket)
end

function BattleCommonRepProcessor:OnRepCurrentStatisticsDatas(tbPacket)
    local tbGameState = BattleGameModeSystem:GetGameState()
    if(not bServer) then
        tbGameState.rCurrentStatisticsDatas = tbPacket
    end
--    EventManager:OnFireEvent(ClientEventDef.EV_GAME_STATE_ON_RECV_STATISTICS_DATAS, tbPacket)
end

function BattleCommonRepProcessor:OnRepBattleTimerStepInfo(tbPacket)
    local tbGameState = BattleGameModeSystem:GetGameState()
    if(not bServer) then
        tbGameState.rBattleTimerStepInfo = tbPacket
    end
end

function BattleCommonRepProcessor:OnRepBattlePlayerResultStep(tbPacket)
    local tbGameState = BattleGameModeSystem:GetGameState()
    if(not bServer) then
        tbGameState.rBattlePlayerResultStep = tbPacket
    end
end

function BattleCommonRepProcessor:OnRepTargetTrackInfoAndIsShow(tbPacket)
    EventManager:OnFireEvent(ClientEventDef.EV_BATTLE_SHOW_TARGETTRACK, tbPacket.nEffectServerInstanceId,
                            tbPacket.nTargetServerInstanceId, tbPacket.nX, tbPacket.nY, tbPacket.nZ, tbPacket.bIsVisible)
end


function BattleCommonRepProcessor:OnRepSpecialToast(tbPacket)
    local tbInfo = tbPacket.tbInfo
    ToastSystem:ShowToast(
        tbInfo.nServerInstanceId,
        tbInfo.nToastId,
        tbInfo.szParam0,
        tbInfo.szParam1,
        tbInfo.szParam2,
        tbInfo.nToastType,
        tbInfo.nCampType,
        tbInfo.nWaitTime)
end

function BattleCommonRepProcessor:OnRepNpcChangeInteraction(tbPacket)
   InteractionSystem:OnChangeInteraction(tbPacket.nServerInstanceId, tbPacket.bIsInteraction)
end

function BattleCommonRepProcessor:OnJsonMainStepInfo(tbPacket)
    local tbGameState = BattleGameModeSystem:GetGameState()
    if(not bServer) then
        tbGameState.rJsonMainStepInfo = tbPacket
    end
    EventManager:OnFireEvent(ClientEventDef.EV_GAME_STATE_ON_RECV_JSON_MAIN_STEP_INFO, tbPacket)
end

function BattleCommonRepProcessor:OnBotInfo(tbPacket)
    local tbGameState = BattleGameModeSystem:GetGameState()
    if(not bServer) then
        tbGameState.rBotInfo = tbPacket
    end
end

return BattleCommonRepProcessor

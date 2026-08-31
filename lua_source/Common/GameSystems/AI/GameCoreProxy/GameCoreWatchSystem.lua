local luaclass = require("luaclass")
local GameCoreWatchSystem   = luaclass("GameCoreWatchSystem")
local SelfEventHelperClass  = require("SelfEventHelper")
local NetworkManager        = dynamic_require("NetworkManager")
local ProtoDC               = require("DungeonCommonProtoNames")
local CommonEventDef        = require("CommonEventDef")
local GameObjectSystem      = dynamic_require("GameObjectSystem")
local GameCoreProxyClient   = require("GameCoreProxyClient")
local BattleTemplateActorSystem = dynamic_require("BattleTemplateActorSystem")


GameCoreWatchSystem.tbWatchMap = nil
GameCoreWatchSystem.SelfEventHelper = nil

GameCoreWatchSystem.nCurrentWatchIndex = -1
GameCoreWatchSystem.nCurrentWatchId = -1

GameCoreWatchSystem.bEnabled = false

-- luacheck: push ignore
local function LOG(...)
    log("CJ->GameCoreWatchSystem:", ...)
end
-- luacheck: pop

local function OnBattleInfoChanged(self, tbGameObject)
    if self.bEnabled then
        self:RepTeamateInfo(tbGameObject)
    end
end

function GameCoreWatchSystem:RepTeamateInfo(tbGameObject)
    local nSourceServerInstanceId = tbGameObject.nServerInstanceId
    local tbWatchList = self.tbWatchMap[nSourceServerInstanceId]
    if tbWatchList and #tbWatchList > 0 then
        --logdebug("send watch team info ", tbGameObject.szName)
        local tbPacket = { }
        local tbTeammates = { }
        local tbTeamdata = tbGameObject.BattleTeamComponent.tbTeamdata
        for i,v in ipairs(tbTeamdata) do
            local tbMemberInfo = { }
            tbMemberInfo.nInstanceId  = v.nInstanceId;
            tbMemberInfo.nHp          = v.nHp;
            tbMemberInfo.nMaxHp       = v.nMaxHp;
            tbMemberInfo.nState       = v.nState;
            tbMemberInfo.SignType     = v.SignType;
            tbMemberInfo.nGenderType  = v.nGenderType;
            tbMemberInfo.name         = v.name;
            table.insert(tbTeammates, tbMemberInfo)
        end
        tbPacket.teammates = tbTeammates
        for i,v in ipairs(tbWatchList) do
            NetworkManager:GetRPCNetworkProxy():SendToClient(v:GetUEControllerUniqueId(), ProtoDC.d2c_GameCoreTeammates,
            tbPacket)
        end
    end
end

function GameCoreWatchSystem:Init()
    self.tbWatchMap = { }
    local SelfEventHelper = SelfEventHelperClass()
    self.SelfEventHelper = SelfEventHelper
    SelfEventHelper:RegisterEvent(CommonEventDef.EV_BATTLE_TEAMINFO_CHANGED, self, OnBattleInfoChanged)
end

function GameCoreWatchSystem:AddWatch(tbSource, tbWatcher)
    if self.bEnabled then
        self:RemoveWatch(tbWatcher)
        local nSourceServerInstanceId = tbSource.nServerInstanceId
        local tbWatchList = self.tbWatchMap[nSourceServerInstanceId] or { }
        for i,v in ipairs(tbWatchList) do
            if v == tbWatcher then
                return
            end
        end
        table.insert( tbWatchList, tbWatcher)
        self.tbWatchMap[nSourceServerInstanceId] = tbWatchList
        LOG("add watch ", tbSource.szName, tbWatcher.szName)
        self:RepTeamateInfo(tbSource)
    end
end

function GameCoreWatchSystem:HasWacther(tbSource)
    local nSourceServerInstanceId = tbSource.nServerInstanceId
    return self.tbWatchMap[nSourceServerInstanceId] and #self.tbWatchMap[nSourceServerInstanceId] > 0
end

function GameCoreWatchSystem:RemoveWatch(tbWatcher)
    for k,tbWatchList in pairs(self.tbWatchMap) do
        for i,v in ipairs(tbWatchList) do
            if v == tbWatcher then
                table.remove(tbWatchList, i)
                LOG("remove watch ", tbWatcher.szName)
                break
            end
        end
    end
end

function GameCoreWatchSystem:RepSourceStatus(tbSource, tbPacket)
    if self.bEnabled then
        local nSourceServerInstanceId = tbSource.nServerInstanceId
        local tbWatchList = self.tbWatchMap[nSourceServerInstanceId]
        if tbWatchList then
            for i,v in ipairs(tbWatchList) do
                NetworkManager:GetRPCNetworkProxy():SendToClient(v:GetUEControllerUniqueId(), ProtoDC.d2c_GameCoreAIBotStatus,
                tbPacket)
            end
        end
    end
end

function GameCoreWatchSystem:Uninit()
    self.SelfEventHelper:UnregisterAll()
    self.tbWatchMap = { }
end

function GameCoreWatchSystem:WatchBotByIndex(nSenderUniqueId, nWatchIndex)
    self.bEnabled = true
    self.nCurrentWatchIndex = -1
    self.nCurrentWatchId = -1
    local nVehicleInstanceId = 0

    local tbWatchObj = nil
    local tbAgent = GameCoreProxyClient.tbAgents[nWatchIndex]
    if tbAgent then
        tbWatchObj = tbAgent:GetGameObject()
    end

    if tbWatchObj then
        local PlayerSelf = GameObjectSystem:FindByUniqueId(nSenderUniqueId)
        local pSelfController = PlayerSelf.pUEActor:GetController()

        self.nCurrentWatchIndex = nWatchIndex
        self.nCurrentWatchId = tbWatchObj:GetServerInstanceId()
        local pWatchActor = tbWatchObj.pUEActor
        local pVehicleActor = nil

        local tbPlayer = GameObjectSystem:FindByUniqueId(nSenderUniqueId)
        BattleTemplateActorSystem:SetWatchedTarget(tbPlayer, tbWatchObj)
        
        local GameVehicleComponent = tbWatchObj.GameVehicleComponent
        if GameVehicleComponent then
            nVehicleInstanceId = GameVehicleComponent:GetVehicleInstanceId()
            local tbVehicle = GameVehicleComponent:GetVehicle()
            if tbVehicle and tbVehicle.pUEActor then
                pVehicleActor = tbVehicle.pUEActor
            end
        end

        if pVehicleActor then
            PiratesReplicationBPHelpers.SetActorReplicateToController(pSelfController, pVehicleActor, true)
        end
        PiratesReplicationBPHelpers.SetActorReplicateToController(pSelfController, pWatchActor, true)
    end
    NetworkManager:GetRPCNetworkProxy():SendToClient(nSenderUniqueId, ProtoDC.d2c_ToggleBotResult, { nBotInstanceId = self.nCurrentWatchId, nVehicleInstanceId = nVehicleInstanceId })
end

function GameCoreWatchSystem:WatchBotById(nSenderUniqueId, nWatchInstanceId)
    self.bEnabled = true
    self.nCurrentWatchIndex = -1
    self.nCurrentWatchId = -1
    local nVehicleInstanceId = 0

    local tbWatchObj = GameObjectSystem:FindByInstanceId(nWatchInstanceId)
    if tbWatchObj then
        local PlayerSelf = GameObjectSystem:FindByUniqueId(nSenderUniqueId)
        local pSelfController = PlayerSelf.pUEActor:GetController()
        self.nCurrentWatchId = nWatchInstanceId
        local pWatchActor = tbWatchObj.pUEActor
        local pVehicleActor = nil
        local tbPlayer = GameObjectSystem:FindByUniqueId(nSenderUniqueId)
        BattleTemplateActorSystem:SetWatchedTarget(tbPlayer, tbWatchObj)
        
        
        local GameVehicleComponent = tbWatchObj.GameVehicleComponent
        if GameVehicleComponent then
            nVehicleInstanceId = GameVehicleComponent:GetVehicleInstanceId()
            local tbVehicle = GameVehicleComponent:GetVehicle()
            if tbVehicle and tbVehicle.pUEActor then
                pVehicleActor = tbVehicle.pUEActor
            end
        end

        if pVehicleActor then
            PiratesReplicationBPHelpers.SetActorReplicateToController(pSelfController, pVehicleActor, true)
        end
        PiratesReplicationBPHelpers.SetActorReplicateToController(pSelfController, pWatchActor, true)
    end

    NetworkManager:GetRPCNetworkProxy():SendToClient(nSenderUniqueId, ProtoDC.d2c_ToggleBotResult, { nBotInstanceId = self.nCurrentWatchId, nVehicleInstanceId = nVehicleInstanceId })
end

return GameCoreWatchSystem()
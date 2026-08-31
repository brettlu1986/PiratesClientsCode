-- ffa毒圈阶段step

local luaclass = require("luaclass")
local BattleTargetActionStep = require("BattleTargetActionStep")
local FFASelectionPointStep = luaclass("FFASelectionPointStep", BattleTargetActionStep)

local CommonEventDef = require("CommonEventDef")
--local EventManager = require("EventManager")
local NetworkManager = dynamic_require("NetworkManager")
local ProtoDC = require("DungeonCommonProtoNames")
local ProtoDR = require("DungeonRepProtoNames")
local SelectionPointHelper = require("SelectionPointHelper")
local BitHelper = require("BitHelper")
local BattleGameModeSystem = dynamic_require("BattleGameModeSystem")
local BattleTeamSystem = require("BattleTeamSystem")
local COORDINATE_PROPORTION = 100

FFASelectionPointStep.bAutoSelect = nil


function FFASelectionPointStep:Init()
    FFASelectionPointStep.super.Init(self)

    self.szName = "FFASelectionPointStep"
end

function FFASelectionPointStep:Parse(tbJsonData)
    if(not FFASelectionPointStep.super.Parse(self, tbJsonData)) then
        return false
    end

    return true
end

local function OnSelectionPoint(self, tbPacket, bSelected)
    local tbGameState = BattleGameModeSystem:GetGameState()    
    local nFFAProcessState = tbGameState.nFFAProcessState
    local nState = nFFAProcessState:Get() 
    if nState >= ProtoDR.rFFAProcessState_EState.SELECTION_LOCK then
        return
    end

    if bSelected then
        local nX = math.floor(tbPacket.nX / COORDINATE_PROPORTION) 
        local nY = math.floor(tbPacket.nY / COORDINATE_PROPORTION)
        local nPos = BitHelper:XYToPos(nX, nY)
        local nOldTransporterId = SelectionPointHelper:GetSelectedTransporterId(tbPacket.nInstanceId)
        local nNewTransporterId = SelectionPointHelper:ManualSelectionPoint(tbPacket.nInstanceId, nPos, nX, nY)

        local d2c_FFASelectionPoint = {PointInfos={}}
        local tbData = {}
        tbData.nInstanceId = tbPacket.nInstanceId
        tbData.nPos = nPos
        table.insert(d2c_FFASelectionPoint.PointInfos, tbData)
        
        if SelectionPointHelper:GetHideOtherSelectionPoint() then
            local nTeamId = BattleTeamSystem:FindTeamIdByInstanceId(tbPacket.nInstanceId)
            local tbTeamMembers = BattleTeamSystem:GetTeamMembers(nTeamId)
            local RPCNetworkProxy = NetworkManager:GetRPCNetworkProxy()
            if tbTeamMembers ~= nil then
                for _, tbTeamMember in pairs(tbTeamMembers) do
                    RPCNetworkProxy:SendToClient(tbTeamMember:GetUEControllerUniqueId(), ProtoDC.d2c_FFASelectionPoint, d2c_FFASelectionPoint)
                end
            end

            if nOldTransporterId ~= nil then
                if nOldTransporterId ~= nNewTransporterId then
                    SelectionPointHelper:SendTransporterPlayerCount(nOldTransporterId)
                    SelectionPointHelper:SendTransporterPlayerCount(nNewTransporterId)
                end
            else
                SelectionPointHelper:SendTransporterPlayerCount(nNewTransporterId)
            end
        else    
            NetworkManager:GetRPCNetworkProxy():Multicast(ProtoDC.d2c_FFASelectionPoint, d2c_FFASelectionPoint, false)
        end
    else
        if SelectionPointHelper:CancelSelectionPoint(tbPacket.nInstanceId) then
            local d2c_FFACancelSelectionPoint = {nInstanceId = tbPacket.nInstanceId}
            local nTeamId = BattleTeamSystem:FindTeamIdByInstanceId(tbPacket.nInstanceId)
            local tbTeamMembers = BattleTeamSystem:GetTeamMembers(nTeamId)
            local RPCNetworkProxy = NetworkManager:GetRPCNetworkProxy()
            if tbTeamMembers ~= nil then
                for _, tbTeamMember in pairs(tbTeamMembers) do
                    RPCNetworkProxy:SendToClient(tbTeamMember:GetUEControllerUniqueId(), ProtoDC.d2c_FFACancelSelectionPoint, d2c_FFACancelSelectionPoint)
                end
            end
        end
    end
end

local function OnProcessStateChanged(self, nState)
    if nState == ProtoDR.rFFAProcessState_EState.SELECTION_LOCK or nState == ProtoDR.rFFAProcessState_EState.MATINEE then
        if not self.bAutoSelect then 
            SelectionPointHelper:AutoSelectionPoint()
            self.bAutoSelect = true
        end
    end
end

local function OnEnterPlayerSelectPoint(self, nState, tbPlayer)
    if nState == ProtoDR.rFFAProcessState_EState.SELECTION_LOCK then
        local tbData = SelectionPointHelper:SelectionPoint(tbPlayer)

        local d2c_FFASelectionPoint = {PointInfos={}}
        table.insert(d2c_FFASelectionPoint.PointInfos, tbData)

        if SelectionPointHelper:GetHideOtherSelectionPoint() then
            local tbTeamMembers = BattleTeamSystem:GetTeamMembersByPlayer(tbPlayer)
            local RPCNetworkProxy = NetworkManager:GetRPCNetworkProxy()
            if tbTeamMembers ~= nil then
                for _, tbTeamMember in pairs(tbTeamMembers) do
                    RPCNetworkProxy:SendToClient(tbTeamMember:GetUEControllerUniqueId(), ProtoDC.d2c_FFASelectionPoint, d2c_FFASelectionPoint)
                end
            end
            SelectionPointHelper:SendTransporterPlayerCountByPlayer(tbPlayer)
        else    
            NetworkManager:GetRPCNetworkProxy():Multicast(ProtoDC.d2c_FFASelectionPoint, d2c_FFASelectionPoint, false)
        end
    end
end

function FFASelectionPointStep:RegisterEvent()
    FFASelectionPointStep.super.RegisterEvent(self)

    self.SelfEventHelper:RegisterEvent(CommonEventDef.EV_FFA_SELECTION_POINT, self, OnSelectionPoint)
    self.SelfEventHelper:RegisterEvent(CommonEventDef.EV_FFA_PROCESS_STATE_CHANGED, self, OnProcessStateChanged)
    self.SelfEventHelper:RegisterEvent(CommonEventDef.EV_FFA_ENTERPLAYER_SELECTPOINT, self, OnEnterPlayerSelectPoint)
end

function FFASelectionPointStep:UnregisterEvent()
    FFASelectionPointStep.super.UnregisterEvent(self)
end

function FFASelectionPointStep:Start()  
    FFASelectionPointStep.super.Start(self)
end

function FFASelectionPointStep:Uninit()
    self.bAutoSelect = nil    
    FFASelectionPointStep.super.Uninit(self)
end

function FFASelectionPointStep:ForceStop()
    FFASelectionPointStep.super.ForceStop(self)
end

function FFASelectionPointStep:OnCompleted()
    FFASelectionPointStep.super.OnCompleted(self)
end

function FFASelectionPointStep:RepStepInfo(bRepNow)
    FFASelectionPointStep.super.RepStepInfo(self, bRepNow)
end

-- 子类必须重载，将当前状态的快照写入replicate属性中，这里可根据情况调用rep，这函数会在新玩家登入时调用
function FFASelectionPointStep:SnapshotToReplicatedProperty()
    self:RepStepInfo()
    return true
end

return FFASelectionPointStep
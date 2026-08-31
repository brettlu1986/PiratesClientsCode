local luaclass = require("luaclass")
local NetMessageProcessorBase = require("NetMessageProcessorBase")
local PVPOccupyRepProcessor = luaclass("PVPOccupyRepProcessor", NetMessageProcessorBase)

local NetworkManager = dynamic_require("NetworkManager")
local Proto = require("DungeonRepProtoNames")
local BattleGameModeSystem = dynamic_require("BattleGameModeSystem")
local GlobalVariableSystem = require("GlobalVariableSystem_C")
local EventManager = require("EventManager")
local ClientEventDef = require("ClientEventDef")

local bServer = false

-- 注册处理包
function PVPOccupyRepProcessor:RegisterPackets()
    self:BindMethod(Proto.rPVPOccupyChangedAreaState, self, self.OnRepPVPOccupyChangedAreaState)
    self:BindMethod(Proto.rPVPOccupyStepInfo, self, self.OnRepPVPOccupyStepInfo)
end

-- 初始化
function PVPOccupyRepProcessor:Init()
    PVPOccupyRepProcessor.super.Init(self)

    bServer = GlobalVariableSystem:IsStandaloneServer()
    self:SetBinder(NetworkManager:GetRPCNetworkProxy())
    self:RegisterPackets()
    return true
end

function PVPOccupyRepProcessor:OnRepPVPOccupyChangedAreaState(tbPacket)
    local tbGameState = BattleGameModeSystem:GetGameState()
    if(not bServer) then
        local tbSavedAreas = tbGameState.tbPVPAllAreaState
        local tbChangedAreas = tbPacket.Areas
        local nChangedCount = #tbChangedAreas
        local tbChangedArea

        for i=1, nChangedCount do
            tbChangedArea = tbChangedAreas[i]
            tbSavedAreas[tbChangedArea.nAreaIndex] = tbChangedArea
        end
    end
    EventManager:OnFireEvent(ClientEventDef.EV_GAME_STATE_ON_RECV_PVP_OCCUPY_AREA_STATE, tbPacket)
end

function PVPOccupyRepProcessor:OnRepPVPOccupyStepInfo(tbPacket)
    local tbGameState = BattleGameModeSystem:GetGameState()
    if(not bServer) then
        tbGameState.rPVPOccupyStepInfo = tbPacket
    end
end

return PVPOccupyRepProcessor

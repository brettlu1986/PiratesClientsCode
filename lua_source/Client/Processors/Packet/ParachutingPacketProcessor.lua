--
local luaclass = require("luaclass")
local NetMessageProcessorBase = require("NetMessageProcessorBase")
local ParachutingPacktProcessor = luaclass("ParachutingPacktProcessor", NetMessageProcessorBase)
local Proto = require("DungeonCommonProtoNames")
local GlobalVariableSystem = dynamic_require("GlobalVariableSystem")
local NetworkManager = dynamic_require("NetworkManager")
local ParachutionSystem = require("ParachutionSystem_C")
local BitHelper = require("BitHelper")
local EventManager = require("EventManager")
local ClientEventDef = require("ClientEventDef")

local COORDINATE_PROPORTION = 100

local function OnParachutionEnd(self, tbPacket)
    if (not GlobalVariableSystem:IsStandalone()) then
        ParachutionSystem:OnParachutionEnd(tbPacket.is_ship)
        -- EventManager:OnFireEvent(ClientEventDef.EV_FFA_PARACHUTION_END, tbPacket.is_ship)
    end
end

local function OnFFASelectionPoint(self, tbPacket)
    for i, v in ipairs(tbPacket.PointInfos) do
        local nX, nY = BitHelper:PosToXY(v.nPos)
        v.nX = nX * COORDINATE_PROPORTION
        v.nY = nY * COORDINATE_PROPORTION
    end
    ParachutionSystem:OnFFASelectPoint(tbPacket)
    -- EventManager:OnFireEvent(ClientEventDef.EV_FFA_SELECT_POINT, tbPacket)
end

local function OnFFACancelSelectionPoint(self, tbPacket)
    ParachutionSystem:OnFFACancelSelectPoint(tbPacket.nInstanceId)
end

local function OnFFATransporterPlayerCount(self, tbPacket)
    EventManager:OnFireEvent(ClientEventDef.EV_FFA_SELECT_TRANSPORTER_PLAYER_COUNT, tbPacket.nCount)
end

-- 注册处理包
function ParachutingPacktProcessor:RegisterPackets()
    local tbProxy = NetworkManager:GetRPCNetworkProxy()
    self:SetBinder(tbProxy)
    self:BindMethod(Proto.d2c_ParachutionEnd, self, OnParachutionEnd)
    self:BindMethod(Proto.d2c_FFASelectionPoint, self, OnFFASelectionPoint)
    self:BindMethod(Proto.d2c_FFATransporterPlayerCount, self, OnFFATransporterPlayerCount)
    self:BindMethod(Proto.d2c_FFACancelSelectionPoint, self, OnFFACancelSelectionPoint)
end

-- 初始化
function ParachutingPacktProcessor:Init()
    ParachutingPacktProcessor.super.Init(self)
    self:RegisterPackets()
    return true
end

-- 结束
function ParachutingPacktProcessor:Uninit()
    ParachutingPacktProcessor.super.Uninit(self)
end

return ParachutingPacktProcessor
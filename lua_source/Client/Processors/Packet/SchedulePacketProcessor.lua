-- 活动相关的消息
local luaclass = require("luaclass")
local NetMessageProcessorBase = require("NetMessageProcessorBase")
local SchedulePacketProcessor = luaclass("SchedulePacketProcessor", NetMessageProcessorBase)

local NetworkManager = dynamic_require("NetworkManager")
local Proto = require("ClientProtoNames")
local ScheduleSystem = require("ScheduleSystem")
local LobbyPopWndHelper = require("LobbyPopWndHelper")

local function OnRecvNoobLogin(self, tbPacket)
    ScheduleSystem:RecvNoobLogin(tbPacket)
end

local function OnRecvGetNoobLoginAward(self, tbPacket)
    ScheduleSystem:RecvGetNoobLoginAward(tbPacket)
end

local function OnRecvBattleStar(self, tbPacket)
    ScheduleSystem:RecvBattleStar(tbPacket)
end

local function OnRecvSevenDayCheckIn(self, tbPacket)
    ScheduleSystem:RecvSevenDayCheckIn(tbPacket)
end

local function OnRecvSevenDayGetReward(self, tbPacket)
    ScheduleSystem:RecvSevenDayGetReward(tbPacket)
end

local function OnRecvGetTimedAwardInfo(self, tbPacket)
    ScheduleSystem:RecvGetTimedAwardInfo(tbPacket)
end

local function OnRecvTimedAward(self, tbPacket)
    ScheduleSystem:RecvTimedAward(tbPacket)
end

local function OnRecvGetContinuousSchedule(self, tbPacket)
    ScheduleSystem:RecvGetContinuousSchedule(tbPacket)
end

local function OnRecvReceiveContinuousAward(self, tbPacket)
    ScheduleSystem:RecvReceiveContinuousAward(tbPacket)
end

local function OnRecvGetDrawActivityInfo(self, tbPacket)
    ScheduleSystem:DispatchMessage(Proto.s2c_GetDrawActivityInfo, tbPacket)
end

local function OnRecvGetBoxActivityInfo(self, tbPacket)
    ScheduleSystem:DispatchMessage(Proto.s2c_GetBoxActivityInfo, tbPacket)
end

local function OnRecvGetRollActivityInfo(self, tbPacket)
    ScheduleSystem:DispatchMessage(Proto.s2c_GetRollActivityInfo, tbPacket)
end

local function OnRecvGetQuestionActivityInfo(self, tbPacket)
    ScheduleSystem:DispatchMessage(Proto.s2c_GetQuestionActivityInfo, tbPacket)
end

local function OnRecvGetQuestionReward(self, tbPacket)
    ScheduleSystem:DispatchMessage(Proto.s2c_GetQuestionReward, tbPacket)
end

local function OnRecvOpenBox(self, tbPacket)
    ScheduleSystem:DispatchMessage(Proto.s2c_OpenBox, tbPacket)
end

local function OnRecvRollDice(self, tbPacket)
    ScheduleSystem:DispatchMessage(Proto.s2c_RollDice, tbPacket)
end

-- local function OnRecvGetTileReward(self, tbPacket)
--     ScheduleSystem:DispatchMessage(Proto.s2c_GetTileReward, tbPacket)
-- end

local function OnRecvGetDiceReward(self, tbPacket)
    ScheduleSystem:DispatchMessage(Proto.s2c_GetDiceReward, tbPacket)
end

local function OnRecvNotifyActivity(self, tbPacket)
    ScheduleSystem:OnRecvNotifyActivity(tbPacket)
end

local function OnRecvResetActivity(self, tbPacket)
    ScheduleSystem:DispatchMessage(Proto.s2c_ResetActivity, tbPacket)
end

local function OnRecvNotifyTask(self, tbPacket)
    ScheduleSystem:DispatchMessage(Proto.s2c_NotifyTask, tbPacket)
end

local function OnRecvUseActivityItem(self, tbPacket)
    ScheduleSystem:DispatchMessage(Proto.s2c_UseActivityItem, tbPacket)
end

function SchedulePacketProcessor:Init()
    log("SchedulePacketProcessor:Init")
    SchedulePacketProcessor.super.Init(self)
    self:SetBinder(NetworkManager:GetHubServerProxy())
    self:RegisterPackets()
    return true
end

function SchedulePacketProcessor:Uninit()
    log("SchedulePacketProcessor:Uninit")
    SchedulePacketProcessor.super.Uninit(self)
end

function SchedulePacketProcessor:RegisterPackets()
    LobbyPopWndHelper:RegisterSameResponse(Proto.s2c_GetCheckInInfo, self, OnRecvSevenDayCheckIn)
    LobbyPopWndHelper:RegisterSameResponse(Proto.s2c_NoobLoginSchedule, self, OnRecvNoobLogin)
    -- self:BindMethod(Proto.s2c_GetCheckInInfo, self, OnRecvSevenDayCheckIn)
    self:BindMethod(Proto.s2c_CheckInAward, self, OnRecvSevenDayGetReward)
    -- self:BindMethod(Proto.s2c_NoobLoginSchedule, self, OnRecvNoobLogin)
    self:BindMethod(Proto.s2c_GetNoobLoginAward, self, OnRecvGetNoobLoginAward)
    self:BindMethod(Proto.s2c_BattleStarSchedule, self, OnRecvBattleStar)
    self:BindMethod(Proto.s2c_GetTimedAwardInfo, self, OnRecvGetTimedAwardInfo)
    self:BindMethod(Proto.s2c_TimedAward, self, OnRecvTimedAward)
    LobbyPopWndHelper:RegisterSameResponse(Proto.s2c_GetContinuousSchedule, self, OnRecvGetContinuousSchedule)
    -- self:BindMethod(Proto.s2c_GetContinuousSchedule, self, OnRecvGetContinuousSchedule)
    self:BindMethod(Proto.s2c_ReceiveContinuousAward, self, OnRecvReceiveContinuousAward)
    
    LobbyPopWndHelper:RegisterSameResponse(Proto.s2c_GetDrawActivityInfo, self, OnRecvGetDrawActivityInfo)
    -- self:BindMethod(Proto.s2c_GetDrawActivityInfo, self, OnRecvGetDrawActivityInfo)
    LobbyPopWndHelper:RegisterSameResponse(Proto.s2c_GetBoxActivityInfo, self, OnRecvGetBoxActivityInfo)
    LobbyPopWndHelper:RegisterSameResponse(Proto.s2c_GetRollActivityInfo, self, OnRecvGetRollActivityInfo)
    LobbyPopWndHelper:RegisterSameResponse(Proto.s2c_GetQuestionActivityInfo, self, OnRecvGetQuestionActivityInfo)

    
    self:BindMethod(Proto.s2c_GetQuestionReward, self, OnRecvGetQuestionReward)
    self:BindMethod(Proto.s2c_OpenBox, self, OnRecvOpenBox)
    self:BindMethod(Proto.s2c_RollDice, self, OnRecvRollDice)
    -- self:BindMethod(Proto.s2c_GetTileReward, self, OnRecvGetTileReward)
    self:BindMethod(Proto.s2c_GetDiceReward, self, OnRecvGetDiceReward)
    self:BindMethod(Proto.s2c_NotifyActivity , self, OnRecvNotifyActivity)
    self:BindMethod(Proto.s2c_ResetActivity, self, OnRecvResetActivity)
    self:BindMethod(Proto.s2c_NotifyTask, self, OnRecvNotifyTask)
    self:BindMethod(Proto.s2c_UseActivityItem, self, OnRecvUseActivityItem)
end

return SchedulePacketProcessor

-----------------------------------------------------
--File Name    : LobbyChatPacketProcessor.lua
--Author       : Edward J
--Create Time  : 2019-04-01
--Description  : lobby Chat system processor
-----------------------------------------------------
local luaclass                  = require("luaclass")
local NetMessageProcessorBase   = require("NetMessageProcessorBase")
local GuidePacketProcessor      = luaclass("GuidePacketProcessor", NetMessageProcessorBase)

local Proto                = require("ClientProtoNames")
local NetworkManager       = dynamic_require("NetworkManager")
local GuideSystem          = require("GuideSystem")
-----------------------------------------------------

local function OnSyncNoobStageError(self, tbPacket, nSenderUniqueId)
    local return_code = tbPacket.return_code
    log("=======OnSyncNoobStageError=======", return_code)
end

local function OnGetNoobStage(self, tbPacket, nSenderUniqueId)
    local szGuideData = tbPacket.noob_stage
    GuideSystem:GetNoobStage(szGuideData)
end

local function OnBattleEnd(self, tbPacket, nSenderUniqueId)
    GuideSystem:OnBattleEnd()
end

function GuidePacketProcessor:Init()
    GuidePacketProcessor.super.Init(self)
    self:SetBinder(NetworkManager:GetHubServerProxy())
    self:RegisterPackets()
    return true
end

function GuidePacketProcessor:Uninit()
    GuidePacketProcessor.super.Uninit(self)
end

function GuidePacketProcessor:RegisterPackets()
    self:BindMethod(Proto.s2c_SyncNoobStage, self, OnSyncNoobStageError)
    self:BindMethod(Proto.s2c_GetNoobStage, self, OnGetNoobStage)
    self:BindMethod(Proto.s2c_BattleEnd, self, OnBattleEnd)
end

return GuidePacketProcessor()
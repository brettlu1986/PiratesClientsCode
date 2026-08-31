-----------------------------------------------------
--File Name    : NoobAwardPacketProcessor.lua
--Author       : Edward J
--Create Time  : 2020-06-19
--Description  : paket process of noob award
-----------------------------------------------------
local luaclass                          = require("luaclass")
local NetMessageProcessorBase           = require("NetMessageProcessorBase")
local NoobAwardPacketProcessor          = luaclass("NoobAwardPacketProcessor", NetMessageProcessorBase)

local Proto                 = require("ClientProtoNames")
local NetworkManager        = dynamic_require("NetworkManager")
local NoobAwardHelper       = require("NoobAwardHelper")
-----------------------------------------------------

local function OnRecieveNoobAwardState(self, tbPacket, nSenderUniqueId)
    local eAwardType = tbPacket.award_type
    local bGet = tbPacket.received_award
    NoobAwardHelper.OnRecieveAwardState(eAwardType, bGet)
end

local function OnRecieveNoobAward(self, tbPacket, nSenderUniqueId)
    local eAwardType = tbPacket.award_type
    local rc = tbPacket.return_code
    NoobAwardHelper.OnRecieveNoobAward(eAwardType, rc)
end

function NoobAwardPacketProcessor:Init()
    NoobAwardPacketProcessor.super.Init(self)
    self:SetBinder(NetworkManager:GetHubServerProxy())
    self:RegisterPackets()
    return true
end

function NoobAwardPacketProcessor:Uninit()
    NoobAwardPacketProcessor.super.Uninit(self)
end

function NoobAwardPacketProcessor:RegisterPackets()
    self:BindMethod(Proto.s2c_GetNoobAwardState, self, OnRecieveNoobAwardState)
    self:BindMethod(Proto.s2c_ReceiveNoobAward, self, OnRecieveNoobAward)
end

return NoobAwardPacketProcessor()
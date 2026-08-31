local luaclass = require("luaclass")
local NetMessageProcessorBase = require("NetMessageProcessorBase")
local AwardPacketProcessor = luaclass("AwardPacketProcessor", NetMessageProcessorBase)
local NetworkManager = dynamic_require("NetworkManager")
local Proto = require("ClientProtoNames")
local AwardSystem = require("AwardSystem")

local function OnRecvAwardNotification(self, tbPacket)
    AwardSystem:OnRecvAwardNotification(tbPacket)
end

-- 注册处理包
function AwardPacketProcessor:RegisterPackets()
    self:BindMethod(Proto.s2c_AwardNotification, self, OnRecvAwardNotification)
end

function AwardPacketProcessor:Init()
    AwardPacketProcessor.super.Init(self)
    self:SetBinder(NetworkManager:GetHubServerProxy())
    self:RegisterPackets()

    return true
end

-- 结束
function AwardPacketProcessor:Uninit()
    AwardPacketProcessor.super.Uninit(self)
end

return AwardPacketProcessor

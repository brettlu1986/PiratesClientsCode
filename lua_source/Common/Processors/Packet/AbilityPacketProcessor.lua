-----------------------------------------------------
--File Name    : AbilityPacketProcessor.lua
--Author       : Song Fuhao
--Create Time  : 2017-09-22
--Description  : Ability相关（Skill、Buff）的协议都放在这，客户端接收逻辑放到_C实现中
-----------------------------------------------------

local luaclass = require("luaclass")
local NetMessageProcessorBase = require("NetMessageProcessorBase")
local AbilityPacketProcessor = luaclass("AbilityPacketProcessor", NetMessageProcessorBase)

local NetworkManager = dynamic_require("NetworkManager")

-- 注册处理包
function AbilityPacketProcessor:RegisterPackets()
end

-- 初始化
function AbilityPacketProcessor:Init()
    AbilityPacketProcessor.super.Init(self)
    self:SetBinder(NetworkManager:GetRPCNetworkProxy())
    self:RegisterPackets()
    return true
end

return AbilityPacketProcessor

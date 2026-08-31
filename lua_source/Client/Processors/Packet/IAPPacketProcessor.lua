local luaclass = require("luaclass")
local NetMessageProcessorBase = require("NetMessageProcessorBase")
local IAPPacketProcessor = luaclass("IAPPacketProcessor", NetMessageProcessorBase)

local Proto = require("ClientProtoNames")
local IAPSystem = require("IAPSystem")
local NetworkManager = dynamic_require("NetworkManager")

local function OnReceivePurchaseResult(tbPacket)
    IAPSystem:ReceivePurchaseResult(tbPacket.return_code, tbPacket.token)
end

local function OnReceiveRestoreOrderResult(tbPacket)
    IAPSystem:ReceiveRestoreOrderResult(tbPacket.return_code)
end

local function OnReceivePurchaseResultNotify(tbPacket)
    IAPSystem:ReceivePurchaseResultNotify(tbPacket.result)
end

local function OnReceiveApplyFirstPurchaseReward(tbPacket)
    IAPSystem:ReceiveApplyFirstPurchaseReward(tbPacket.return_code)
end

local function OnReceiveSyncFirstPurchaseState(tbPacket)
    IAPSystem:ReceiveFirstPurchaseState(tbPacket.first_purchase_state)
end

-- 注册处理包
function IAPPacketProcessor:RegisterPackets()
    self:BindFunc(Proto.s2c_RequestPurchase, OnReceivePurchaseResult)
    self:BindFunc(Proto.s2c_RequestRestoreOrder, OnReceiveRestoreOrderResult)
    self:BindFunc(Proto.s2c_NotifyPurchaseResult, OnReceivePurchaseResultNotify)
    self:BindFunc(Proto.s2c_ApplyFirstPurchaseReward, OnReceiveApplyFirstPurchaseReward)
    self:BindFunc(Proto.s2c_SyncFirstPurchaseState, OnReceiveSyncFirstPurchaseState)
end

-- 初始化
function IAPPacketProcessor:Init()
    IAPPacketProcessor.super.Init(self)

    self:SetBinder(NetworkManager:GetHubServerProxy())
    self:RegisterPackets()
    return true
end

-- 结束
function IAPPacketProcessor:Uninit()
    IAPPacketProcessor.super.Uninit(self)
end

return IAPPacketProcessor

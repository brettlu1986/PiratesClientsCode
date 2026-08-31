local luaclass = require("luaclass")
local NetworkProxyBase = require("NetworkProxyBase")
local RPCNetworkProxy = luaclass("RPCNetworkProxy", NetworkProxyBase)
local BaseUtil = require("BaseUtil")
local CppDelegate = require("CppDelegate")
local GameObjectSystem

RPCNetworkProxy.pNetworkManager = nil
RPCNetworkProxy.fnMulticast = nil
RPCNetworkProxy.RecvMessageDelegate = nil
RPCNetworkProxy.bCheckDispatchSender = nil
RPCNetworkProxy.nEncryptionSeed = nil

local OnRPCMessageReceived = nil

local function GetProtoIds()
    local tbProtoNames = {
        "DungeonRepProtoNames",
        "DungeonCommonProtoNames"
    }

    local tbRet = {}
    local tbTempIds
    for _, v in ipairs(tbProtoNames) do
        tbTempIds = require(v).GenerateIds()
        for nId, szName in pairs(tbTempIds) do
            if(tbRet[nId]) then
                error("Duplicated proto id:", nId, szName)
            end
            tbRet[nId] = szName
        end
    end
    return tbRet
end

function RPCNetworkProxy:Init(pInNetworkManager)
    RPCNetworkProxy.super.Init(self)

    GameObjectSystem = dynamic_require("GameObjectSystem")
    self.pNetworkManager = pInNetworkManager
    self.fnMulticast = self.pNetworkManager.Multicast
    self.RecvMessageDelegate = CppDelegate:BindMethod(self.pNetworkManager.OnRPCMessageReceived, self, OnRPCMessageReceived)

    local tbIgnoreLogProtoList = {
        "rTeamScores",
        "d2c_SyncBotInfos",
    }
    pInNetworkManager:SetIgnoreMessageLog(tbIgnoreLogProtoList)
    --self:SetPacketEncryptionEnabled(true, 1234567)
end

function RPCNetworkProxy:Uninit()
    if self.RecvMessageDelegate then
        self.RecvMessageDelegate:Unbind()
        self.RecvMessageDelegate = nil
    end

    self.pNetworkManager = nil
    RPCNetworkProxy.super.Uninit(self)
end

function RPCNetworkProxy:SetProtoFile(szProtoFile)
    self.pNetworkManager:SetProtoFile(szProtoFile)
    self.pNetworkManager:SetProtoIds(GetProtoIds())
end

OnRPCMessageReceived = function(self, nInterfaceUniqueId, szMessageType, pMessageRef)
    -- 将pMessageRef转成luatable然后调用Dispatch
    -- local tbMessage = msgtoluatable(self.pNetworkManager, pMessageRef)
    local tbMessage = msgtoluatable(pMessageRef)

    if tbMessage == nil then
        logerror("msgtoluatable is error, szMessageType : ", szMessageType)
        return
    end
    self:Dispatch(nInterfaceUniqueId, szMessageType, tbMessage)
end

function RPCNetworkProxy:SendPacket(PacketID, tbPacket)
    error("RPCNetworkProxy does not support SendPacket method.")
    return false
end

function RPCNetworkProxy:SendToServer(szMessageType, tbMessageBody)
    local bRet = self.pNetworkManager:SendToServer(szMessageType, exposetable(tbMessageBody))
    if self.bSwitchNetLog == true then
        log("RPCNetworkProxy:SendPacket[" .. szMessageType .. "] : ", BaseUtil:ConvertTableToJsonString(tbMessageBody))
    end
    return bRet
end

function RPCNetworkProxy:SendToClient(nPCUniqueId, szMessageType, tbMessageBody)
    if nPCUniqueId <= 0 then
        -- e.g. trying to send message to client on a bot
        return false
    end

    local bRet = self.pNetworkManager:SendToClient(nPCUniqueId, szMessageType, exposetable(tbMessageBody))
    if self.bSwitchNetLog == true then
        log("RPCNetworkProxy:SendPacket[" .. szMessageType .. "] : ", BaseUtil:ConvertTableToJsonString(tbMessageBody))
    end
    return bRet
end

-- lua的Multicast都是reliable的，因为实现是从PlayerController上调用的SendToClient
function RPCNetworkProxy:Multicast(szMessageType, tbMessageBody, bSendToServer)
    bSendToServer = bSendToServer ~= false
    local bRet = self.fnMulticast(self.pNetworkManager, szMessageType, exposetable(tbMessageBody), bSendToServer)
    if self.bSwitchNetLog == true then
        log("RPCNetworkProxy:MulticastPacket[" .. szMessageType .. "] : ", BaseUtil:ConvertTableToJsonString(tbMessageBody))
    end
    return bRet
end

function RPCNetworkProxy:SetPacketEncryptionEnabled(bEnabled, nSeed)
    self.nEncryptionSeed = bEnabled and nSeed or nil
    self.pNetworkManager:SetPacketEncryptionEnabled(bEnabled, nSeed)
end

function RPCNetworkProxy:GetPacketEncryptionSeed()
    return self.nEncryptionSeed
end

function RPCNetworkProxy:Dispatch(nSenderId, PacketID, tbMessage)
    if(self.bCheckDispatchSender and GameObjectSystem:FindByUniqueId(nSenderId) == nil) then
        logwarning("RPCNetworkProxy:Dispatch failed, cannot find sender:", nSenderId)
        return
    end
    RPCNetworkProxy.super.Dispatch(self, nSenderId, PacketID, tbMessage)
end

function RPCNetworkProxy:SetActorAsyncCreatingEnabled(bEnabled)
    self.pNetworkManager:SetActorAsyncCreatingEnabled(bEnabled)
end

return RPCNetworkProxy
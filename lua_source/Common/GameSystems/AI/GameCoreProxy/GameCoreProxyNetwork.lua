
local luaclass = require("luaclass")
local NetworkProxyBase     = require("NetworkProxyBase")
local GameCoreProxyNetwork = luaclass("GameCoreProxyNetwork", NetworkProxyBase)
local CPPDelegate          = require("CPPDelegate")
local GameCoreSDKAnalysis  = require("GameCoreSDKAnalysis")

GameCoreProxyNetwork.pNetworkManager = nil
GameCoreProxyNetwork.pGameCorePorxy = nil
GameCoreProxyNetwork.RecvMessageDelegate = nil
GameCoreProxyNetwork.bDebug = false

local szProtoFile = "GameDataGenerated/protos/gamecore.pb"

local function LOG(...)
    log("CJ->GameCoreProxyNetwork:", ...)
end

function GameCoreProxyNetwork:EnableDebug(bEnable)
    LOG("EnableDebug ", bEnable)
    self.bDebug = bEnable
    if self.pNetworkManager then
        self.pNetworkManager:SetEnableLog(bEnable)
    end
end

function GameCoreProxyNetwork:Init(pGameCorePorxy)
    GameCoreProxyNetwork.super.Init(self)
    self.pGameCorePorxy = pGameCorePorxy
    self.pNetworkManager = pGameCorePorxy.NetworkManager
    local fnRecvMessage = function(nSocketId, szMessageType, pMessageRef)
        local tbMessage = msgtoluatable(pMessageRef)
        if not tbMessage then
            logerror("msgtoluatable is error, szMessageType : ", szMessageType)
            return
        end
        self:Dispatch(nSocketId, szMessageType, tbMessage)
        if self.bDebug then
            GameCoreSDKAnalysis.Record(szMessageType)
        end
    end
    self.RecvMessageDelegate = CPPDelegate:Bind(self.pNetworkManager.OnReceivedMessage, fnRecvMessage)
    self.pNetworkManager:SetProtoFile(szProtoFile)
    self.pNetworkManager:SetEnableLog(false)
    GameCoreSDKAnalysis.Reset()
end

function GameCoreProxyNetwork:OpenNetLog(bOpen)
    if self.pNetworkManager then
        self.pNetworkManager:SetEnableLog(bOpen)
    end
end

function GameCoreProxyNetwork:Uninit()
    if self.RecvMessageDelegate then
        self.RecvMessageDelegate:Unbind()
        self.RecvMessageDelegate = nil
    end
    self.pNetworkManager = nil
    self.pGameCorePorxy = nil
    GameCoreProxyNetwork.super.Uninit(self)
end

function GameCoreProxyNetwork:SendPacket(szPacketType, tbPacket)
    local pGameCorePorxy = self.pGameCorePorxy
    if not pGameCorePorxy then
        return false
    end
    return pGameCorePorxy:SendPacketByTable(szPacketType, exposetable(tbPacket))
end

function GameCoreProxyNetwork:Dispatch(nSenderId, PacketID, tbMessage)
    local Func = self.tbFuncs[PacketID]
    if not Func then
        logerror("GameCoreProxyNetwork packet id not found ", PacketID)
        return false
    end
    --log("received action message:", PacketID)
    local tbPacket = tbMessage
    Func(tbPacket, nSenderId, PacketID)
    return true
end

return GameCoreProxyNetwork

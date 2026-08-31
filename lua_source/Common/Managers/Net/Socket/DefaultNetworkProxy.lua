local luaclass = require("luaclass")
local NetworkProxyBase = require("NetworkProxyBase")
local DefaultNetworkProxy = luaclass("DefaultNetworkProxy", NetworkProxyBase)

local CPPDelegate = require("CPPDelegate")

DefaultNetworkProxy.pNetworkManager = nil
DefaultNetworkProxy.RecvMessageDelegate = nil
DefaultNetworkProxy.DisconnectedDelegate = nil
DefaultNetworkProxy.ConnectedDelegate = nil
DefaultNetworkProxy.PreDisconnectedDelegate = nil
DefaultNetworkProxy.nDisconnectReason = 0
DefaultNetworkProxy.bPreDisconnected  = false
DefaultNetworkProxy.tbPostDisconnectedHandle = nil
DefaultNetworkProxy.fnPostDisconnectedMethod = nil

local tbDispatchWhenDisconnected = {
    s2c_Disconnect = true,
    s2d_KickPlayer = true,
    s2c_BanPlayer  = true,
    s2c_LoginError = true,
}

DefaultNetworkProxy.DisconnectReason = {
    Disconnect_Initiative = 1,
    Disconnect_Passivity = 2,
}

function DefaultNetworkProxy:SetProtoFile(szProtoFile)
    self.pNetworkManager:SetProtoFile(szProtoFile)
end

function DefaultNetworkProxy:OnPostDisconnected(nSocketId)
    self.bPreDisconnected = false
    self:ClearPendingPackets()
    if self.tbPostDisconnectedHandle and self.fnPostDisconnectedMethod then
        self.fnPostDisconnectedMethod(self.tbPostDisconnectedHandle, nSocketId, self.nDisconnectReason)
    end
end

function DefaultNetworkProxy:Init(pInNetworkManager)
    DefaultNetworkProxy.super.Init(self)

    self.pNetworkManager = pInNetworkManager

    -- 不想输入Log的放入该table中
    -- key : szPacketName
    -- value : is not nil
    local tbIgnoreLogProtoList = {
        "c2s_ShipMove",
        "s2c_ShipMove",
        "c2s_HumanMove",
        "s2c_HumanMove",
    }
    pInNetworkManager:SetIgnoreMessageLog(tbIgnoreLogProtoList)

    local fnRecvMessage = function(nSocketId, szMessageType, pMessageRef)
        -- 将pMessageRef转成luatable然后调用dispath
        -- local tbMessage = msgtoluatable(self.pNetworkManager, pMessageRef)
        local tbMessage = msgtoluatable(pMessageRef)
        if tbMessage == nil then
            logerror("msgtoluatable is error, szMessageType : ", szMessageType)
            return
        end

        self:Dispatch(nSocketId, szMessageType, tbMessage)
    end
    self.RecvMessageDelegate = CPPDelegate:Bind(self.pNetworkManager.OnReceivedMessage, fnRecvMessage)

    local fnPreDisconnected = function(_nSocketId)
        log("set hub predisconnected ")
        self.bPreDisconnected = true
    end
    self.PreDisconnectedDelegate = CPPDelegate:Bind(self.pNetworkManager.OnPreDisconnected, fnPreDisconnected)
    local fnPostDisconnected = function(nSocketId)
        self:OnPostDisconnected(nSocketId)
    end
    self.DisconnectedDelegate = CPPDelegate:Bind(self.pNetworkManager.OnPostDisconnected, fnPostDisconnected)
end

function DefaultNetworkProxy:Uninit()
    if self.RecvMessageDelegate then
        self.RecvMessageDelegate:Unbind()
        self.RecvMessageDelegate = nil
    end

    if self.PreDisconnectedDelegate then
        self.PreDisconnectedDelegate:Unbind()
        self.PreDisconnectedDelegate = nil
    end

    if self.DisconnectedDelegate then
        self.DisconnectedDelegate:Unbind()
        self.DisconnectedDelegate = nil
    end

    self:UnbindConnected()
    self:UnbindDisconnected()
    if(self.pNetworkManager) then
        log("DefaultNetworkProxy:Uninit")
        self.pNetworkManager:Disconnect(0)
        self.pNetworkManager = nil
    end
    DefaultNetworkProxy.super.Uninit(self)
end

--Client Network proxy not necessary pass nSenderId. It has only one socket connected.
function DefaultNetworkProxy:SendPacket(szPacketType, tbPacket, nSenderId)
    if nSenderId == nil then
        nSenderId = 0
    end

    local pNetworkManager = self.pNetworkManager
    if(pNetworkManager == nil) then
        return false
    end

    return pNetworkManager:SendPacketByTable(nSenderId, szPacketType, exposetable(tbPacket))
end

function DefaultNetworkProxy:UnbindConnected()
    local ConnectedDelegate = self.ConnectedDelegate
    if(ConnectedDelegate) then
        ConnectedDelegate:Unbind()
        self.ConnectedDelegate = nil
    end
end

function DefaultNetworkProxy:BindConnected(Class, Method)
    self:UnbindConnected()
    local Callback = function(nSocketId, nResult)
        Method(Class, nResult, nSocketId)
    end

    self.ConnectedDelegate = CPPDelegate:Bind(self.pNetworkManager.OnConnectedResult, Callback)
end

function DefaultNetworkProxy:UnbindDisconnected()
    -- local DisconnectedDelegate = self.DisconnectedDelegate
    -- if(DisconnectedDelegate) then
    --     DisconnectedDelegate:Unbind()
    --     self.DisconnectedDelegate = nil
    -- end
    if self.tbPostDisconnectedHandle then
        self.tbPostDisconnectedHandle = nil
        self.fnPostDisconnectedMethod = nil
    end
end

function DefaultNetworkProxy:BindDisconnected(Class, Method)
    if(self.pNetworkManager == nil) then
        return nil
    end
    self:UnbindDisconnected()
    -- local Func = function(nSocketId)
    --     Method(Class, nSocketId, self.nDisconnectReason)
    -- end
    -- self.DisconnectedDelegate = CPPDelegate:Bind(self.pNetworkManager.OnDisconnected, Func)
    -- return self.DisconnectedDelegate
    self.tbPostDisconnectedHandle = Class
    self.fnPostDisconnectedMethod = Method
end

--Client Network proxy not necessary pass nSenderId. It has only one socket connected.
function DefaultNetworkProxy:Connect(szParam, nSenderId)
    if nSenderId == nil then
        nSenderId = 0
    end

    local pNetworkManager = self.pNetworkManager
    if(pNetworkManager == nil) then
        return false
    end
    self.nDisconnectReason = self.DisconnectReason.Disconnect_Passivity

    local tbConnectInfo = self:ParseConnectInfo(szParam)
    if(tbConnectInfo == nil) then
        return pNetworkManager:Connect(nSenderId, szParam)
    elseif(tbConnectInfo.szDomainName ~= nil and tbConnectInfo.nPort ~= nil) then
        return pNetworkManager:ConnectWithDomainName(nSenderId, tbConnectInfo.szDomainName, tbConnectInfo.nPort, tbConnectInfo.bUseOpenSSL)
    elseif(tbConnectInfo.szDomainName ~= nil and tbConnectInfo.szIp ~= nil) then
        return pNetworkManager:ConnectIPWithOpenSSL(nSenderId, tbConnectInfo.szIp, tbConnectInfo.szDomainName)
    else
        error("invalid connect param: "..szParam)
        return false
    end
end

function DefaultNetworkProxy:Disconnect(_tbParams, nSenderId, nReason)
    if nSenderId == nil then
        nSenderId = 0
    end

    local pNetworkManager = self.pNetworkManager
    if(pNetworkManager == nil) then
        return false
    end
    self.nDisconnectReason = not nReason and self.DisconnectReason.Disconnect_Initiative or nReason
    log("DefaultNetworkProxy:Disconnect")
    return pNetworkManager:Disconnect(nSenderId)
end
function DefaultNetworkProxy:IsConnect(_tbParams, nSenderId)
    if nSenderId == nil then
        nSenderId = 0
    end

    local pNetworkManager = self.pNetworkManager
    if(pNetworkManager == nil) then
        return false
    end
    return pNetworkManager:IsConnected(nSenderId)
end

function DefaultNetworkProxy:Dispatch(nSenderId, PacketID, tbMessage)
    local Func = self.tbFuncs[PacketID]
    if(Func == nil) then
        -- 等服务器屏蔽响应系统协议后，打开日志。
        -- logwarning("Dispatch packet failed, no reciever, packetID: ", PacketID)
        return false
    end

    local tbPacket = tbMessage
    if self.bPreDisconnected then
        if tbDispatchWhenDisconnected[PacketID] then
            log("DefaultNetworkProxy:Dispatch perdisconnected care ", PacketID)
            Func(tbPacket, nSenderId)
        else
            log("DefaultNetworkProxy:Dispatch but perdisconnected don't care ", PacketID)
        end
    else
        Func(tbPacket, nSenderId)
    end
    return true
end

function DefaultNetworkProxy:SetPending(bPending)
    self.pNetworkManager:SetPending(bPending)
end

function DefaultNetworkProxy:MessageToBase64String(szPacketType, tbPacket)
    return self.pNetworkManager:MessageToBase64String(szPacketType, exposetable(tbPacket))
end

function DefaultNetworkProxy:Base64StringToMessage(szPacketType, szContent)
    return self.pNetworkManager:Base64StringToMessage(szPacketType, szContent)
end

function DefaultNetworkProxy:ParseConnectInfo(szConnectInfo)
    assert(szConnectInfo)

    local szPrefix, szDomainName, szPort, szBackupIp = string.match(szConnectInfo, "(%a+)://([A-Za-z0-9%._-]+):(%d+):?([0-9.]*)")
    --logdebug(string.format("prefix: %s, domain_name: %s, port: %s, szBackupIp: %s", szPrefix, szDomainName, szPort, szBackupIp or "nil"))
    if(szPrefix == nil or string.len(szPrefix) == 0) then
        return nil
    end

    if(szPrefix == "tls" or szPrefix == "tcp") then
        if(szDomainName ~= nil and szPort ~= nil) then
            local tbConnectInfo = {}
            tbConnectInfo.szDomainName = szDomainName
            tbConnectInfo.bUseOpenSSL = szPrefix == "tls"
            tbConnectInfo.nPort = tonumber(szPort)
            return tbConnectInfo
        end
    elseif(szPrefix == "iptls") then
        if(szDomainName ~= nil and szPort ~= nil and szBackupIp ~= nil) then
            local tbConnectInfo = {}
            tbConnectInfo.szDomainName = szDomainName
            tbConnectInfo.szIp = szBackupIp..":"..szPort
            return tbConnectInfo
        end
    end
    return nil
end

return DefaultNetworkProxy

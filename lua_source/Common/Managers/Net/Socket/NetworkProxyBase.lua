local luaclass = require("luaclass")
local NetworkProxyBase = luaclass("NetworkProxyBase")

NetworkProxyBase.tbFuncs = nil
NetworkProxyBase.bPending = false
NetworkProxyBase.tbPendingPackets = nil

function NetworkProxyBase:Init()
    self.tbFuncs = {}
    self.tbPendingPackets = {}
end

function NetworkProxyBase:Uninit()
    self:UnbindAll()
end

function NetworkProxyBase:BindConnected(Class, Method)
    -- 子类重载
end

function NetworkProxyBase:UnbindConnected()
    -- 子类重载
end

function NetworkProxyBase:BindDisconnected(Class, Method)
    -- 子类重载
end

function NetworkProxyBase:UnbindDisconnected()
    -- 子类重载
end

function NetworkProxyBase:Connect(tbParams, nSenderId)
    -- 子类重载
end

function NetworkProxyBase:Disconnect(tbParams)
    -- 子类重载
end

function NetworkProxyBase:IsConnect(tbParams)
    -- 子类重载
end

function NetworkProxyBase:SwitchNetLog(bSwitch)
    
    log("SwitchNetLog : ", bSwitch)
end

-- 暂时只支持一个消息绑一个，需要绑多个的时候再说
function NetworkProxyBase:BindMethod(PacketID, Class, Method)
    if PacketID == nil or Class == nil or Method == nil then
        logerror("NetworkProxyBase:BindMethod(), PacketID : ", PacketID, ", Class : ", Class, ", Method : ", Method)
    end

    local Func = function(tbPacket, nSenderId)
        Method(Class, tbPacket, nSenderId)
    end
    self.tbFuncs[PacketID] = Func
end

function NetworkProxyBase:BindFunc(PacketID, Func)
    if PacketID == nil or Func == nil then
        logerror("NetworkProxyBase:BindFunc(), PacketID : ", PacketID, ", Func : ", Func)
    end

    self.tbFuncs[PacketID] = Func  
end

function NetworkProxyBase:UnbindMethod(PacketID, Class, Method)
    self.tbFuncs[PacketID] = nil
end

function NetworkProxyBase:UnbindAll()
    self.tbFuncs = {} 
    self:ClearPendingPackets()
end

function NetworkProxyBase:Dispatch(nSenderId, PacketID, tbMessage)
    if(self.bPending) then
        table.insert(self.tbPendingPackets, {nSenderId, PacketID, tbMessage})
        return true;
    end

    local Func = self.tbFuncs[PacketID]
    if(Func == nil) then
        logwarning("Dispatch packet failed, no reciever, packetID: ", PacketID)
        return false
    end
    
    Func(tbMessage, nSenderId)
    return true
end

-- 暂时这样，未来c++网络层应该提供接口
function NetworkProxyBase:SetPending(bPending)
    if(self.bPending == bPending) then
        return
    end

    log("NetworkProxyBase:SetPending ", bPending)
    self.bPending = bPending
    if(not bPending) then
        local tbPendingPackets = self.tbPendingPackets
        self.tbPendingPackets = {}
        for _, tbTemp in ipairs(tbPendingPackets) do
            self:Dispatch(tbTemp[1], tbTemp[2], tbTemp[3])
        end
    end
end

function NetworkProxyBase:ClearPendingPackets()
    self.tbPendingPackets = {}
end

function NetworkProxyBase:MessageToBase64String(szPacketType, tbPacket)
    -- subclass overwrite
    return nil
end

function NetworkProxyBase:Base64StringToMessage(szPacketType, szContent)
    -- subclass overwrite
    return nil, nil
end

return NetworkProxyBase

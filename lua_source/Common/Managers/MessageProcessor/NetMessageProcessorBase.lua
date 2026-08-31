local luaclass = require("luaclass")
local MessageProcessorBaseClass = require("MessageProcessorBase")
local NetMessageProcessorBase = luaclass("NetMessageProcessorBase", MessageProcessorBaseClass)

NetMessageProcessorBase.PacketBinder = nil
NetMessageProcessorBase.tbPacketMethods = nil

function NetMessageProcessorBase:Init()
    self.tbPacketMethods = {}
    return true
end

function NetMessageProcessorBase:SetBinder(Binder)
    self.PacketBinder = Binder
end

function NetMessageProcessorBase:GetBinder()
    return self.PacketBinder
end

function NetMessageProcessorBase:Uninit()
    self:UnbindAll()
end

function NetMessageProcessorBase:BindMethod(Key, Class, Method)
    if(self.tbPacketMethods[Key]) then
        error("BindMethod failed, duplicated packet id " .. Key)
        return
    end
    self.PacketBinder:BindMethod(Key, Class, Method)
    self.tbPacketMethods[Key] = true
end

function NetMessageProcessorBase:BindFunc(Key, Func)
    if(self.tbPacketMethods[Key]) then
        logerror("BindFunc failed, duplicated packet id")
        return
    end
    self.PacketBinder:BindFunc(Key, Func)
    self.tbPacketMethods[Key] = true
end

function NetMessageProcessorBase:Unbind(Key)
    self.PacketBinder:UnbindMethod(Key, nil, nil)
    self.tbPacketMethods[Key] = nil
end

function NetMessageProcessorBase:UnbindAll()
    local tbPacketMethods = self.tbPacketMethods
    if(tbPacketMethods) then
        for k, _ in pairs(tbPacketMethods) do
            self.PacketBinder:UnbindMethod(k, nil, nil)
        end
    end
    self.tbPacketMethods = {}
end

return NetMessageProcessorBase

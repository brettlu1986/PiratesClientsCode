local MessageProcessorManager = {}

MessageProcessorManager.tbProcessors = {}

local UnreigsterAllProcessor = function (self)
    local tb = self.tbProcessors
    for _, Processor in pairs(tb) do
        Processor:Uninit()
    end
    self.tbProcessors = {}
end

function MessageProcessorManager:OnRegister()
    local Register = dynamic_require("MessageProcessorRegister")
    Register:RegisterAllProcessors(self)
    return true;
end

function MessageProcessorManager:Init()
end

function MessageProcessorManager:Uninit()
    UnreigsterAllProcessor(self)
end

function MessageProcessorManager:Register(MessageProcessorClass)
    if(MessageProcessorClass == nil) then
        logerror("MessageProcessorManager:Register failed, the class is nil")
        return nil
    end

    local tbTable = self.tbProcessors
    local MessageProcessor = MessageProcessorClass()
    table.insert(tbTable, MessageProcessor)
    return MessageProcessor
end

function MessageProcessorManager:Unregister(MessageProcessor)
    local tbTable = self.tbProcessors
    for Index, Processor in pairs(tbTable) do
        if Processor == MessageProcessor then
            --MessageProcessor:Uninit() -- 这个在binder里uninit
            table.remove(tbTable, Index)
            return true;
        end
    end
    return false;
end

return MessageProcessorManager

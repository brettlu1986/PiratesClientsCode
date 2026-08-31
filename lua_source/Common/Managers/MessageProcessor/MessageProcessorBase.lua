local luaclass = require("luaclass")

local MessageProcessorBase = luaclass("MessageProcessorBase")

function MessageProcessorBase:Init()
    return true
end

function MessageProcessorBase:Uninit()
end

function MessageProcessorBase:Register(Key, Func)
    -- 子类重载
    return false;
end

function MessageProcessorBase:Unregister(Key, Func)
    -- 子类重载
end

return MessageProcessorBase

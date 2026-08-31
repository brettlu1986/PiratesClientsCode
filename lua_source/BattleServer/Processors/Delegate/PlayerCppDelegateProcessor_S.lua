local luaclass = require("luaclass")
local PlayerCppDelegateProcessorClass = require("PlayerCppDelegateProcessor")
local PlayerCppDelegateProcessor_S = luaclass("PlayerCppDelegateProcessor_S", PlayerCppDelegateProcessorClass)

function PlayerCppDelegateProcessor_S:Init()
    PlayerCppDelegateProcessor_S.super.Init(self)
    return true
end

return PlayerCppDelegateProcessor_S

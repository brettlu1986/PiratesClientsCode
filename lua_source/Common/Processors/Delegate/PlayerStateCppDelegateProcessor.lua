local luaclass = require("luaclass")
local CppDelegateProcessorBaseClass = require("CPPDelegateProcessorBase")
local PlayerStateCppDelegateProcessor = luaclass("PlayerStateCppDelegateProcessor", CppDelegateProcessorBaseClass)

function PlayerStateCppDelegateProcessor:Init()
    PlayerStateCppDelegateProcessor.super.Init(self)
    return true
end

return PlayerStateCppDelegateProcessor
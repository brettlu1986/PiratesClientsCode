local luaclass = require("luaclass")
local LuaTablePool = luaclass("LuaTablePool")

LuaTablePool.nIndex = 1
LuaTablePool.tbTables = { }


function LuaTablePool:Get()
    self.tbTables[self.nIndex] = self.tbTables[self.nIndex] or {}
    self.nIndex = self.nIndex + 1
    return self.tbTables[self.nIndex - 1]
end

function LuaTablePool:Reset()
    self.nIndex = 1
end


return LuaTablePool
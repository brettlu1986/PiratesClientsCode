local luaclass = require("luaclass")
local GameCoreAgentLuaPoolManager = luaclass("GameCoreAgentLuaPoolManager")
local LuaTablePool    = require("LuaTablePool")

GameCoreAgentLuaPoolManager.tbObjectPools = nil

-- luacheck: push ignore
local function LOG(...)
    log("CJ->GameCoreAgentLuaPoolManager:", ...)
end
-- luacheck: pop

function GameCoreAgentLuaPoolManager:Register(nServerInstanceId, tbTablePoolNames)
    self.tbObjectPools = self.tbObjectPools or {}
    local tbPools = {}
    for _,v in ipairs(tbTablePoolNames) do
        tbPools[v] = LuaTablePool()
        LOG("register lua pool ", v)
    end
    self.tbObjectPools[nServerInstanceId] = tbPools
end

function GameCoreAgentLuaPoolManager:Unregister(nServerInstanceId)
    self.tbObjectPools[nServerInstanceId] = nil
end

function GameCoreAgentLuaPoolManager:Reset(nServerInstanceId)
    for k,v in pairs(self.tbObjectPools[nServerInstanceId]) do
        v:Reset()
    end
    --LOG("reset lua pool")
end

function GameCoreAgentLuaPoolManager:Get(nServerInstanceId, szPoolName)
    return self.tbObjectPools[nServerInstanceId][szPoolName]
end

return GameCoreAgentLuaPoolManager()
local luaclass = require "luaclass"
local NetPlayerManager_S = luaclass("NetPlayerManager_S")

local EventManager = require("EventManager")
local CommonEventDef = require("CommonEventDef")
local BaseUtil = require("BaseUtil")

NetPlayerManager_S.tbPlayerIdSocketMap = {}
NetPlayerManager_S.tbSocketIds = {}

function NetPlayerManager_S:OnRegister()
end

function NetPlayerManager_S:Init()
    log("NetPlayerManager_S Init")
    EventManager:BindEventMethod(CommonEventDef.EV_GAME_MODE_ON_ALL_PLAYER_LOGOUT, self, self.AllPlayerLogout)
    return true
end

function NetPlayerManager_S:RegisterPlayer(nSocketId, nPlayerId)
    if self.tbPlayerIdSocketMap[nPlayerId] == nil then
        self.tbPlayerIdSocketMap[nPlayerId] = {}
    end
    self.tbPlayerIdSocketMap[nPlayerId] = nSocketId

    local bNewSocketId = true
    for k,v in pairs(self.tbSocketIds) do
        if v == nSocketId then
            bNewSocketId = false
            break
        end
    end
    if bNewSocketId then
        table.insert(self.tbSocketIds, nSocketId)
    end
end

function NetPlayerManager_S:GetSocketId(nPlayerId)
    return self.tbPlayerIdSocketMap[nPlayerId]
end

function NetPlayerManager_S:GetAllSocketIds()
    return BaseUtil:ReadOnly(self.tbSocketIds)
end

function NetPlayerManager_S:AllPlayerLogout()
    log("NetPlayerManager_S receive all player logout event. Do clear.")
    self:Clear()
end

function NetPlayerManager_S:Clear()
    self.tbPlayerIdSocketMap = {}
    self.tbSocketIds = {}
end

function NetPlayerManager_S:Uninit()
    log("NetPlayerManager_S Uninit")
    self:Clear()
    EventManager:UnBindEventMethod(CommonEventDef.EV_GAME_MODE_ON_ALL_PLAYER_LOGOUT, self, self.AllPlayerLogout)
end

return NetPlayerManager_S()

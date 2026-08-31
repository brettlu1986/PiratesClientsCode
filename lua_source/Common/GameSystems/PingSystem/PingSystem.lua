local luaclass = require("luaclass")
local PingSystem = luaclass("PingSystem")
local SelfEventHelper = require("SelfEventHelper")

local DEFAULT_WRITE_IDLE_TIME = 15
local DEFAULT_READ_IDLE_TIME = 30

PingSystem.nWriteIdleTime = nil
PingSystem.nReadIdleTime = nil
PingSystem.tbPing = nil

local function OnWriteIdleTimeout(self, nSocketId, nDeltaTime)
    log("ping system OnWriteIdleTimeOut", nSocketId)
    local Socket = self:GetNetworkProxy()
    if Socket:IsConnect(nil, nSocketId) then
        Socket:SendPacket(self.tbPing, nil, nSocketId)
    else
        log("ping system OnWriteIdleTimeOut: disconnect")
    end
end

function PingSystem:OnReadIdleTimeout(nSocketId, nDeltaTime)
end

function PingSystem:InitWriteIdleTime()
    self.nWriteIdleTime = DEFAULT_WRITE_IDLE_TIME
end

function PingSystem:InitReadIdleTime()
    self.nReadIdleTime = DEFAULT_READ_IDLE_TIME
end

-- Please override this function.
function PingSystem:InitPingMessage()
    log.error("Please specify ping message explicitly. Do OVERRIDE InitPingMessage function.")
    self.tbPing = nil
end

-- Please override this function
function PingSystem:GetNetworkProxy()
    log.error("Please override GetNetworkProxy function.")
    return nil
end

function PingSystem:Init()
    log("ping system init")
    local EventHelper = SelfEventHelper()
    self.EventHelper = EventHelper

    self:InitWriteIdleTime()
    self:InitReadIdleTime()
    self:InitPingMessage()

    log("Ping system init to write idle time", self.nWriteIdleTime,
        ". Read idle time", self.nReadIdleTime,
        ". Ping message", self.tbPing)

    local NetworkProxy = self:GetNetworkProxy()
    local pNetworkManager = NetworkProxy.pNetworkManager
    pNetworkManager:SetIdleTime(self.nWriteIdleTime, self.nReadIdleTime)

    EventHelper:RegisterCppDelegate(pNetworkManager.OnWriteIdleTimeout, self, OnWriteIdleTimeout)
    EventHelper:RegisterCppDelegate(pNetworkManager.OnReadIdleTimeout, self, self.OnReadIdleTimeout)

    return true
end

function PingSystem:Uninit()
    log("ping system uninit")
    self.EventHelper:UnregisterAll()
    self.EventHelper = nil
end

return PingSystem
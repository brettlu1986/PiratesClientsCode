local luaclass = require("luaclass")
local LoginPacketProcessor = require("LoginPacketProcessorNew")
local ReloginPacketProcessor = luaclass("ReloginPacketProcessor", LoginPacketProcessor)
local ClientEventDef = require("ClientEventDef")
local EventManager = require("EventManager")
local NetworkManager = dynamic_require("NetworkManager")
local Proto = require("ClientProtoNames")
local GlobalVariableSystem = require("GlobalVariableSystem_C")
local ReconnectSystem  = require("ReconnectSystemNew")

function ReloginPacketProcessor:Init()
    self.tbPacketMethods = {}
    self:SetBinder(NetworkManager:GetHubServerProxy())
    log("ReloginPacketProcessor:Init")
    EventManager:BindEventMethod(ClientEventDef.EV_RECONNECTED, self, self.OnReconnected)

    return true
end

function ReloginPacketProcessor:Uninit()
    log("ReloginPacketProcessor:Uninit")
    EventManager:UnBindEventMethod(ClientEventDef.EV_RECONNECTED, self, self.OnReconnected)
    ReloginPacketProcessor.super.Uninit(self)
end

function ReloginPacketProcessor:RegisterPackets()
    self:BindMethod(Proto.s2c_LoginError, self, self.OnLoginError)
    self:BindMethod(Proto.s2c_PlayerData, self, self.OnRecvPlayerData)
    self:BindMethod(Proto.s2c_NewPlayer, self, self.OnRecvNewPlayer)
end

function ReloginPacketProcessor:OnReconnected()
    if not self.tbPacketMethods[Proto.s2c_PlayerData] then
        log("relogin RegisterPackets")
        self:RegisterPackets()
    end
end

function ReloginPacketProcessor:OnLoginError(tbPacket)
    log("ReloginPacketProcessor:OnLoginError ", tbPacket.return_code)
    if tbPacket.return_code == Proto.ReturnCode.REVISION_CHECK_FAILED then

        ReconnectSystem:EnterFailed()
    end
end

function ReloginPacketProcessor:OnRecvPlayerData(tbPacket)
    log(string.format("ReloginPacketProcessor:OnRecvPlayerData name = %s, player_id = %d, ip= %s", tbPacket.data.name, tbPacket.data.id, EngineExtActorShell.GetLocalHostAddress()))

    local tbPlayerData = tbPacket.data
    local nPlayerId = tbPlayerData.id
    GlobalVariableSystem.nSelfLobbyPlayerId = nPlayerId

    log("Rebuild world start")
    -- ReconnectSystem:SetPlayerData(tbPacket)
    ReconnectSystem:TryEnter(tbPacket)

    self:UnbindAll()
end

function ReloginPacketProcessor:OnRecvNewPlayer(tbPacket)
    log(string.format("ReloginPacketProcessor:OnRecvNewPlayer ip= %s", EngineExtActorShell.GetLocalHostAddress()))
    
    self:UnbindAll()    
    ReconnectSystem:TryEnter()
end

return ReloginPacketProcessor
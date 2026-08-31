local luaclass = require("luaclass")
local NetMessageProcessorBase = require("NetMessageProcessorBase")
local FirstBattlePacketProcessor = luaclass("FirstBattlePacketProcessor", NetMessageProcessorBase)
local NetworkManager = dynamic_require("NetworkManager")
local Proto = require("ClientProtoNames")
local GamePlayerSelfHelper = require("GamePlayerSelfHelper")
local ClientEventDef = require("ClientEventDef")
local EventManager = require("EventManager")

local function OnRecvFirstBattleTime(self, tbPacket)
    local PlayerSelf = GamePlayerSelfHelper:Get()

    local nBattleTime = tbPacket.first_battle_time
	if PlayerSelf and PlayerSelf.LobbyPropertyComponent then
        PlayerSelf.LobbyPropertyComponent:SetFirstBattleTime(nBattleTime)
        EventManager:OnFireEvent(ClientEventDef.EV_FIRST_BATTLE_REFRESH_TIME)
    end
end

-- 注册处理包
function FirstBattlePacketProcessor:RegisterPackets()
    self:BindMethod(Proto.s2c_NotifyBattleTime, self, OnRecvFirstBattleTime)
end

function FirstBattlePacketProcessor:Init()
    FirstBattlePacketProcessor.super.Init(self)
    self:SetBinder(NetworkManager:GetHubServerProxy())
    self:RegisterPackets()

    return true
end

-- 结束
function FirstBattlePacketProcessor:Uninit()
    FirstBattlePacketProcessor.super.Uninit(self)
end

return FirstBattlePacketProcessor

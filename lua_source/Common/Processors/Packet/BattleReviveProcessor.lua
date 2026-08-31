--死亡复活

local luaclass = require("luaclass")
local NetMessageProcessorBase = require("NetMessageProcessorBase")
local BattleReviveProcessor = luaclass("BattleReviveProcessor", NetMessageProcessorBase)

local NetworkManager = dynamic_require("NetworkManager")
local ProtoDC = require("DungeonCommonProtoNames")
local BattleReviveSystem = dynamic_require("BattleReviveSystem")

-- 选择哪种复活方式
local function ReviveMode(self, tbPacket, nSenderUniqueId)
    BattleReviveSystem:OnReviveMode(tbPacket.player_instanceId, tbPacket.backcity)
end


-- 注册处理包
function BattleReviveProcessor:RegisterPackets()
    local tbProxy = NetworkManager:GetRPCNetworkProxy()
    self:SetBinder(tbProxy)
    self:BindMethod(ProtoDC.c2d_ReviveMode, self, ReviveMode)
   
end

-- 初始化
function BattleReviveProcessor:Init()
    BattleReviveProcessor.super.Init(self)

    self:RegisterPackets()
    return true
end

return BattleReviveProcessor
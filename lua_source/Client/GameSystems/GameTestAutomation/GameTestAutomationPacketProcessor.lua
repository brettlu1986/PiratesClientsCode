-----------------------------------------------------
--File Name    : GameTestAutomationPacketProcessor.lua
--Author       : WuJizhou
--Create Time  : 7/7/2019, 10:47:56 AM
--Description  : GameTestAutomationPacketProcessor
-----------------------------------------------------
local luaclass = require("luaclass")
local NetMessageProcessorBase = require("NetMessageProcessorBase")
local GameTestAutomationPacketProcessor = luaclass("GameTestAutomationPacketProcessor", NetMessageProcessorBase)

local NetworkManager = dynamic_require("NetworkManager")
local ProtoDC = require("DungeonCommonProtoNames")
local EventManager = require("EventManager")
local ClientEventDef = require("ClientEventDef")


local function OnFFAFinishedNotified(self)
    EventManager:OnFireEvent(ClientEventDef.EV_NOTIFY_BATTLE_FINISHED)
end


function GameTestAutomationPacketProcessor:RegisterPackets()
    local tbProxy = NetworkManager:GetRPCNetworkProxy()
    self:SetBinder(tbProxy)
    self:BindMethod(ProtoDC.d2c_NotifyClientToQuitDungeon, self, OnFFAFinishedNotified)
end

-- 初始化
function GameTestAutomationPacketProcessor:Init()
    GameTestAutomationPacketProcessor.super.Init(self)
    self:RegisterPackets()
    return true
end

-- 结束
function GameTestAutomationPacketProcessor:Uninit()
    GameTestAutomationPacketProcessor.super.Uninit(self)
end

return GameTestAutomationPacketProcessor

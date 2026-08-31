--修改npc交互状态

local luaclass = require("luaclass")
local NetMessageProcessorBase = require("NetMessageProcessorBase")
local BattleNpcInteractionProcessor = luaclass("BattleNpcInteractionProcessor", NetMessageProcessorBase)

local NetworkManager = dynamic_require("NetworkManager")
local ProtoDC = require("DungeonCommonProtoNames")
local EventManager = require("EventManager")
local CommonEventDef = require("CommonEventDef")
local GameObjectSystem = dynamic_require("GameObjectSystem")
local BattleCollectionSystem =  require("BattleCollectionSystem")
local GameNpcType = require("GameNpcType")
local BattleLandSystem = dynamic_require("BattleLandSystem")

-- 剧情对话结束
local function CloseInteractionDialog(self, tbPacket, nSenderUniqueId)
    EventManager:OnFireEvent(CommonEventDef.EV_BATTLE_INTERACTIONDLG_END)
end

--开始通过npc交互
local function StartInteractionNpc(self, tbPacket, nSenderUniqueId)
    local tbNpc = GameObjectSystem:FindByInstanceId(tbPacket.npc_instanceId)
    if tbNpc ~= nil then
        if tbNpc:GetNpcType() ~= GameNpcType.BattleCollection then
            EventManager:OnFireEvent(CommonEventDef.EV_BATTLE_INTERACTIONDLG_START_NPC, tbPacket.npc_instanceId, tbPacket.player_instanceId)
        else
            -- 增加开始采集事件,逻辑处理完需调用OnCollectionStart
            -- EventManager:OnFireEvent(CommonEventDef.EV_BATTLE_COLLECTION_START_NPC, tbPacket.npc_instanceId, tbPacket.player_instanceId)
            BattleCollectionSystem:OnCollectionStart(tbPacket.npc_instanceId, tbPacket.player_instanceId)
        end
    end
    
end

--进入npc交互范围
local function TriggerInteractionNpc(self, tbPacket, nSenderUniqueId)
    EventManager:OnFireEvent(CommonEventDef.EV_BATTLE_TARIGGER_INTERACTION, tbPacket.npc_instanceid)
end

--采集中断
local function CollectionBrake(self, tbPacket, nSenderUniqueId)
    BattleCollectionSystem:OnCollectionBreak(tbPacket.npc_instanceid)
end

local function OnStartChangeDisplay(self, tbPacket, nSenderUniqueId)
    BattleLandSystem:OnStartChangeDisplay(nSenderUniqueId)
end

local function OnBreakChangingDisplay(self, tbPacket, nSenderUniqueId)
    BattleLandSystem:OnBreakChangingDisplay(nSenderUniqueId)
end

-- 注册处理包
function BattleNpcInteractionProcessor:RegisterPackets()
    local tbProxy = NetworkManager:GetRPCNetworkProxy()
    self:SetBinder(tbProxy)
    self:BindMethod(ProtoDC.c2d_CloseDialog, self, CloseInteractionDialog)
    self:BindMethod(ProtoDC.c2d_BattleStartInteractionNpc, self, StartInteractionNpc)
    self:BindMethod(ProtoDC.c2d_BattleTriggerInteractionNpc, self, TriggerInteractionNpc)
    self:BindMethod(ProtoDC.c2d_CollectionBreak, self, CollectionBrake)
    self:BindMethod(ProtoDC.c2d_StartChangeDisplay, self, OnStartChangeDisplay)
    self:BindMethod(ProtoDC.c2d_BreakChangeDisplay, self, OnBreakChangingDisplay)    
end

-- 初始化
function BattleNpcInteractionProcessor:Init()
    BattleNpcInteractionProcessor.super.Init(self)

    self:RegisterPackets()
    return true
end

return BattleNpcInteractionProcessor
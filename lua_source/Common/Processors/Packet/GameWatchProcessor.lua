-----------------------------------------------------
local luaclass                  = require("luaclass")
local NetMessageProcessorBase   = require("NetMessageProcessorBase")
local GameWatchProcessor = luaclass("GameWatchProcessor", NetMessageProcessorBase)

local Proto             = require("DungeonCommonProtoNames")
local GameObjectSystem  = dynamic_require("GameObjectSystem")
local NetworkManager    = dynamic_require("NetworkManager")
local EventManager      = require("EventManager")
local CommonEventDef    = require("CommonEventDef")
local GlobalVariableSystem      = dynamic_require("GlobalVariableSystem")
local WatchBattleSystem         = dynamic_require("WatchBattleSystem")
local BattleTemplateActorSystem = dynamic_require("BattleTemplateActorSystem")

-----------------------------------------------------


local function WatchTeammateBattle(self, tbPacket, nSenderUniqueId)
    local nPreMateInsId = tbPacket.pre_watch_mate
    local nMateInsId = tbPacket.new_watch_mate
    local bOtherTeam = tbPacket.is_other_team
    local bChangeSuccessed, nNewMateId = WatchBattleSystem:ChangeTeammateView(nPreMateInsId, nMateInsId, nSenderUniqueId, bOtherTeam)
    if(bChangeSuccessed and GlobalVariableSystem.bEnableTemplateActor) then
        local tbPlayer = GameObjectSystem:FindByUniqueId(nSenderUniqueId)
        local tbMate = GameObjectSystem:FindByInstanceId(nNewMateId)
        BattleTemplateActorSystem:SetWatchedTarget(tbPlayer, tbMate)
    end
end

local function StopWatchTeammateBattle(self, tbPacket, nSenderUniqueId)
    local nMateInsId = tbPacket.watch_mate_id
    local nStopType = tbPacket.stop_type
    WatchBattleSystem:StopTeammateView(nMateInsId, nStopType, nSenderUniqueId)
end


local function FFAWatchMateTips(self, tbPacket, nSenderUniqueId)
    local tbPlayer = GameObjectSystem:FindByUniqueId(nSenderUniqueId)
    if tbPlayer then
        EventManager:OnFireEvent(CommonEventDef.EV_WATCH_MATE_TIPS, tbPlayer, tbPacket.nInstanceId)
    end
end

function GameWatchProcessor:Init()
    GameWatchProcessor.super.Init(self)
    self:SetBinder(NetworkManager:GetRPCNetworkProxy())
    self:RegisterPackets()
    return true
end

function GameWatchProcessor:RegisterPackets()
    self:BindMethod(Proto.c2d_WatchTeammateBattle, self, WatchTeammateBattle)
    self:BindMethod(Proto.c2d_StopWatchTeammateBattle, self, StopWatchTeammateBattle )
    self:BindMethod(Proto.c2d_FFAWatchMateTips, self, FFAWatchMateTips )
end

return GameWatchProcessor
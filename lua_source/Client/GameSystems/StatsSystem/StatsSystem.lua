local NetworkManager = dynamic_require("NetworkManager")
local Proto = require("ClientProtoNames")
local GamePlayerSelfHelper = require("GamePlayerSelfHelper")
local ClientEventDef = require("ClientEventDef")
local EventManager = require("EventManager")
local SelfEventHelper = require("SelfEventHelper")
local UIUtils = require("UIUtils")
local UITextDef = require("UITextDef")

local StatsSystem = {}

local Return_Code = {
    [Proto.ReturnCode.FORBID_VIEW_HISTORY] = UITextDef.FORBID_VIEW_HISTORY,
}

local function ShowErrorCode(nReturnCode)
    local l10nErrorCode = Return_Code[nReturnCode]
    if l10nErrorCode ~= nil then
        UIUtils.ShowToast(l10nErrorCode)
    else
        log("StatsSystem invalid return code:", nReturnCode)
    end
end

local function OnEnterLobby(self)
    self:RequestGetHistoryStats()
end

local function SendPacket(szProto, tbPacket)
    local Socket = NetworkManager:GetHubServerProxy()
    Socket:SendPacket(szProto, tbPacket)    
end

function StatsSystem:Init()
    local EventHelper = SelfEventHelper()
    self.EventHelper = EventHelper
    -- self.nHistoryTime = 0
    EventHelper:RegisterEvent(ClientEventDef.EV_LOBBY_READY, self, OnEnterLobby)
    
    return true
end

function StatsSystem:Uninit()
    self.EventHelper:UnregisterAll()
    self.EventHelper = nil
end

function StatsSystem:GetComponent()
    local tbPlayerSelf = GamePlayerSelfHelper:Get()
    if tbPlayerSelf ~= nil then
        return tbPlayerSelf.StatsComponent
    end
end

function StatsSystem:RequestGetHistoryStats(nPlayerId)
    local szLastEvaluatedKey = ""
    if nPlayerId == nil then
        nPlayerId = GamePlayerSelfHelper:Get().nPlayerId
    end
    if nPlayerId == GamePlayerSelfHelper:Get().nPlayerId then
        local Component = self:GetComponent()
        szLastEvaluatedKey = Component:GetLastEvaluatedKey()
    end
    local c2s_GetHistoryStats = {
        player_id = nPlayerId,
        last_evaluated_key = szLastEvaluatedKey
    }
    SendPacket(Proto.c2s_GetHistoryStats, c2s_GetHistoryStats)
end

function StatsSystem:RequestGetHistoryStatsDetail(szDungeonId, nTeamId, nTeamMode)
    local c2s_GetHistoryStatsDetail = {
        dungeon_id = szDungeonId,
        team_id = nTeamId,
        team_mode = nTeamMode
    }
    SendPacket(Proto.c2s_GetHistoryStatsDetail, c2s_GetHistoryStatsDetail)
end

function StatsSystem:OnRecvGetHistoryStats(tbPacket)    
    if tbPacket.return_code ~= Proto.ReturnCode.OK then
        ShowErrorCode(tbPacket.return_code)
        -- return
    end

    local nCount = #tbPacket.stats
    if tbPacket.player_id == GamePlayerSelfHelper:Get().nPlayerId then
        local Component = self:GetComponent()
        Component:SetHistoryStats(tbPacket.stats, tbPacket.last_evaluated_key)
        tbPacket.stats = Component:GetHistoryStats()
    end
    local fnSort = function(a, b)
        if a.battle_time > b.battle_time then
            return true
        elseif b.battle_time > a.battle_time then
            return false
        else
            return a.dungeon_id > b.dungeon_id
        end
    end
    table.sort(tbPacket.stats, fnSort)
    EventManager:OnFireEvent(ClientEventDef.EV_ON_REFRESH_HISTORY_STATS, tbPacket, nCount, tbPacket.return_code == Proto.ReturnCode.OK) 
end

function StatsSystem:OnRecvGetHistoryStatsDetail(tbPacket)
    local Component = self:GetComponent()
    Component:SetHistoryStatsDetail(tbPacket)
    EventManager:OnFireEvent(ClientEventDef.EV_ON_REFRESH_HISTORY_STATS_DETAIL, 
        tbPacket.dungeon_id, tbPacket.team_id, tbPacket.mvp_player_id, tbPacket.detail)     
end

return StatsSystem
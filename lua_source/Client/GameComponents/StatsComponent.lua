local luaclass = require("luaclass")
local GameComponentBase = require("GameComponentBase")
local StatsComponent = luaclass("StatsComponent", GameComponentBase)
----------------------------------------------------------------------------------
StatsComponent.tbHistoryStats = nil --历史战绩
StatsComponent.szLastEvaluatedKey = nil

function StatsComponent:OnCreate(Owner, tbParams)
    StatsComponent.super.OnCreate(self, Owner, tbParams)
end

function StatsComponent:OnDestroy()
    -- self.tbHistoryStats = nil
    StatsComponent.super.OnDestroy(self)
end


function StatsComponent:SetHistoryStats(tbStats, szLastEvaluatedKey)
    if self.tbHistoryStats == nil then
        self.tbHistoryStats = {}
    end
    for i = #tbStats, 1, -1 do
        table.insert(self.tbHistoryStats, tbStats[i])
    end
    if szLastEvaluatedKey ~= nil and szLastEvaluatedKey ~= "" then
        self.szLastEvaluatedKey = szLastEvaluatedKey
    end
end

function StatsComponent:GetHistoryStats()
    return self.tbHistoryStats
end

function StatsComponent:GetLastEvaluatedKey()
    return self.szLastEvaluatedKey or ""
end

function StatsComponent:ClearHistoryStats()
    self.tbHistoryStats = nil
    self.szLastEvaluatedKey = nil
end

function StatsComponent:SetHistoryStatsDetail(tbPacket)
    if self.tbHistoryStats == nil then
        -- logerror("StatsComponent:SetHistoryStatsDetail, but not history stats")
        return
    end
    for i, v in ipairs(self.tbHistoryStats) do
        if v.dungeon_id == tbPacket.dungeon_id and v.team_id == tbPacket.team_id then
            self.tbHistoryStats[i].mvp_player_id = tbPacket.mvp_player_id
            self.tbHistoryStats[i].detail = tbPacket.detail
            break
        end
    end
end

function StatsComponent:GetHistoryStatsDetail(szDungeonId, nTeamId)
    if self.tbHistoryStats == nil then
        return
    end
    for i, v in ipairs(self.tbHistoryStats) do
        if v.dungeon_id == szDungeonId and v.team_id == nTeamId then
            return self.tbHistoryStats[i].detail, self.tbHistoryStats[i].mvp_player_id
        end
    end
end

return StatsComponent
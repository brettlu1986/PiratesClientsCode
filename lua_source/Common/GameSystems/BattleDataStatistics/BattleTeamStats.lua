
local luaclass = require("luaclass")
local BattleStatsBase = require("BattleStatsBase")
local BattleTeamStats = luaclass("BattleTeamStats", BattleStatsBase)
local BattleDataStatisticsPropertyDef = require("BattleDataStatisticsPropertyDef")
local BattleDataStatisticsEnum = require("BattleDataStatisticsEnum")

function BattleTeamStats:RegisterDefaultProperty()
    BattleTeamStats.super.RegisterDefaultProperty(self)
    for _, v in ipairs(BattleDataStatisticsPropertyDef.tbTeamPropertyDef) do
        if v.PropertySource == BattleDataStatisticsEnum.LuaScript then
            self:RegisterProperty(v.Name, v.DefaultValue)
        end
    end
end

function BattleTeamStats:Reset()
    for _, v in ipairs(BattleDataStatisticsPropertyDef.tbTeamPropertyDef) do
        if v.PropertySource == BattleDataStatisticsEnum.LuaScript then
            self:SetProperty(v.Name, v.DefaultValue)
        end
    end
end

return BattleTeamStats

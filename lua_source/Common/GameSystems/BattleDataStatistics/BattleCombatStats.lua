-----------------------------------------------------
--File Name    : BattleCombatStas.lua
--Author       : Chen Jing
--Create Time  : 2018-02-06
--Description  : 战斗内玩家数据统计
-----------------------------------------------------

local luaclass = require("luaclass")
local BattleStatsBase = require("BattleStatsBase")
local BattleCombatStats = luaclass("BattleCombatStats", BattleStatsBase)
local BattleDataStatisticsPropertyDef = require("BattleDataStatisticsPropertyDef")
local BattleDataStatisticsEnum = require("BattleDataStatisticsEnum")
local GlobalVariableSystem = dynamic_require("GlobalVariableSystem")
local PropertyDef = require("BattleDataStatisticsPropertyFieldDef")

function BattleCombatStats:RegisterDefaultProperty()
    BattleCombatStats.super.RegisterDefaultProperty(self)
    for _, v in ipairs(BattleDataStatisticsPropertyDef.tbCombatPropertyDef) do
        if v.PropertySource == BattleDataStatisticsEnum.LuaScript then
            self:RegisterProperty(v.Name, v.DefaultValue)
        end
    end
end

function BattleCombatStats:CaptureDungeonStartStatisticsData()
    self:SetProperty(PropertyDef.DUNGEONBEGINTIME, GlobalVariableSystem:GetLocalTime())
end

function BattleCombatStats:GetDungeonElapsedTime()
    local nDungeonBeginTime = self:GetProperty(PropertyDef.DUNGEONBEGINTIME)
    return GlobalVariableSystem:GetLocalTime() - nDungeonBeginTime
end

function BattleCombatStats:CaptureDungeonEndStatisticsData()
    local nDungeonBeginTime = self:GetProperty(PropertyDef.DUNGEONBEGINTIME)
    local nDungeonElapsed = GlobalVariableSystem:GetLocalTime() - nDungeonBeginTime
    if nDungeonElapsed > 0 then
        self:SetProperty(PropertyDef.DUNGEONELAPSEDTIME, nDungeonElapsed)
    else
        logwarning("[BattleCombatStats] CaptureDungeonEndStatisticsData dungeon end time is less than begin time")
    end
end

function BattleCombatStats:Reset()
    for _, v in ipairs(BattleDataStatisticsPropertyDef.tbCombatPropertyDef) do
        if v.PropertySource == BattleDataStatisticsEnum.LuaScript then
            self:SetProperty(v.Name, v.DefaultValue)
        end
    end
end

return BattleCombatStats

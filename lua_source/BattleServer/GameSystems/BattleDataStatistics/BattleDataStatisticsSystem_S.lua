-----------------------------------------------------
--File Name    : BattleDataStatisticsSystem_S.lua
--Author       : Song Fuhao
--Create Time  : 2017-08-29
--Description  : 战斗内数据统计
-----------------------------------------------------
local luaclass = require("luaclass")
local BattleDataStatisticsSystem = require("BattleDataStatisticsSystem")
local BattleDataStatisticsSystem_S = luaclass("BattleDataStatisticsSystem_S", BattleDataStatisticsSystem)

function BattleDataStatisticsSystem_S:Init()
    BattleDataStatisticsSystem_S.super.Init(self)
    
    return true
end

function BattleDataStatisticsSystem_S:Uninit()
    BattleDataStatisticsSystem_S.super.Uninit(self) 
    
end

return BattleDataStatisticsSystem_S()
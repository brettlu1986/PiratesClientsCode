-----------------------------------------------------
--File Name    : BattleCharacterStats.lua
--Author       : Song Fuhao
--Create Time  : 2017-08-29
--Description  : 战斗内数据统计
-----------------------------------------------------
local luaclass = require("luaclass")
local BattleStatsBase = require("BattleStatsBase")
local BattleCharacterStats = luaclass("BattleCharacterStats", BattleStatsBase)

BattleCharacterStats.tbCharacter = nil

function BattleCharacterStats:Create(tbCharacter)
    self.tbCharacter = tbCharacter
    BattleCharacterStats.super.Create(self)
end

function BattleCharacterStats:RegisterDefaultProperty()
    BattleCharacterStats.super.RegisterDefaultProperty(self)
    local tbCharacter = self.tbCharacter
    self:RegisterProperty("InstanceId", tbCharacter:GetServerInstanceId())
    self:RegisterProperty("Name", tbCharacter.szName)
end


return BattleCharacterStats

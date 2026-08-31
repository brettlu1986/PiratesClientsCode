-----------------------------------------------------
--File Name    : BattleEnableSkyAction.lua
--Author       : 
--Create Time  : 
--Description  : 启用昼夜系统
-----------------------------------------------------

local luaclass = require("luaclass")
local BattleActionBase = require("BattleActionBase")
local BattleEnableSkyAction = luaclass("BattleEnableSkyAction", BattleActionBase)

local BattleOperationHelper = require("BattleOperationHelper")
local BattleSkySystem = dynamic_require("BattleSkySystem")

BattleEnableSkyAction.nConfigIndex = 0

function BattleEnableSkyAction:Parse(tbJsonData)
    self.nConfigIndex = tbJsonData.ConfigIndex

    return true
end

function BattleEnableSkyAction:Execute()
    BattleOperationHelper:PrintLog(self, ", nConfigIndex: "..self.nConfigIndex)

    BattleSkySystem:EnableSky(self.nConfigIndex)
    return true
end

return BattleEnableSkyAction


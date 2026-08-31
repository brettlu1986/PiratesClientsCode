-----------------------------------------------------
--File Name    : BattleSetAdditionalSuccessCountAction.lua
--Author       : LiHui
--Create Time  : 
--Description  : 设置额外胜利名额数量，之所以设置成action是可以支持不同模式不同数量的功能。
-----------------------------------------------------

local luaclass = require("luaclass")
local BattleActionBase = require("BattleActionBase")
local BattleSetAdditionalSuccessCountAction = luaclass("BattleSetAdditionalSuccessCountAction", BattleActionBase)

local BattleOperationHelper = require("BattleOperationHelper")
local BattleFFAAdditionalSuccessHelper = require("BattleFFAAdditionalSuccessHelper")

BattleSetAdditionalSuccessCountAction.nCount = 0

function BattleSetAdditionalSuccessCountAction:Parse(tbJsonData)
    self.nCount = tbJsonData.Count or 0
    return true
end

function BattleSetAdditionalSuccessCountAction:Execute()

    BattleOperationHelper:PrintLog(self,
        "AdditionalSuccessCount: "..self.nCount)

    BattleFFAAdditionalSuccessHelper:SetAdditionSuccessCount(self.nCount)
    return true
end

return BattleSetAdditionalSuccessCountAction


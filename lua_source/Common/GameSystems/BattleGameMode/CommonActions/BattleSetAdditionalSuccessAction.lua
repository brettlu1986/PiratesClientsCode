-----------------------------------------------------
--File Name    : BattleSetAdditionalSuccessAction.lua
--Author       : LiHui
--Create Time  : 
--Description  : 额外胜利结算
-----------------------------------------------------

local luaclass = require("luaclass")
local BattleActionBase = require("BattleActionBase")
local BattleSetAdditionalSuccessAction = luaclass("BattleSetAdditionalSuccessAction", BattleActionBase)

local BattleOperationHelper = require("BattleOperationHelper")
local BattleBlackboard = require("BattleBlackboard")
local BattleFFAAdditionalSuccessHelper = require("BattleFFAAdditionalSuccessHelper")

BattleSetAdditionalSuccessAction.szGetObjKey      = nil
BattleSetAdditionalSuccessAction.nAdditionalAward = 0
BattleSetAdditionalSuccessAction.bStopGame        = nil

function BattleSetAdditionalSuccessAction:Parse(tbJsonData)
    self.szGetObjKey      = tbJsonData.GetObjKey
    self.nAdditionalAward = tbJsonData.AdditionalAward or 0
    self.bStopGame        = tbJsonData.StopGame or false

    return true
end

function BattleSetAdditionalSuccessAction:Execute()

    BattleOperationHelper:PrintLog(self,
        "GetObjKey: "..(self.szGetObjKey or "")..
        ", AdditionalAward: "..self.nAdditionalAward..
        ", StopGame: "..(self.bStopGame and "true" or "false"))

    local tbPlayer = nil
    if self.szGetObjKey and string.len(self.szGetObjKey) > 0 then
        tbPlayer = BattleBlackboard:GetTable(self.szGetObjKey)
        if not tbPlayer then
            error("BattleBlackboard:GetTable GetObjKey Failed. szGetObjKey:",self.szGetObjKey) 
            return false
        end
    end

    return BattleFFAAdditionalSuccessHelper:ProcessAdditionalSucessResult(tbPlayer,self.nAdditionalAward,self.bStopGame)
end

return BattleSetAdditionalSuccessAction


-----------------------------------------------------
--File Name    : BattleTryAdditionalSuccessAction.lua
--Author       : LiHui
--Create Time  : 
--Description  : 尝试额外胜利;首先判断是否还有名额，如果有则发送通知给客户端。
-----------------------------------------------------

local luaclass = require("luaclass")
local BattleActionBase = require("BattleActionBase")
local BattleTryAdditionalSuccessAction = luaclass("BattleTryAdditionalSuccessAction", BattleActionBase)

local BattleOperationHelper = require("BattleOperationHelper")
local BattleBlackboard = require("BattleBlackboard")
local BattleFFAAdditionalSuccessHelper = require("BattleFFAAdditionalSuccessHelper")

BattleTryAdditionalSuccessAction.szGetObjKey      = nil
BattleTryAdditionalSuccessAction.szSetObjKey      = nil
BattleTryAdditionalSuccessAction.nCDTime = 0

function BattleTryAdditionalSuccessAction:Parse(tbJsonData)
    self.szGetObjKey      = tbJsonData.GetObjKey
    self.nCDTime          = tbJsonData.CDTime or 0
    self.szSetObjKey      = tbJsonData.SetObjKey
    return true
end

function BattleTryAdditionalSuccessAction:Execute()

    BattleOperationHelper:PrintLog(self,
        "GetObjKey: "..(self.szGetObjKey or "")..
        "SetObjKey: "..(self.szSetObjKey or "")..
        ", nCDTime: "..self.nCDTime)

    local tbPlayer = nil
    if string.len(self.szGetObjKey) > 0 then
        tbPlayer = BattleBlackboard:GetTable(self.szGetObjKey)
        if not tbPlayer then
            return false
        end
    else
        return false
    end

    local bRet = BattleFFAAdditionalSuccessHelper:TryAdditionSuccess(tbPlayer,self.nCDTime)
    if string.len(self.szSetObjKey) > 0 then
        BattleBlackboard:SetBool(self.szSetObjKey,bRet)
    end

    return true
end

return BattleTryAdditionalSuccessAction


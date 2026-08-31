-----------------------------------------------------
--File Name    : BattleAddPlayerBuffLoginAction.lua
--Author       : 
--Create Time  : 
--Description  : 添加playerbuff
-----------------------------------------------------

local luaclass = require("luaclass")
local BattleActionBase = require("BattleActionBase")
local BattleAddPlayerBuffLoginAction = luaclass("BattleAddPlayerBuffLoginAction", BattleActionBase)

local BattleOperationHelper = require("BattleOperationHelper")
local BattleBlackboard = require("BattleBlackboard")
local BattleOperationDef = dynamic_require("BattleOperationDef")

BattleAddPlayerBuffLoginAction.nBuffId = nil
BattleAddPlayerBuffLoginAction.bRemoveBuff = nil
BattleAddPlayerBuffLoginAction.nOverlapCount = 0

function BattleAddPlayerBuffLoginAction:Parse(tbJsonData)
    self.nBuffId = tbJsonData.BuffId
    self.nOverlapCount = tbJsonData.OverlapCount    
    self.bRemoveBuff = tbJsonData.RemoveBuff
    return self.nBuffId > 0
end

function BattleAddPlayerBuffLoginAction:Execute()

    BattleOperationHelper:PrintLog(self,
        ", BuffId: "..self.nBuffId..
        ", OverlapCount: "..self.nOverlapCount..
        ", RemoveBuff: "..(self.bRemoveBuff and "true" or "false"))

    if self.nOverlapCount < 1 then 
        self.nOverlapCount = 1
    end
    
    local tbPlayer = BattleBlackboard:GetTable(BattleOperationDef.CurrentObject)
    if tbPlayer ~= nil then
        if not self.bRemoveBuff  then
            tbPlayer.BuffComponentServer:AddBuffById(self.nBuffId, self.nOverlapCount)
        else
            tbPlayer.BuffComponentServer:RemoveBuffById(self.nBuffId)
        end
    else
        logerror("Can't find Player")
        return false
    end

    return true
end

return BattleAddPlayerBuffLoginAction


local luaclass = require("luaclass")
local BattleActionBase = require("BattleActionBase")
local BattleSetBattleStatisticsAction = luaclass("BattleSetBattleStatisticsAction", BattleActionBase)

local BattleBlackboard = require("BattleBlackboard")
local BattleOperationHelper = require("BattleOperationHelper")
local GameObjectTypeDef = require("GameObjectTypeDef")
local BattleDataStatisticsSystem = dynamic_require("BattleDataStatisticsSystem")

BattleSetBattleStatisticsAction.szObjKey = nil
BattleSetBattleStatisticsAction.szStatisticsKey = nil
BattleSetBattleStatisticsAction.nNum = nil

function BattleSetBattleStatisticsAction:Parse(tbJsonData)
    self.szObjKey = tbJsonData.ObjKey
    self.szStatisticsKey = tbJsonData.StatisticsKey
    self.nNum = tbJsonData.Num
    return true
end

function BattleSetBattleStatisticsAction:Execute()
    BattleOperationHelper:PrintLog(self, "ObjKey: "..self.szObjKey..
        ", StatisticsKey: "..self.szStatisticsKey..
        ", Num: "..self.nNum)

    if self.szObjKey and string.len(self.szObjKey) > 0 then 
        local tbObject = BattleBlackboard:GetTable(self.szObjKey)
        if tbObject then
            if self.szStatisticsKey and string.len(self.szStatisticsKey) > 0 then
                if tbObject.ObjectType == GameObjectTypeDef.PlayerSelf then
                    local nPlayerId = tbObject:GetPlayerId()
                    local szStatisticsKey = self.szStatisticsKey
                    local nNum = self.nNum > 0 and self.nNum or 1
                    BattleDataStatisticsSystem:StatisticsPlayerProperty(nPlayerId, szStatisticsKey, nNum)
                end
            end
        end
    end
    
    return true
end

return BattleSetBattleStatisticsAction
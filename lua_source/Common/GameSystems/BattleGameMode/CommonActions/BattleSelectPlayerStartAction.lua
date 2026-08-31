local luaclass = require("luaclass")
local BattleActionBase = require("BattleActionBase")
local BattleSelectPlayerStartAction = luaclass("BattleSelectPlayerStartAction", BattleActionBase)

local BattleGameModeSystem = dynamic_require("BattleGameModeSystem")
local BattleOperationDef = dynamic_require("BattleOperationDef")
local BattleOperationHelper = require("BattleOperationHelper")
local CampDefine = require("CampDefine")
local BattleBlackboard = require("BattleBlackboard")

BattleSelectPlayerStartAction.tbNoUsedPoints = nil
BattleSelectPlayerStartAction.tbUsedPoints = nil
BattleSelectPlayerStartAction.nCount = nil

BattleSelectPlayerStartAction.bUniquePoint = false
BattleSelectPlayerStartAction.nGroupIndex = nil
BattleSelectPlayerStartAction.nSubGroupIndex = nil
BattleSelectPlayerStartAction.nCamp = nil


local function Check(self, tbPlayerStart)
    return (self.nCampType == CampDefine.Type.CAMP_NONE or self.nCampType == tbPlayerStart.CampType)
        and self.nGroupIndex == tbPlayerStart.GroupIndex
        and self.nSubGroupIndex == tbPlayerStart.SubGroupIndex
end

function BattleSelectPlayerStartAction:Parse(tbJsonData)    
    self.bUniquePoint = tbJsonData.UniquePoint
    self.nGroupIndex = tbJsonData.Group
    self.nSubGroupIndex = tbJsonData.SubGroup
    self.nCampType = tbJsonData.CampType
    if(self.bUniquePoint) then
        self.tbUsedPoints = {}
    else
        self.tbUsedPoints = nil
    end

    local tbNoUsedPoints = {}
    local tbGameMode = BattleGameModeSystem:GetGameMode()
    local tbPlayerStarts = tbGameMode.tbJsonTableFile.tbContainer.DungeonPlayerStarts
    if(tbPlayerStarts) then
        for i, v in ipairs(tbPlayerStarts) do
            if(Check(self, v)) then
                table.insert(tbNoUsedPoints, v)
            end
        end
    end
    self.tbNoUsedPoints = tbNoUsedPoints
    self.nCount = #tbNoUsedPoints
    return self.nCount > 0
end

function BattleSelectPlayerStartAction:Execute()
    local tbPlayer = BattleBlackboard:GetTable(BattleOperationDef.CurrentObject)
    if(tbPlayer == nil) then
        BattleOperationHelper:PrintLog(self, "Can not find player from blackboard")
        return false
    end
    
    local nId = tbPlayer:GetServerInstanceId()
    local tbUsedPoints = self.tbUsedPoints
    local tbNoUsedPoints = self.tbNoUsedPoints
    local nNoUsedCount = #tbNoUsedPoints  

    local NewPoint, nIndex
    if(self.bUniquePoint) then
        if(nNoUsedCount == 0) then            
            -- 都用光了，随机在使用的点里找一个
            nIndex = math.random(1, self.nCount)
            for _, Point in pairs(tbUsedPoints) do
                nIndex = nIndex - 1
                if(nIndex == 0) then
                    NewPoint = Point
                    break
                end
            end
        else
            -- 在没用光的点里找
            nIndex = math.random(1, nNoUsedCount)
            NewPoint = tbNoUsedPoints[nIndex]
            table.remove(tbNoUsedPoints, nIndex)
            tbUsedPoints[nId] = NewPoint
        end
    else
        nIndex = math.random(1, nNoUsedCount)
        NewPoint = tbNoUsedPoints[nIndex]        
    end

    if(NewPoint == nil) then
        BattleBlackboard:SetTable(BattleOperationDef.CurrentPlayerStart, nil)    
        BattleOperationHelper:PrintError(self, "BattleSelectPlayerStartAction failed, can not find point")
        return false
    end

    local tbTransform = NewPoint.Transform
    BattleOperationHelper:PrintLog(self, "X: "..tbTransform.X..
        ", Y: "..tbTransform.Y..
        ", Z: "..tbTransform.Z..
        ", Yaw: "..tbTransform.Yaw)
    BattleBlackboard:SetTable(BattleOperationDef.CurrentPlayerStart, NewPoint)
    return true
end

return BattleSelectPlayerStartAction
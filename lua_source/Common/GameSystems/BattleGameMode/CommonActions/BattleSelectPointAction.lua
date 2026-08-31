local luaclass = require("luaclass")
local BattleActionBase = require("BattleActionBase")
local BattleSelectPointAction = luaclass("BattleSelectPointAction", BattleActionBase)

local BattleOperationDef = dynamic_require("BattleOperationDef")
local BattleTransformPointHelper = require("BattleTransformPointHelper")
local BattleBlackboard = require("BattleBlackboard")
local BattleOperationHelper = require("BattleOperationHelper")
local TransformDef = require("BattleTransformDef")

BattleSelectPointAction.bUniquePoint = false
BattleSelectPointAction.tbUsedPoints = nil
BattleSelectPointAction.tbNoUsedPoints = nil

function BattleSelectPointAction:Parse(tbJsonData)    
    self.bUniquePoint = tbJsonData.UniquePoint
    self.nTransformId = tbJsonData.TransformId

    if(self.bUniquePoint) then
        self.tbUsedPoints = {}
    else
        self.tbUsedPoints = nil
    end

    local TransformType = TransformDef.TransformType
    local tbNoUsedPoints = {}
    local fnParseGroup = function(tbPoints)
        if tbPoints.StartPoint and tbPoints.EndPoint then
            table.insert(tbNoUsedPoints, tbPoints)
        else
            local tbGroup = tbPoints.Group
            for _, v in ipairs(tbGroup) do
                table.insert(tbNoUsedPoints, v)
            end
        end    
    end

    local tbPoint = BattleTransformPointHelper:Find(self.nTransformId)
    if (tbPoint) then
        if (tbPoint.Type == TransformType.Point) then
            table.insert(tbNoUsedPoints, tbPoint)
        elseif (tbPoint.Type == TransformType.Transform) then
            fnParseGroup(tbPoint)
        elseif (tbPoint.Type == TransformType.Volume) then
            local tbVolume = tbPoint.Volume
            for k, v in ipairs(tbVolume) do
                local tbVolumePoint = BattleTransformPointHelper:Find(v)
                fnParseGroup(tbVolumePoint)
            end
        end
    else
        error(string.format("BattleSelectPointAction not find transform: %d", self.nTransformId))
    end
    self.tbNoUsedPoints = tbNoUsedPoints
    
    return #tbNoUsedPoints > 0
end

local function RandomPoint(tbStartPoint, tbEndPoint)
    local tbTransform = {}
    tbTransform.X = math.random(tbStartPoint.X, tbEndPoint.X)
    tbTransform.Y = math.random(tbStartPoint.Y, tbEndPoint.Y)
    tbTransform.Z = tbStartPoint.Z
    tbTransform.Yaw = 0
    return tbTransform
end

local function RandomArray(tbGroup) 
    local nIndex = math.random(1, #tbGroup)
    return tbGroup[nIndex]
end

function BattleSelectPointAction:Execute()
    local tbUsedPoints = self.tbUsedPoints
    local tbNoUsedPoints = self.tbNoUsedPoints
    local nNoUsedCount = #tbNoUsedPoints

    local NewPoint, nIndex

    local tbPoint = RandomArray(tbNoUsedPoints)
    if tbPoint.StartPoint then
        NewPoint = RandomPoint(tbPoint.StartPoint, tbPoint.EndPoint)
        NewPoint.Yaw = tbPoint.Yaw
    else
        if(self.bUniquePoint) then
            if(nNoUsedCount == 0) then
                -- 都用光了，随机在使用的点里找一个
                nIndex = math.random(1, #tbUsedPoints)
                NewPoint = tbUsedPoints[nIndex]
            else
                -- 在没用光的点里找
                nIndex = math.random(1, nNoUsedCount)
                NewPoint = tbNoUsedPoints[nIndex]
                table.remove(tbNoUsedPoints, nIndex)
                table.insert(tbUsedPoints, NewPoint)
            end
        else
            nIndex = math.random(1, nNoUsedCount)
            NewPoint = tbNoUsedPoints[nIndex]        
        end
    end
    if(NewPoint == nil) then
        BattleBlackboard:SetTable(BattleOperationDef.CurrentPoint, nil)    
        BattleOperationHelper:PrintError(self, "BattleSelectPointAction failed, can not find point")
        return false
    end

    BattleOperationHelper:PrintLog(self, "TransformId: "..self.nTransformId..
        ", X: "..NewPoint.X..
        ", Y: "..NewPoint.Y..
        ", Z: "..NewPoint.Z..
        ", Yaw: "..NewPoint.Yaw)
    BattleBlackboard:SetTable(BattleOperationDef.CurrentPoint, NewPoint)
    return true
end

return BattleSelectPointAction
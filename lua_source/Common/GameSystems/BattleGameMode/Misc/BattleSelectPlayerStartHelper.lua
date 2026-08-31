local BattleSelectPlayerStartHelper = {}

local BattleGameModeSystem = dynamic_require("BattleGameModeSystem")
local CampDefine = require("CampDefine")

BattleSelectPlayerStartHelper.tbNoUsedPointsList = nil
BattleSelectPlayerStartHelper.tbUsedPointsList = nil
BattleSelectPlayerStartHelper.tbCountList = nil


function BattleSelectPlayerStartHelper:Init()
    self.tbNoUsedPointsList = {}
    self.tbUsedPointsList = {}
    self.tbCountList = {}
end

function BattleSelectPlayerStartHelper:Uninit()
    self.tbNoUsedPointsList = nil
    self.tbUsedPointsList = nil
    self.tbCountList = nil
end

local function Check(self, tbPlayerStart)
    return (self.nCampType == CampDefine.Type.CAMP_NONE or self.nCampType == tbPlayerStart.CampType)
        and self.nGroupIndex == tbPlayerStart.GroupIndex
        and self.nSubGroupIndex == tbPlayerStart.SubGroupIndex
end

function BattleSelectPlayerStartHelper:PlayerSelectPoint(tbPlayer, bUniquePoint, nCampType, nGroupIndex, nSubGroupIndex)
    self.bUniquePoint = bUniquePoint
    self.nGroupIndex = nGroupIndex
    self.nSubGroupIndex = nSubGroupIndex
    self.nCampType = nCampType

    local szKey = self.nCampType..self.nGroupIndex..self.nSubGroupIndex
    
    if self.tbUsedPointsList[szKey] == nil then
        self.tbUsedPointsList[szKey] = {}
    end

    local tbNoUsedPoints = {}
    if self.tbNoUsedPointsList[szKey] then
        tbNoUsedPoints = self.tbNoUsedPointsList[szKey]
    else
        local tbGameMode = BattleGameModeSystem:GetGameMode()
        local tbPlayerStarts = tbGameMode.tbJsonTableFile.tbContainer.DungeonPlayerStarts
        if(tbPlayerStarts) then
            for i, v in ipairs(tbPlayerStarts) do
                if(Check(self, v)) then
                    table.insert(tbNoUsedPoints, v)
                end
            end
        end
        self.tbNoUsedPointsList[szKey] = tbNoUsedPoints
        self.tbCountList[szKey] = #tbNoUsedPoints
        if self.tbCountList[szKey] <= 0 then
            logerror("No match points to use.")
        end
    end

    local nId = tbPlayer:GetServerInstanceId()
    local tbUsedPoints = self.tbUsedPointsList[szKey]
    local nNoUsedCount = #tbNoUsedPoints
    local NewPoint, nIndex
    if(self.bUniquePoint) then
        -- 修改如果已经选过出生点则还用之前的点
        if tbUsedPoints[nId] then
            NewPoint = tbUsedPoints[nId]
        else
            if(nNoUsedCount == 0) then            
                -- 都用光了，随机在使用的点里找一个
                nIndex = math.random(1, self.tbCountList[szKey])
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
        end
    else
        nIndex = math.random(1, nNoUsedCount)
        NewPoint = tbNoUsedPoints[nIndex]        
    end

    return NewPoint
end

return BattleSelectPlayerStartHelper
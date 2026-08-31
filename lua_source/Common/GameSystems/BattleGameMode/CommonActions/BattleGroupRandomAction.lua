local luaclass = require("luaclass")
local BattleActionBase = require("BattleActionBase")
local BattleGroupRandomAction = luaclass("BattleGroupRandomAction", BattleActionBase)

local BattleOperationHelper = require("BattleOperationHelper")

BattleGroupRandomAction.tbTempActions = nil
BattleGroupRandomAction.tbActions = nil
BattleGroupRandomAction.tbTempPercent = nil
BattleGroupRandomAction.tbPercent = nil
BattleGroupRandomAction.nCount = nil
BattleGroupRandomAction.tbGroup = nil
BattleGroupRandomAction.bForceStop = false

function BattleGroupRandomAction:Parse(tbJsonData)
    self.tbActions = {}
    self.tbPercent = tbJsonData.Percent
    self.nCount = tbJsonData.Count
    local tbGroup = tbJsonData.Group

    for i, Data in ipairs(tbGroup) do
        local Action = BattleOperationHelper:Create(self, Data)
        if(Action == nil) then
            BattleOperationHelper:PrintError(self, "Create Action failed, index: "..i)
            return false
        end
        table.insert(self.tbActions, Action)        
    end

    

    return true
end

function BattleGroupRandomAction:GetSumPercent()
    local nSum = 0;
    if self.tbTempPercent then
        for i, Percent in ipairs(self.tbTempPercent) do
            nSum = nSum + Percent
        end
    end
    return nSum
end

local function GetSum(tbTable, begin)
    local nSum = 0;
    local nCount = #tbTable
    for i = begin, nCount do
        nSum = nSum + tbTable[i]
    end
    return nSum
end

function BattleGroupRandomAction:GetHitIndex(tbTable, begin)
    local nSum = 0;
    local nCount = #tbTable
    local nSumPercent = GetSum(tbTable, begin)
    local nRandom = math.random(0, nSumPercent)
    if tbTable then
        for i = begin, nCount do
            nSum = nSum + tbTable[i]
            if nRandom <= nSum then 
                return i
            end
        end
    end
    return 0
end

local function GetRandomIndex(tbPercent, begin)
    local nSumPercent = GetSum(tbPercent, begin)
    local nRandom = math.random(0, nSumPercent)
    local nCount = #tbPercent
    local nSum = 0;
    if tbPercent then
        for i = begin, nCount do
            nSum = nSum + tbPercent[i]
            if nRandom <= nSum then 
                return i
            end
        end
    end
    return 0
end

function BattleGroupRandomAction:GetRandomActions(tbPercent, tbAction, nCount)
    if nCount >= #tbAction then
        return
    end
    for i = 1, nCount do
        local nRandomIndex = GetRandomIndex(tbPercent, i)
        local percent1, percent2 = tbPercent[i], tbPercent[nRandomIndex]
        tbPercent[i], tbPercent[nRandomIndex] = percent2, percent1
        local action1, action2 = tbAction[i], tbAction[nRandomIndex]
        tbAction[i], tbAction[nRandomIndex] = action2, action1
    end
end

function BattleGroupRandomAction:RandomActionIndex()
    local nIndex = 0
    local nSumPercent = self:GetSumPercent()
    local nRandom = math.random(0, nSumPercent)
    nIndex = self:GetHitIndex(nRandom)
    return nIndex
end

function BattleGroupRandomAction:Execute()
    BattleOperationHelper:PrintLog(self, "")

    self.bForceStop = false
    self.tbTempPercent = {}
    self.tbTempActions = {}
    for _, percent in ipairs(self.tbPercent) do
        table.insert( self.tbTempPercent, percent )
    end

    for _, action in ipairs(self.tbActions) do
        table.insert( self.tbTempActions, action )
    end
    -- 修改 返回action表
    self:GetRandomActions(self.tbTempPercent, self.tbTempActions, self.nCount)
    
    for i = 1, self.nCount, 1 do
        if not self.tbTempActions[i]:Execute() then
            return false
        end            
        if(self.bForceStop) then
            return true
        end
   end

   return true
end

function BattleGroupRandomAction:Uninit()
    local tbActions = self.tbActions
    local nCount = #tbActions
    for i=1, nCount do
        tbActions[i]:Uninit()
    end
    BattleGroupRandomAction.super.Uninit(self)
end

function BattleGroupRandomAction:ForceStop()
    self.bForceStop = true
    local tbActions = self.tbActions
    local nCount = #tbActions
    for i=1, nCount do
        tbActions[i]:ForceStop()
    end
    BattleGroupRandomAction.super.ForceStop(self)
end

return BattleGroupRandomAction
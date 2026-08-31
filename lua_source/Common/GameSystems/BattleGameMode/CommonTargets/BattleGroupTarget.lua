local luaclass = require("luaclass")
local BattleTargetBaseClass = require("BattleTargetBase")
local BattleGroupTarget = luaclass("BattleGroupTarget", BattleTargetBaseClass)

local BattleOperationHelper = require("BattleOperationHelper")

BattleGroupTarget.tbTargets = nil
BattleGroupTarget.szOperator = nil

function BattleGroupTarget:Init()
    BattleGroupTarget.super.Init(self)
    self.szName = "BattleGroupTarget"
end

function BattleGroupTarget:Uninit()
    if(self.tbTargets) then
        for i, v in ipairs(self.tbTargets) do
            v:Uninit()
        end
    end
    BattleGroupTarget.super.Uninit(self)
end

function BattleGroupTarget:ForceStop()
    BattleGroupTarget.super.ForceStop(self)

    if(self.tbTargets) then
        for i, v in ipairs(self.tbTargets) do
            v:ForceStop()
        end
    end 
end

local function OnTargetCompleted(self, Target)    
    local tbTargets = self.tbTargets
    local nCount = #tbTargets
    local bRet = tbTargets[1]:IsCompleted()

    for i=2, nCount do
        bRet = BattleOperationHelper:CallOperator(self.szOperator, tbTargets[i]:IsCompleted(), bRet)
    end

    if(bRet) then
        self:Complete()
    end
end

function BattleGroupTarget:Start()
    BattleGroupTarget.super.Start(self)
    
    local tbTargets = self.tbTargets
    for i, Target in ipairs(tbTargets) do
        Target:Start()
        if(self:IsCompleted()) then
            break
        end
    end
end

function BattleGroupTarget:AddTarget(Target)
    table.insert(self.tbTargets, Target)
end

function BattleGroupTarget:RemoveTarget(Target)
    for i, v in ipairs(self.tbTargets) do
        if(v == Target) then
            Target:SetCompleteCallback(nil)
            table.remove(self.tbTargets, i)
            break
        end
    end
end

function BattleGroupTarget:SetOperator(nOperator)
    self.nOperator = nOperator
end

function BattleGroupTarget:Parse(tbJsonData)
    self.szOperator = tbJsonData.Operator
    self.tbTargets = {}
    local fnCallback = function(Target)
        OnTargetCompleted(self, Target)
    end
    
    local tbTargetGroup = tbJsonData.Group
    for i, TargetData in ipairs(tbTargetGroup) do
        local Target = BattleOperationHelper:Create(self, TargetData)
        if(Target == nil) then
            BattleOperationHelper:PrintError(self, "Create Target failed, target index: "..i)
            return false
        end
        self:AddTarget(Target)
        Target:SetCompleteCallback(fnCallback)
    end
    if(#self.tbTargets == 0) then
        BattleOperationHelper:PrintError(self, "No Target in target group")
        return false
    end
    return true
end

function BattleGroupTarget:OnCompleted()
    BattleGroupTarget.super.OnCompleted(self)
    -- 把子节点都强停掉
    self:ForceStop()
end

return BattleGroupTarget
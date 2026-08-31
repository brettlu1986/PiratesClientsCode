local luaclass = require("luaclass")
local StepHelper = luaclass("StepHelper")

StepHelper.nStepIndex = 0
StepHelper.tbSteps = nil

function StepHelper:construct()
    self.nStepIndex = 0
    self.tbSteps = {}
end

function StepHelper:AddStepMethod(Class, Method, szTag)
    local tbData = {}
    tbData.Class = Class
    tbData.Func = Method
    tbData.szTag = szTag
    table.insert(self.tbSteps, tbData)
    return #self.tbSteps
end

function StepHelper:RemoveStepMethod(Class, Method)
    local tbSteps = self.tbSteps
    local tbData
    local nCount = #tbSteps
    for i=1, nCount do
        tbData = tbSteps[i]
        if(tbData.Class == Class and tbData.Func == Method) then
            table.remove(tbSteps, i)
            return true
        end
    end
    return false
end

function StepHelper:AddStepFunc(Func, szTag)
    self:AddStepMethod(nil, Func, szTag)
end

function StepHelper:RemoveStepFunc(Func)
    self:RemoveStepFunc(nil, Func)
end

function StepHelper:Start()
    self:StepNext()
end

local function ActivateStep(self, nIndex)
    local tbSteps = self.tbSteps
    if(nIndex > 0 and nIndex <= #tbSteps) then
        self.nStepIndex = nIndex
        local tbData = tbSteps[nIndex]
        if(tbData.Func == nil) then
            log("StepHelper:ActivateStep ignore step with nil func", nIndex, tbData.szTag)
            return false
        end
        
        if(tbData.Class) then
            tbData.Func(tbData.Class)
        else
            tbData.Func()
        end
        return true
    end
    return false
end

function StepHelper:StepNext()
    return ActivateStep(self.nStepIndex + 1)
end

function StepHelper:Restart()
    self.nStepIndex = 0
    self:Start()
end

function StepHelper:Clear()
    self.nStepIndex = 0
    self.tbSteps = {}
end

function StepHelper:GetCurrentStepTag()
    local tbSteps = #self.tbSteps
    local nCount = #tbSteps
    local nCurrentIndex = self.nStepIndex
    if(nCurrentIndex > 0 and nCurrentIndex <= nCount) then
        return tbSteps[nCurrentIndex].szTag
    end
    return nil
end

return StepHelper
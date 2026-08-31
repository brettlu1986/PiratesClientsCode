local ProcedureManager = {}

ProcedureManager.CurrentActiveProcedure = nil
ProcedureManager.tbProcedures = nil

function ProcedureManager:Init()
    self.tbProcedures = {}
    local ProcedureRegister = require("ProcedureRegister")
    ProcedureRegister:Register(self)
    return true
end

local function ProcessOnProcedureCompleted(self, NextProcedureName, tbNextProcedureParams, tbEndParams)
    self:ActiveProcedure(NextProcedureName, tbNextProcedureParams, tbEndParams, false)
end

function ProcedureManager:RegistProcedure(ProcedureName)
    local ProcClass = require(ProcedureName)
    local RetProc = ProcClass()
    RetProc:Init()
    RetProc.Name = ProcedureName
    RetProc:SetOnProcedureCompleted(self, ProcessOnProcedureCompleted)
    table.insert(self.tbProcedures, RetProc)
    return RetProc
end

function ProcedureManager:ActiveProcedure(NewProcedure, tbActiveProcedureParams, tbEndParam, bForce)
    local CurrentProc = self.CurrentActiveProcedure;

    if (not bForce and NewProcedure and CurrentProc == NewProcedure) then
        logwarning("Duplicated procedure activated: ", NewProcedure.Name)
        return
    end

    if (CurrentProc) then
        log("Procedure", CurrentProc.Name, "end...")
        CurrentProc:End(tbEndParam)
    end

    self.CurrentActiveProcedure = NewProcedure
    if (NewProcedure) then
        log("Procedure", NewProcedure.Name, "begin...")
        NewProcedure.Param = tbActiveProcedureParams
        NewProcedure:Begin()
    else
        log("ProcedureManager:ActiveProcedure, no new procedure ", debug.traceback( ))
    end
end

function ProcedureManager:Uninit()
    -- 这里可能不该强制切状态，因为有可能上一个状态还没运行完，强制关闭可能会有问题
    --self:ActiveProcedure(nil)

    local tbProc = self.tbProcedures
    local nCount = #tbProc
    for i=1, nCount do
        tbProc[i]:Uninit()
    end
    self.tbProcedures = nil
end

return ProcedureManager

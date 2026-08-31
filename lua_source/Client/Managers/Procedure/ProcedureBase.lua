local luaclass = require("luaclass")
local ProcedureBase = luaclass("ProcedureBase")
local EventManager = require("EventManager")

ProcedureBase.Param = nil
ProcedureBase.OnProcedureCompleted = nil
ProcedureBase.GlobalEventList = {}

function ProcedureBase:Init()
end

function ProcedureBase:Uninit()
end

function ProcedureBase:Begin()
end

function ProcedureBase:End(tbEndParams)
    self:UnbindAllEvents()
end

function ProcedureBase:BindEvent(varEvent, fnCallback)
    EventManager:BindEvent(varEvent, fnCallback)
    table.insert(self.GlobalEventList, {varEvent, fnCallback})
end

function ProcedureBase:UnbindAllEvents()
    local GlobalEventList = self.GlobalEventList
    for i,v in ipairs(GlobalEventList) do
        local varEvent = v[1]
        local fnCallback = v[2]
        if (varEvent and fnCallback) then
            EventManager:UnBindEvent(varEvent, fnCallback)
        end
        GlobalEventList[i] = nil
    end
end

function ProcedureBase:SetOnProcedureCompleted(obj, func)
    self.OnProcedureCompleted = {obj, func}
end

function ProcedureBase:Complete(NextProc, Param, tbEndParams)
    local OnProcCompleted = self.OnProcedureCompleted
    if (OnProcCompleted) then
        local Obj = OnProcCompleted[1]
        local Func = OnProcCompleted[2]
        Func(Obj, NextProc, Param, tbEndParams)
    end
end

return ProcedureBase

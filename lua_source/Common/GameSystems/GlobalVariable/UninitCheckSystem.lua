local UninitCheckSystem = {}

local tbHelpers = nil

function UninitCheckSystem:Init()
    tbHelpers = {}
    return true
end

function UninitCheckSystem:Uninit()
    self:ExecCheck()
    tbHelpers = nil
end

function UninitCheckSystem:Register(tbHelper)
    if GWithEditor then
        tbHelpers[tbHelper] = debug.traceback()
    end
end

function UninitCheckSystem:Unregister(tbHelper)
    tbHelpers[tbHelper] = nil
end

function UninitCheckSystem:ExecCheck()
    if not tbHelpers then 
        return 
    end 
    
    for k,v in pairs(tbHelpers) do
        logerror("!!!!!!!!!!!!! Need call helper uninit,", v)
    end
end

return UninitCheckSystem

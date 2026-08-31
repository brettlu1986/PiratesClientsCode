local SessionSystem = {}

SessionSystem.Type = require("SessionType")
SessionSystem.tbClasses = nil
SessionSystem.tbAlivedInstances = nil

function SessionSystem:Init()
    self.tbClasses = {}
    self.tbAlivedInstances = {}
    dynamic_require("SessionRegister"):Register(self)
end

function SessionSystem:Uninit()
    for k, v in pairs(self.tbAlivedInstances) do
        error("Session has not finished")
    end

    self.tbClasses = nil
    self.tbAlivedInstances = nil
end

function SessionSystem:Register(nType, szFileName)
    local Class = require(szFileName)
    assert(Class)
    assert(self.tbClasses[nType] == nil)
    self.tbClasses[nType] = Class
end

function SessionSystem:StartSession(nType, tbParams, tbSelf, fnOnFinished)
    local Class = self.tbClasses[nType]
    if(Class == nil) then
        error("StartSession failed, invalid type: ")
    end

    local Instance = Class()
    Instance.nType = nType
    Instance.fnNotifyFinishedToParent = function(EndInstance)
        self:FinishSession(EndInstance)
    end

    local tbInfo = {}
    tbInfo.tbSelf = tbSelf
    tbInfo.fnOnFinished = fnOnFinished
    self.tbAlivedInstances[Instance] = tbInfo

    Instance:OnStarted(tbParams)
    return Instance
end

function SessionSystem:FinishSession(Instance)
    local tbInfo = self.tbAlivedInstances[Instance]
    if(not tbInfo) then
        error("Invalid session instance")
        return false
    end
    self.tbAlivedInstances[Instance] = nil

    Instance:OnFinished()

    if(tbInfo.fnOnFinished) then
        if(tbInfo.tbSelf) then
            tbInfo.fnOnFinished(tbInfo.tbSelf, Instance)
        else
            tbInfo.fnOnFinished(Instance)
        end
    end    
    return true
end

function SessionSystem:GetAlivedSession(nType)
    if(self.tbAlivedInstances) then
        for k, v in pairs(self.tbAlivedInstances) do
            if(k.nType == nType) then
                return k
            end
        end
    end
    return nil
end

return SessionSystem
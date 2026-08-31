local luaclass = require("luaclass")
local SessionBase = luaclass("SessionBase")

SessionBase.fnNotifyFinishedToParent = nil
SessionBase.tbParams = nil

function SessionBase:OnStarted(tbParams)
    self.tbParams = tbParams
end

function SessionBase:OnFinished()
end

function SessionBase:FinishSelf()
    if(self.fnNotifyFinishedToParent) then
        self.fnNotifyFinishedToParent(self)
    end
end

return SessionBase
local luaclass = require("luaclass")
local CommonAwardSession = luaclass("CommonAwardSession")

CommonAwardSession.fnNotifyFinishedToParent = nil
CommonAwardSession.nType    = nil
CommonAwardSession.tbParams = nil

function CommonAwardSession:OnStarted(tbParams)
    self.tbParams = tbParams
end

function CommonAwardSession:OnFinished()

end

function CommonAwardSession:OnCanceled()
    self:FinishSelf()
end

function CommonAwardSession:FinishSelf()
    if(self.fnNotifyFinishedToParent) then
        self.fnNotifyFinishedToParent(self)
    end
end

function CommonAwardSession:TryFinish()
    self:FinishSelf()
end

function CommonAwardSession:CheckShowAward(nSourceType)
    return true
end

return CommonAwardSession
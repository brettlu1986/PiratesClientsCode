local luaclass = require("luaclass")
local BattleTargetBase = luaclass("BattleTargetBase")

local CommonEventDef = require("CommonEventDef")
local EventManager = require("EventManager")

local BattleOperationHelper = require("BattleOperationHelper")

BattleTargetBase.szName = nil
BattleTargetBase.bCompleted = false
BattleTargetBase.bStarted = false
BattleTargetBase.fnCompleteCallback = nil

function BattleTargetBase:Init()
    self.bCompleted = false
    self.bStarted = false
    self.fnCompleteCallback = nil
end

function BattleTargetBase:Uninit()
    self:UnregisterEvent()
    self.fnCompleteCallback = nil
end

function BattleTargetBase:Start()
    BattleOperationHelper:PrintLog(self, "Start")
    self:RegisterEvent()
    self.bStarted = true
    self.bCompleted = false
    EventManager:OnFireEvent(CommonEventDef.EV_BATTLE_TARGET_START, self)
end

function BattleTargetBase:OnCompleted()
end

function BattleTargetBase:Complete()
    BattleOperationHelper:PrintLog(self, "Complete")
    self.bCompleted = true
    self:UnregisterEvent()
    self:OnCompleted()

    if(self.fnCompleteCallback) then
        self.fnCompleteCallback(self)
    end
    EventManager:OnFireEvent(CommonEventDef.EV_BATTLE_TARGET_COMPLETE, self)
end

function BattleTargetBase:OnForceStop()
    
end

function BattleTargetBase:ForceStop()        
    if(not self.bCompleted and self.bStarted) then
        BattleOperationHelper:PrintLog(self, "ForceStop")
        self:UnregisterEvent()
        self:OnForceStop()
        self.bStarted = false
    end    
end

function BattleTargetBase:IsStarted()
    return self.bStarted
end

function BattleTargetBase:IsCompleted()
    return self.bCompleted
end

function BattleTargetBase:RegisterEvent()

end

function BattleTargetBase:UnregisterEvent()
end

function BattleTargetBase:SetCompleteCallback(fnCompleteCallback)
    self.fnCompleteCallback = fnCompleteCallback
end

function BattleTargetBase:Parse(tbJsonData)
    error("BattleTargetBase:Parse failed, has no implemention ".. self.szName)
    return false
end

return BattleTargetBase
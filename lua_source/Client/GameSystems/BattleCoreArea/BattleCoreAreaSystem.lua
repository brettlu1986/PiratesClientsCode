local BattleCoreAreaSystem = {}

BattleCoreAreaSystem.bShowCoreArea = nil

function BattleCoreAreaSystem:SetCoreAreaShow(bShow)
    log("BattleCoreAreaSystem:SetCoreAreaShow",bShow)
    self.bShowCoreArea = bShow
end

function BattleCoreAreaSystem:IsShowCoreArea()
    --logdebug("BattleCoreAreaSystem:IsShowCoreArea=",self.bShowCoreArea and true or false)
    return self.bShowCoreArea and true or false
end

function BattleCoreAreaSystem:Init()
    return true
end

function BattleCoreAreaSystem:Uninit()
    self.bShowCoreArea = false
end

return BattleCoreAreaSystem

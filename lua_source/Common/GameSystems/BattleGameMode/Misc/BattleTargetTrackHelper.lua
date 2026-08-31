local BattleTargetTrackHelper = {}

BattleTargetTrackHelper.rObjective = nil

function BattleTargetTrackHelper:Init(rObjective)
    self.rObjective = rObjective
end

function BattleTargetTrackHelper:Uninit()
    self.rObjective = nil
end

function BattleTargetTrackHelper:ShowWithTargetTrackActor(nEffectInstanceId, nTargetInstanceId)
    if self.rObjective ~= nil then
        if nEffectInstanceId then
            self.rObjective.nEffectServerInstanceId = nEffectInstanceId            
        end
        self.rObjective.nTargetServerInstanceId = nTargetInstanceId
        self.rObjective.bIsVisible = true
        self.rObjective.Rep()
    end
end

function BattleTargetTrackHelper:ShowTargetTrackPos(nEffectInstanceId, nX, nY, nZ)
    if self.rObjective ~= nil then
        if nEffectInstanceId then
            self.rObjective.nEffectServerInstanceId = nEffectInstanceId            
        end
        self.rObjective.nX = nX
        self.rObjective.nY = nY
        self.rObjective.nZ = nZ
        self.rObjective.bIsVisible = true
        self.rObjective.Rep()
    end
end

function BattleTargetTrackHelper:SetTargetTrackVisible(nEffectInstanceId, bVisible)
    if self.rObjective ~= nil then
        if nEffectInstanceId then
            self.rObjective.nEffectServerInstanceId = nEffectInstanceId            
        end
        self.rObjective.bIsVisible = bVisible 
        self.rObjective.Rep()
    end
end

return BattleTargetTrackHelper

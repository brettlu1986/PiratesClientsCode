local BattleNpcChangeInfoHelper = {}

BattleNpcChangeInfoHelper.rObjective = nil
-- BattleNpcChangeInfoHelper.nWeaponEnabledOverlapId = -1

function BattleNpcChangeInfoHelper:Init(rObjective)
    self.rObjective = rObjective
end

function BattleNpcChangeInfoHelper:Uninit()
    self.rObjective = nil
end

function BattleNpcChangeInfoHelper:SetChangeNpcInteraction(tbNpc, bIsInteraction)
    if self.rObjective ~= nil then
        self.rObjective.nServerInstanceId = tbNpc.nServerInstanceId
        self.rObjective.bIsInteraction = bIsInteraction
        self.rObjective.Rep()
        -- local PropertyWrapperHelper = tbNpc.BattleStatusComponent.PropertyWrapperHelper
        -- if bIsInteraction then
        --     self.nWeaponEnabledOverlapId = PropertyWrapperHelper:Overlap_Override("bWeaponEnabled", false)
        -- elseif self.nWeaponEnabledOverlapId > -1 then
        --     PropertyWrapperHelper:RemoveOverlap("bWeaponEnabled", self.nWeaponEnabledOverlapId)
        --     self.nWeaponEnabledOverlapId = -1
        -- end
    end
end



return BattleNpcChangeInfoHelper
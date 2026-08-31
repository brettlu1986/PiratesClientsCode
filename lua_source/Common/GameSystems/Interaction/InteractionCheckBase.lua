-- InteractionCheckBase
local luaclass = require("luaclass")
local InteractionCheckBase = luaclass("InteractionCheckBase")
local GamePlayerSelfHelper = require("GamePlayerSelfHelper")

InteractionCheckBase.tbNpc = nil 
InteractionCheckBase.nInvalidCollectorCamp = nil 

function InteractionCheckBase:Init(tbNpc)
    self.tbNpc = tbNpc
end 

function InteractionCheckBase:SetInvalidCollectorCamp(nCamp)
    self.nInvalidCollectorCamp = nCamp
end 

function InteractionCheckBase:CheckCanInteraction()
    local tbNpc = self.tbNpc
    if not tbNpc then 
        return false 
    end 

    -- if not (tbNpc.bEnableInteraction or tbNpc.tbNpcTemplateData ~= nil and tbNpc.tbNpcTemplateData.nInteractionType ~= 0) then 
    --     return false
    -- end 
    
    if not tbNpc.bEnableInteraction then 
        return false 
    end 
    
    if self.nInvalidCollectorCamp then 
        local PlayerSelf = GamePlayerSelfHelper:Get()
        if PlayerSelf.BattleCampComponent and PlayerSelf.BattleCampComponent:GetCampType() == self.nInvalidCollectorCamp then
            return false
        end
    end

    return true
end 

return InteractionCheckBase
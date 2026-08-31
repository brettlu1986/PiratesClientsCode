local EffectManager = {}

-- local EventManager = require("EventManager")
-- local ClientEventDef = require("ClientEventDef")
-- local GamePlayerSelfHelper = require("GamePlayerSelfHelper")

function EffectManager:Init()
    -- local pBlurEffect = ('/Game/Resources/Effects/Blueprints/BP_BlurEffect.BP_BlurEffect_C'):load()
    -- if pBlurEffect then 
    --     self.BP_BlurEffect = ClientShell.GetClient(GWorld):GetObjectShell():CreateObject(pBlurEffect)
    --     self.BP_BlurEffect:Init()
    --     self.SetShipFunc = function()
    --         local PlayerSelf = GamePlayerSelfHelper:Get()
    --         if PlayerSelf:IsShip() then
    --             self.BP_BlurEffect:SetPawnActor(PlayerSelf:GetModelActor())
    --         end
    --     end
    --     EventManager:BindEvent(ClientEventDef.EV_PLAYERSELF_READY, self.SetShipFunc)
    -- else
    --     logerror("EffectManager:Init can not load BP_BlurEffect")
    -- end
end

function EffectManager:Uninit()
    -- if self.BP_BlurEffect then
    --     ClientShell.GetClient(GWorld):GetObjectShell():ReleaseObject(self.BP_BlurEffect)
    --     EventManager:UnBindEvent(ClientEventDef.EV_PLAYERSELF_READY, self.SetShipFunc)
    --     self.SetShipFunc = nil
    --     self.BP_BlurEffect = nil
    -- end
end

return EffectManager

local luaclass = require("luaclass")
local HumanMovementStateBase = dynamic_require("HumanMovementStateBase")
local HumanMovementStateCrouch = luaclass("HumanMovementStateCrouch", HumanMovementStateBase)
-- local GameObjectTypeDef = require("GameObjectTypeDef")
-- local GlobalVariableSystem = dynamic_require("GlobalVariableSystem")

function HumanMovementStateCrouch:Active()
    self:ChangeCapsule()
    self:BlendCameraWithTime()
    -- local GamePlayer = self.Owner.Owner
    -- local pUEActor = GamePlayer.pUEActor
    -- if GamePlayer.ObjectType == GameObjectTypeDef.PlayerSelf then
    --     if GlobalVariableSystem:IsClient() then
    --         pUEActor.CharacterMovement:SetUseBoxHit(true)
    --     end
    -- end 
end

function HumanMovementStateCrouch:UnActive()
    -- local GamePlayer = self.Owner.Owner
    -- local pUEActor = GamePlayer.pUEActor
    -- if GamePlayer.ObjectType == GameObjectTypeDef.PlayerSelf then
    --     if GlobalVariableSystem:IsClient() then
    --         pUEActor.CharacterMovement:SetUseBoxHit(false)
    --     end
    -- end 
end

return HumanMovementStateCrouch
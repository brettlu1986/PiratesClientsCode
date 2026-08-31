local luaclass = require("luaclass")
local GameCorePacketProcessorAction = require("GameCorePacketProcessorAction")
local GameCorePacketProcessorCrouch = luaclass("GameCorePacketProcessorCrouch", GameCorePacketProcessorAction)

local Proto                         = require("GameCoreClientProtoNames")
local HumanMovementStateType  = require("HumanMovementStateType")

-- luacheck: push ignore
local function LOG(...)
    log("CJ->GameCorePacketProcessorCrouch:", ...)
end
-- luacheck: pop


function GameCorePacketProcessorCrouch:DoAction(tbPacket)
    local tbGameObject = self.tbAgent:GetGameObject()
    if tbGameObject:IsHuman() then
        if not self:CanChangeMovementState() then
            LOG("Do Action crouch failed.")
            self:ReportActionResult(Proto.ActionType.Crouch, 1)
            return
        end
        tbGameObject.HumanMovementStateComponent:SetMovementState(HumanMovementStateType.Crouch_State)
        self:ReportActionResult(Proto.ActionType.Crouch, 0)
    end
end


return GameCorePacketProcessorCrouch
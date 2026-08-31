local luaclass = require("luaclass")
local GameCorePacketProcessorAction = require("GameCorePacketProcessorAction")
local GameCorePacketProcessorStand = luaclass("GameCorePacketProcessorStand", GameCorePacketProcessorAction)

local Proto                         = require("GameCoreClientProtoNames")
local HumanMovementStateType  = require("HumanMovementStateType")

-- luacheck: push ignore
local function LOG(...)
    log("CJ->GameCorePacketProcessorStand:", ...)
end
-- luacheck: pop


function GameCorePacketProcessorStand:DoAction(tbPacket)
    local tbGameObject = self.tbAgent:GetGameObject()
    if tbGameObject:IsHuman() then
        if not self:CanChangeMovementState() then
            LOG("Do Action stand failed: 1.")
            self:ReportActionResult(Proto.ActionType.Stand, 1)
            return
        end
        tbGameObject.HumanMovementStateComponent:SetMovementState(HumanMovementStateType.UpRight_State)
        self:ReportActionResult(Proto.ActionType.Stand, 0)
    end
end


return GameCorePacketProcessorStand
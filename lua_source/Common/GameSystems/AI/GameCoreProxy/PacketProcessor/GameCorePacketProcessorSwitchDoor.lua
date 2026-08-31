local luaclass = require("luaclass")
local GameCorePacketProcessorAction = require("GameCorePacketProcessorAction")
local GameCorePacketProcessorSwitchDoor = luaclass("GameCorePacketProcessorSwitchDoor", GameCorePacketProcessorAction)

local Proto                         = require("GameCoreClientProtoNames")
local GameObjectSystem  = dynamic_require("GameObjectSystem")

-- luacheck: push ignore
local function LOG(...)
    log("CJ->GameCorePacketProcessorSwitchDoor:", ...)
end
-- luacheck: pop


function GameCorePacketProcessorSwitchDoor:DoAction(tbPacket)
    local nAction = tbPacket.action
    local tbAgent = self.tbAgent
    local tbGameObject = tbAgent:GetGameObject()
    if tbAgent.nDoorAction == nAction then
        local tbGameDoor = GameObjectSystem:FindByInstanceId(tbAgent.nDoorInstanceId)
        if tbGameDoor and tbGameDoor.pUEActor and not tbGameDoor:IsDead() then
            local pUEActor = tbGameDoor.pUEActor
            local nCurState = enumtoint(pUEActor:GetCurState())
            local nState = 0
            if nCurState == 0 then -- closed
                local pDoorTransform = pUEActor:GetTransform()
                local pSelfLocation  = tbGameObject:GetLocation()
                local pOutLocation   = KismetMathLibrary.TransformLocation(pDoorTransform, pUEActor.OutPoint)
                local nDistanceOut   = ExtendBlueprintFunctions.GetVectorToVectorDistance(pSelfLocation, pOutLocation)
                local pInLocation    = KismetMathLibrary.TransformLocation(pDoorTransform, pUEActor.InPoint)
                local nDistanceIn    = ExtendBlueprintFunctions.GetVectorToVectorDistance(pSelfLocation, pInLocation)
                if nDistanceOut < nDistanceIn then
                    nState = 1
                else
                    nState = 2
                end
            end
            pUEActor:SwitchDoor(nState, tbGameObject:GetServerInstanceId())
            self:ReportActionResult(Proto.ActionType.SwitchDoor, 0)
        else
            self:ReportActionResult(Proto.ActionType.SwitchDoor, 2)
        end
    else
        self:ReportActionResult(Proto.ActionType.SwitchDoor, 1)
    end
end


return GameCorePacketProcessorSwitchDoor
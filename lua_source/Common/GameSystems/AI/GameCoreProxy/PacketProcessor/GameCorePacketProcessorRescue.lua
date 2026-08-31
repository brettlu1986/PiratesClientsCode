local luaclass = require("luaclass")
local GameCorePacketProcessorAction = require("GameCorePacketProcessorAction")
local GameCorePacketProcessorRescue = luaclass("GameCorePacketProcessorRescue", GameCorePacketProcessorAction)

local Proto                         = require("GameCoreClientProtoNames")
local GameObjectSystem  = dynamic_require("GameObjectSystem")

-- luacheck: push ignore
local function LOG(...)
    log("CJ->GameCorePacketProcessorRescue:", ...)
end
-- luacheck: pop


function GameCorePacketProcessorRescue:DoAction(tbPacket)
    local tbGameObject = self.tbAgent:GetGameObject()
    local nServerInstanceId = tbPacket.rescue_id
    local tbRescueObject = GameObjectSystem:FindByInstanceId(nServerInstanceId)
    if tbRescueObject then
        if not tbRescueObject:GetCurrentPropertyComponent():GetIsDying() then
            LOG("not dying")
            self:ReportActionResult(Proto.ActionType.Rescue, 1)
        elseif tbRescueObject.BattleDyingComponent:IsBeingRescued() then
            LOG("is being rescue by other")
            self:ReportActionResult(Proto.ActionType.Rescue, 2)
        else
            local BattleDyingComponent = tbRescueObject.BattleDyingComponent
            for tbTeammate,v in pairs(BattleDyingComponent.tbNearbyTeammates) do
                if tbTeammate == tbGameObject then
                    tbRescueObject.BattleDyingComponent:Rescue(tbGameObject)
                    self:ReportActionResult(Proto.ActionType.Rescue, 0)
                    return
                end
            end
            LOG("too far to rescue")
            self:ReportActionResult(Proto.ActionType.Rescue, 3)
        end
    end
end


return GameCorePacketProcessorRescue
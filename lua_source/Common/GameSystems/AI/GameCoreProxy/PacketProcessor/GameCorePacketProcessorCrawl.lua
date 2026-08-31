local luaclass = require("luaclass")
local GameCorePacketProcessorAction = require("GameCorePacketProcessorAction")
local GameCorePacketProcessorCrawl = luaclass("GameCorePacketProcessorCrawl", GameCorePacketProcessorAction)

local Proto                         = require("GameCoreClientProtoNames")
local HumanMovementStateType  = require("HumanMovementStateType")

-- luacheck: push ignore
local function LOG(...)
    log("CJ->GameCorePacketProcessorCrawl:", ...)
end
-- luacheck: pop


function GameCorePacketProcessorCrawl:DoAction(tbPacket)
    local tbGameObject = self.tbAgent:GetGameObject()
    if tbGameObject:IsHuman() then
        if not self:CanChangeMovementState() then
            LOG("Do Action crawl failed.")
            self:ReportActionResult(Proto.ActionType.Crawl, 1)
            return
        end
        tbGameObject.HumanMovementStateComponent:SetMovementState(HumanMovementStateType.Crawl_State)
        self:ReportActionResult(Proto.ActionType.Crawl, 0)
    end
end


return GameCorePacketProcessorCrawl
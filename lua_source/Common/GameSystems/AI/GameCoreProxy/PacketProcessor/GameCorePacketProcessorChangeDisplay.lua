local luaclass = require("luaclass")
local GameCorePacketProcessorAction = require("GameCorePacketProcessorAction")
local GameCorePacketProcessorChangeDisplay = luaclass("GameCorePacketProcessorChangeDisplay", GameCorePacketProcessorAction)

local Proto  = require("GameCoreClientProtoNames")
local BattleLandSystem = dynamic_require("BattleLandSystem")
local GameCoreActionActorType = require("GameCoreActionActorType")

GameCorePacketProcessorChangeDisplay.ActorType = GameCoreActionActorType.All

-- luacheck: push ignore
local function LOG(...)
    log("CJ->GameCorePacketProcessorChangeDisplay:", ...)
end
-- luacheck: pop


function GameCorePacketProcessorChangeDisplay:DoAction(tbPacket)
    local tbPlayer = self.tbAgent:GetGameObject()
    local nUniqueId = tbPlayer.nUniqueId
    if BattleLandSystem:GetTargetRegionTypeByLocation(tbPlayer) ~= nil then
        BattleLandSystem:OnStartChangeDisplay(nUniqueId)
        self:ReportActionResult(Proto.ActionType.ChangeDisplay, 0)
        LOG("Action_ChangeDisplay", tbPlayer:GetServerInstanceId(), 0)
    else
        self:ReportActionResult(Proto.ActionType.ChangeDisplay, 1)
        LOG("Action_ChangeDisplay", tbPlayer:GetServerInstanceId(), 1)
    end
end


return GameCorePacketProcessorChangeDisplay
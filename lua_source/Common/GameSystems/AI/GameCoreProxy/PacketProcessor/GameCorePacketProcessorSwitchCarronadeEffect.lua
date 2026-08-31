local luaclass = require("luaclass")
local GameCorePacketProcessorAction = require("GameCorePacketProcessorAction")
local GameCorePacketProcessorSwitchCarronadeEffect = luaclass("GameCorePacketProcessorSwitchCarronadeEffect", GameCorePacketProcessorAction)

local Proto                         = require("GameCoreClientProtoNames")
local CarronadeEffectDef  = require("CarronadeEffectDef")

-- luacheck: push ignore
local function LOG(...)
    log("CJ->GameCorePacketProcessorSwitchCarronadeEffect:", ...)
end
-- luacheck: pop


function GameCorePacketProcessorSwitchCarronadeEffect:DoAction(tbPacket)
    local nNewEffectType = tbPacket.effect_type
    local tbGameObject = self.tbAgent:GetGameObject()
    if tbGameObject:IsShip() and nNewEffectType > 0 and nNewEffectType <= CarronadeEffectDef.Max then
        self.tbAgent.nCarronadeEffectType = nNewEffectType
        self:ReportActionResult(Proto.ActionType.SwitchCarronadeEffect, 0)
    else
        self:ReportActionResult(Proto.ActionType.SwitchCarronadeEffect, 1)
    end
end


return GameCorePacketProcessorSwitchCarronadeEffect
local luaclass = require("luaclass")
local GameCorePacketProcessorBase = require("GameCorePacketProcessorBase")
local GameCorePacketProcessorAction = luaclass("GameCorePacketProcessorAction", GameCorePacketProcessorBase)
local Proto = require("GameCoreClientProtoNames")
local BattleItemSystemHelper = require("BattleItemSystemHelper")
local HumanWeaponMisc = require("HumanWeaponMisc")
local GameCoreActionActorType = require("GameCoreActionActorType")
local HumanMovementStateType = require("HumanMovementStateType")
local ShipFiringOperationDef = require("ShipFiringOperationDef")
local BattleShipWeaponSystem = dynamic_require("BattleShipWeaponSystem")
local GlobalVariableSystem = dynamic_require("GlobalVariableSystem")
local HumanWeaponType = HumanWeaponMisc.Type
-- luacheck: push ignore
local function LOG(...)
    log("CJ->GameCorePacketProcessorAction:", ...)
end
-- luacheck: pop

GameCorePacketProcessorAction.tbAgent = nil
GameCorePacketProcessorAction.ActorType = GameCoreActionActorType.HumanAndShip

local tbActionResultPacket = { }

function GameCorePacketProcessorAction:DoAction(tbPacket)

end


function GameCorePacketProcessorAction:CanChangeMovementState()
    local tbGameObject = self.tbAgent:GetGameObject()
    local HumanMovementStateComponent = tbGameObject.HumanMovementStateComponent
    local nAgentId = self.tbAgent.nID
    if not tbGameObject:IsHuman() then
        LOG("Can not change movement state: not human. AgentId = ", nAgentId)
        return false
    end
    if not HumanMovementStateComponent then
        LOG("Can not change movement state: HumanMovementStateComponent is nil. AgentId = ", nAgentId)
        return false
    end
    if HumanMovementStateComponent:GetCurrentState() == HumanMovementStateType.Jumping_SpeelWall then
        LOG("Can not change movement state: Jumping wall. AgentId = ", nAgentId)
        return false
    end
    return true
end

function GameCorePacketProcessorAction:IsFalling()
    local tbGameObject = self.tbAgent:GetGameObject()
    return tbGameObject:IsHuman() and tbGameObject.pUEActor.CharacterMovement.MovementMode == EMovementMode.MOVE_Falling
end

function GameCorePacketProcessorAction:StopRun()
    local tbGameObject = self.tbAgent:GetGameObject()
    if tbGameObject:IsHuman() then
        tbGameObject.HumanMovementStateComponent:SetRun(false)
    end
end

function GameCorePacketProcessorAction:GetValidSlot(nCategory, nSlotId)
    local ItemOperationHelper = BattleItemSystemHelper:GetItemOperationHelper(nCategory)
    if ItemOperationHelper:IsSlotIndexValid(nSlotId) then
        return nSlotId
    end
    return 0
end

function GameCorePacketProcessorAction:IngorePackets(tbPackets, nTime)
    local tbAgent = self.tbAgent
    for i,v in ipairs(tbPackets) do
        tbAgent:AddIngorePacket(v, nTime)
    end
end

function GameCorePacketProcessorAction:StopAttack()
    local tbGameObject = self.tbAgent:GetGameObject()
    if tbGameObject:IsHuman() then
        local WeaponComponent = tbGameObject.HumanWeaponComponent
        local tbCurrentWeapon = WeaponComponent:GetCurrentWeapon(true)
        if tbCurrentWeapon and tbCurrentWeapon:IsType(HumanWeaponType.MELEE) then
            tbCurrentWeapon:StopCheatAttack()
        end
    else
        BattleShipWeaponSystem:Fire(tbGameObject, ShipFiringOperationDef.END)
    end
end

function GameCorePacketProcessorAction:ReportActionResult(ActionType, nResult)
    local nServerInstanceId = self.tbAgent:GetGameObject().nServerInstanceId
    if GlobalVariableSystem.bAIGameCoreTrainingMode then
        local tbPacket = tbActionResultPacket
        tbPacket.id = nServerInstanceId
        tbPacket.action = ActionType
        tbPacket.result = nResult
        self.tbGameCoreProxyClient:Send(Proto.c2s_actionValid, tbPacket)
    end
    if nResult ~= 0 then
        LOG("action result fail:", nResult, ActionType, nServerInstanceId)
    end
end

function GameCorePacketProcessorAction:Process(tbPacket)
    local tbAgent = self.tbGameCoreProxyClient:GetAgent(tbPacket.id)
    if not tbAgent then
        error("game core ai:recieve invalid action packet:", tbPacket.id)
        return
    end
    if tbAgent:IsPacketIgnored(self.szPacketId) then
        LOG("ignored packet ",tbAgent:GetGameObject().szName, self.szPacketId, tbPacket.id)
        return
    end
    -- rts()
    if tbAgent:CanDoAction(self.ActorType) then
        self.tbAgent = tbAgent
        self:DoAction(tbPacket)
    else
        LOG("can not do action ",tbAgent:GetGameObject().szName, tbPacket.id, self.ActorType)
    end
    -- rte("GameCorePacketProcessorAction:Process " .. self.szPacketId)
end

return GameCorePacketProcessorAction
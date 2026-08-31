local luaclass = require("luaclass")
local GameCorePacketProcessorAction = require("GameCorePacketProcessorAction")
local GameCorePacketProcessorFire = luaclass("GameCorePacketProcessorFire", GameCorePacketProcessorAction)

local Proto                         = require("GameCoreClientProtoNames")
local GameObjectSystem              = dynamic_require("GameObjectSystem")
local Timer                         = require("Timer")
local HumanWeaponMisc               = require("HumanWeaponMisc")
local BattleShipWeaponSystem        = dynamic_require("BattleShipWeaponSystem")

local HumanWeaponType = HumanWeaponMisc.Type

local nSequenceAttackInterval = 0.3
local SEQUENCE_ATTACK_TIMER = "sequence_attack_timer"
local GetActorsInSectorRange = ExtendBlueprintFunctions.GetActorsInSectorRange

-- luacheck: push ignore
local function LOG(...)
    log("CJ->GameCorePacketProcessorFire:", ...)
end
-- luacheck: pop

function GameCorePacketProcessorFire:IsValidShipFireRange()
    return true
end

function GameCorePacketProcessorFire:DoAction(tbPacket)
    self:StopRun()
    local tbAgent = self.tbAgent
    local tbGameObject = tbAgent:GetGameObject()
    local pAIController = tbAgent.pAIController
    if tbGameObject and tbGameObject:IsAlive() then
        if tbGameObject:IsHuman() then
            local WeaponComponent = tbGameObject.HumanWeaponComponent
            local tbWeaponInst = WeaponComponent:GetCurrentWeapon()
            if tbWeaponInst and tbWeaponInst:IsType(HumanWeaponType.THROW) then
                LOG("throw ")
            elseif tbWeaponInst and tbWeaponInst:IsType(HumanWeaponType.GUN) then
                if tbWeaponInst:IsReloading() then
                    self:ReportActionResult(Proto.ActionType.Fire, 1)
                    return
                end
                local tbProperty  = tbWeaponInst:GetProperty()
                local pHitActor, pHitComponent = pAIController:GetHitActor(tbProperty.nEffectiveRange * 100, 2)
                local tbHitPlayer = nil
                if pHitActor then
                    tbHitPlayer = GameObjectSystem:FindByUEActor(pHitActor)
                end
                if tbHitPlayer then
                    local szHitName = KismetSystemLibrary.GetObjectName(pHitComponent)
                    WeaponComponent:CheatAttack(tbHitPlayer.pUEActor, szHitName)
                else
                    WeaponComponent:CheatAttack()
                end
            else
                -- empty hand
                local nAttackRange = 100
                local nAttackAngle = 60
                if tbWeaponInst then
                    -- with melee
                    local tbProperty  = tbWeaponInst:GetProperty()
                    nAttackRange = tbProperty.nEffectiveRange * 100
                    nAttackAngle = 120
                end
                local pAgentUEActor = tbGameObject.pUEActor
                local tbOutActors = GetActorsInSectorRange(GWorld, Pawn, pAgentUEActor:K2_GetActorLocation(),
                pAgentUEActor:K2_GetActorRotation(), nAttackRange, nAttackAngle)
                local pHitActor = tbOutActors[1]
                local tbHitPlayer = nil
                if pHitActor then
                    tbHitPlayer = GameObjectSystem:FindByUEActor(pHitActor)
                end
                if tbHitPlayer then
                    WeaponComponent:CheatAttack(tbHitPlayer.pUEActor, "Body")
                else
                    WeaponComponent:CheatAttack()
                end
                Timer.StartOwnerTimer(tbAgent, SEQUENCE_ATTACK_TIMER, function()
                    self:StopAttack()
                end, nSequenceAttackInterval)
            end
            self:ReportActionResult(Proto.ActionType.Fire, 0)
        else
            local ActiveWeaponItem = BattleShipWeaponSystem:GetActiveWeaponItem(tbGameObject)
            if ActiveWeaponItem then
                if self:IsValidShipFireRange() then
                    ActiveWeaponItem:SetReplacedViewerActor(pAIController)
                    BattleShipWeaponSystem:Fire(tbGameObject)
                    self:ReportActionResult(Proto.ActionType.Fire, 0)
                else
                    self:ReportActionResult(Proto.ActionType.Fire, 3)
                end
            end
        end
    else
        self:ReportActionResult(Proto.ActionType.Fire, 2)
    end
end


return GameCorePacketProcessorFire
local luaclass = require("luaclass")
local GameCorePacketProcessorAction = require("GameCorePacketProcessorAction")
local GameCorePacketProcessorJumpWall = luaclass("GameCorePacketProcessorJumpWall", GameCorePacketProcessorAction)

local Proto                         = require("GameCoreClientProtoNames")
local HumanMovementStateType  = require("HumanMovementStateType")
local HumanJumpTypeDef              = require("HumanJumpTypeDef")
local PropName = require("PropName")
local Timer = require("Timer")

local GlobalVariableSystem = dynamic_require("GlobalVariableSystem")

-- luacheck: push ignore
local function LOG(...)
    log("CJ->GameCorePacketProcessorJumpWall:", ...)
end
-- luacheck: pop

local TempTable = {}
local function CopyVector(Dest, From)
    Dest.X = From.X
    Dest.Y = From.Y
    Dest.Z = From.Z
end

local JUMP_WALL_TIMER= "jump_wall_timer"
local nJumpWallInterval = 2.0

function GameCorePacketProcessorJumpWall:DoAction(tbPacket)
    local tbGameObject  = self.tbAgent:GetGameObject()
    if tbGameObject:IsHuman() then
        local HumanMovementStateComponent = tbGameObject.HumanMovementStateComponent
        if not self:CanChangeMovementState() or not HumanMovementStateComponent.bEnableMove then
            LOG("Do Action jumpwall failed: 1.")
            self:ReportActionResult(Proto.ActionType.JumpWall, 1)
            return
        end
        local fClimbRate = tbGameObject.HumanBattlePropertyComponent:GetProp(PropName.nClimbCoefficient)
        if fClimbRate <= 0 then
            LOG("Do Action jumpwall failed: 4.")
            self:ReportActionResult(Proto.ActionType.JumpWall, 4)
            return
        end
        local nMovementState = HumanMovementStateComponent.rMovementState
        if nMovementState == HumanMovementStateType.Crouch_State or
        nMovementState == HumanMovementStateType.Crawl_State then
            LOG("Do Action jumpwall failed: 2.")
            tbGameObject.HumanMovementStateComponent:SetMovementState(HumanMovementStateType.UpRight_State)
            self:ReportActionResult(Proto.ActionType.JumpWall, 2)
            return
        end
        local tbDestructible = HumanMovementStateComponent:GetDestructibleObject()
        local nDestructibleInstanceId = 0
        if tbDestructible then
            nDestructibleInstanceId = tbDestructible:GetServerInstanceId()
            tbDestructible.pUEActor:SetCollisionEnabled(false)
        end
        local pUEActor = tbGameObject.pUEActor

        if GlobalVariableSystem.bUseNewSpeel then
            local eWallType, pRotator, pSpeelPos, pTargetPos, pExpectStartPos = pUEActor:GetSpeelInfo()
            local WallType = enumtoint(eWallType)
            
            if WallType ~= HumanJumpTypeDef.None then
                local tbSpeelPos       = {X = pSpeelPos.X,       Y = pSpeelPos.Y,       Z = pSpeelPos.Z}
                local tbTargetPos      = {X = pTargetPos.X,      Y = pTargetPos.Y,      Z = pTargetPos.Z}
                local tbExpectStartPos = {X = pExpectStartPos.X, Y = pExpectStartPos.Y, Z = pExpectStartPos.Z}
            
                HumanMovementStateComponent:RequestSpeelNew(WallType, nDestructibleInstanceId, tbSpeelPos, tbTargetPos, tbExpectStartPos, math.floor(pRotator.Yaw))
                self:ReportActionResult(Proto.ActionType.JumpWall, 0)
            else
                if tbDestructible then
                    tbDestructible.pUEActor:SetCollisionEnabled(true)
                end

                LOG("Do Action jumpwall failed: 3.")
                self:ReportActionResult(Proto.ActionType.JumpWall, 3)
            end

            destroyUserData(pSpeelPos)
            destroyUserData(pTargetPos)
            destroyUserData(pExpectStartPos)
            destroyUserData(pRotator)
        else
            local eWallType, WallLocation, Rotator = pUEActor:GetJumpType()
            local nWallType = enumtoint(eWallType)
            if nWallType ~= HumanJumpTypeDef.None then
                CopyVector(TempTable, WallLocation)
                tbGameObject.HumanMovementStateComponent:RequestSpeel(nWallType, nDestructibleInstanceId, TempTable, math.floor(Rotator.Yaw))
                destroyUserData(WallLocation)
                destroyUserData(Rotator)
                --local bRet, WallLocation, _ = pUEActor:GetWallLocation(nWallType)
                Timer.StartOwnerTimer(self.tbAgent, JUMP_WALL_TIMER, function()
                    -- if bRet then
                    --     pUEActor:K2_SetActorLocation(WallLocation)
                    -- end
                    tbGameObject.HumanMovementStateComponent:RequestSpeel(HumanJumpTypeDef.None)
                end, nJumpWallInterval)
                self:ReportActionResult(Proto.ActionType.JumpWall, 0)
            else
                if tbDestructible then
                    tbDestructible.pUEActor:SetCollisionEnabled(true)
                end
                destroyUserData(WallLocation)
                destroyUserData(Rotator)
                LOG("Do Action jumpwall failed: 3.")
                self:ReportActionResult(Proto.ActionType.JumpWall, 3)
            end
        end
    end
end


return GameCorePacketProcessorJumpWall
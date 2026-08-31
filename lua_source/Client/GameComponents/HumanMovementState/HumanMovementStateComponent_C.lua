local luaclass = require("luaclass")
local HumanMovementStateComponent = require("HumanMovementStateComponent")
local ClientEventDef = require("ClientEventDef")
local NetworkManager = dynamic_require("NetworkManager")
local ProtoDC = require("DungeonCommonProtoNames")
local HumanMovementStateComponent_C = luaclass("HumanMovementStateComponent_C", HumanMovementStateComponent)
local HumanMovementStateType = require("HumanMovementStateType")
local GlobalVariableSystem = dynamic_require("GlobalVariableSystem")

local TempTable = {}
local function CopyVector(Dest, From)
    Dest.X = From.X
    Dest.Y = From.Y
    Dest.Z = From.Z
end
local function OnHumanWeaponOnEquipid(self, nServerInstanceId)
    if self.Owner:GetServerInstanceId() ~= nServerInstanceId then
        return
    end

    local nWeaponSpeedFactor = self.Owner.HumanWeaponComponent:GetWeaponSpeedFactor()

    if self.nWeaponSpeedFactor == nWeaponSpeedFactor then
        return
    end
    self.nWeaponSpeedFactor = nWeaponSpeedFactor
    self:OnSpeedChanged()
end



function HumanMovementStateComponent_C:OnActorCreated(pUEActor)
    HumanMovementStateComponent_C.super.OnActorCreated(self, pUEActor)
    self.EventHelper:RegisterEvent(ClientEventDef.EV_HUMAN_WEAPON_ON_EQUIPED_CLIENT, self, OnHumanWeaponOnEquipid)
    self.EventHelper:RegisterEvent(ClientEventDef.EV_HUMAN_WEAPON_ON_UNEQUIPED_CLIENT, self, OnHumanWeaponOnEquipid)    
end 

function HumanMovementStateComponent_C:RequestChangeMovement(nNewState, bForce)
    if not self.StateHelper.bSelf then  
        return 
    end 

    if bForce or self.StateHelper:CanChangeState(nNewState) then  
        self.StateHelper:ChangeState(nNewState)
        if not GlobalVariableSystem:IsServerLogic() then 
            local c2d_ChangeMovementState =
            {
                movement_state = nNewState
            }
            NetworkManager:GetRPCNetworkProxy():SendToServer(ProtoDC.c2d_ChangeMovementState, c2d_ChangeMovementState)
        end
    else
        if nNewState == HumanMovementStateType.Vehicle then
            self.EventHelper:FireEvent(ClientEventDef.EV_ON_REQUEST_VEHICLE_FAILED)
        end
    end 
end

function HumanMovementStateComponent_C:RequestSpeel(nJumpType, nDestructibleInstanceId, tbWallPosition, Yaw)
    if not self.StateHelper:CanChangeState(HumanMovementStateType.Jumping_SpeelWall) then  
        return 
    end
    Yaw = math.floor(Yaw)
    CopyVector(TempTable, tbWallPosition)

    local tbHumanRootMotionJump = {
        jump_type = nJumpType,
        destructible_id = nDestructibleInstanceId,
        wall_position = TempTable,
        yaw = Yaw,
    } 

    if not GlobalVariableSystem:IsServerLogic() then 
        NetworkManager:GetRPCNetworkProxy():SendToServer(ProtoDC.c2d_RootMotionJump, tbHumanRootMotionJump)
    end

    self.OnRootMotionJump:Fire(tbHumanRootMotionJump)    
end

function HumanMovementStateComponent_C:RequestSpeelNew(nJumpType, nDestructibleInstanceId, tbSpeelPos, tbTargetPos, tbExpectStartPos, Yaw)
    if not self.StateHelper:CanChangeState(HumanMovementStateType.Jumping_SpeelWall) then  
        return 
    end

    Yaw = math.floor(Yaw)

    local tbHumanRootMotionJump =
        {
            jump_type = nJumpType,
            destructible_id = nDestructibleInstanceId,
            yaw = Yaw,            
            speel_position = tbSpeelPos,
            target_position = tbTargetPos,
            expect_start_position = tbExpectStartPos
        }

    if not GlobalVariableSystem:IsServerLogic() then 
        
        NetworkManager:GetRPCNetworkProxy():SendToServer(ProtoDC.c2d_RootMotionJumpNew, tbHumanRootMotionJump)
    end

    self.OnRootMotionJumpNew:Fire(tbHumanRootMotionJump)  
end

return HumanMovementStateComponent_C 
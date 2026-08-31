-----------------------------------------------------
--File Name    : GuideActionRotateShipActor.lua
--Description  : 船向指定位置旋转，主要针对船的yaw用
-----------------------------------------------------
local luaclass                      = require("luaclass")
local GuideActionBase               = require("GuideActionBase")
local GuideActionRotateShipActor    = luaclass("GuideActionRotateShipActor", GuideActionBase)

local GamePlayerSelfHelper      = require("GamePlayerSelfHelper")

local ROT_INTERVAL = 0.1
local ERROR_OFFSET = 5

local function RotateToTarget(self)
    local tbTemplate = self.tbTemplate
    local nP1 = tonumber(tbTemplate.tbParam[1])
    local nP2 = tonumber(tbTemplate.tbParam[2])
    local nP3 = tonumber(tbTemplate.tbParam[3])
    local pTargetLoc = Vector{X = nP1, Y = nP2, Z = nP3}

    local PlayerSelf = GamePlayerSelfHelper:Get()
    if PlayerSelf:IsShip() then

        local ShipActorLoc = PlayerSelf.pUEActor:K2_GetActorLocation()
        local ShipActorRot = PlayerSelf.pUEActor:K2_GetActorRotation()
        local TargetRotation = KismetMathLibrary.FindLookAtRotation(ShipActorLoc, pTargetLoc)

        local nOffsetYaw = TargetRotation.Yaw - ShipActorRot.Yaw
        local nSteerDir = nOffsetYaw > 0 and 1 or -1
        PlayerSelf.pUEActor.ShipMovementComponent:SteerRight(nSteerDir)

        --logerror("the offset yaw is 1:", nOffsetYaw, ShipActorRot.Yaw)
        self.TimerHelper:NewTimerMethod(self, 
        function() 
            ShipActorRot = PlayerSelf.pUEActor:K2_GetActorRotation()
            --logerror("the offset yaw is 2:", nOffsetYaw, ShipActorRot.Yaw, math.abs(ShipActorRot.Yaw - TargetRotation.Yaw))
            if math.abs(ShipActorRot.Yaw - TargetRotation.Yaw) < ERROR_OFFSET then  
                --logerror("stop")
                PlayerSelf.pUEActor.ShipMovementComponent:SteerRight(0)
                self.TimerHelper:ClearAllTimer()
                -- self:ForceEndCurrentStep()
            end
        end, ROT_INTERVAL, true)
    end

end

function GuideActionRotateShipActor:DoAction(tbTemplate)
    GuideActionRotateShipActor.super.DoAction(self, tbTemplate)
    RotateToTarget(self)
end

return GuideActionRotateShipActor

local luaclass = require("luaclass")
local GameComponentBaseClass = require("GameComponentBase")
local HeadlessMoveComponent = luaclass("HeadlessMoveComponent", GameComponentBaseClass)
local StringUtil = require("StringUtil")
local SelfTimerHelperClass = require("SelfTimerHelper")
local ControlModeSystem = require("ControlModeSystem")
local DCProto = require("DungeonCommonProtoNames")
local NetworkManager = dynamic_require("NetworkManager")

local MOVE_TICK_SECOND = 1

HeadlessMoveComponent.TimerHelper = nil
HeadlessMoveComponent.nMoveCount = 0
HeadlessMoveComponent.ShipMoveCount = 0

local CppGear = {
    [1] = EShipGear.FullSpeed,
    [2] = EShipGear.LowSpeed,
    [3] = EShipGear.Stopped,
    [4] = EShipGear.Reverse,
}

local function HumanMove(self, pUEActor)
    self.nMoveCount = self.nMoveCount + 1
    -- 测试使用
    if self.nMoveCount > 200 then
       self.nMoveCount = 0
    end

    local nX =  math.random(1,10);
    local nY =  math.random(1,10);

    if self.nMoveCount > 100 then
       nX = nX - 10
       nY = nY - 10
    end
    
    pUEActor:MoveForward(nX)
    pUEActor:MoveRight(nY)

    -- local pPlayerInputComponent = pUEActor.PlayerInputComponent
    -- if not pPlayerInputComponent then
    --     return
    -- end
    -- local InputYaw = math.random(-90, 90)
    -- pUEActor:AddControllerYawInput(InputYaw)
    -- pPlayerInputComponent:SetContinuousRun(true)
end

local function ShipMove(self, pUEActor)
    local ShipMovementComponent = pUEActor.ShipMovementComponent
    if ShipMovementComponent then       
        if self.ShipMoveCount == 0 or self.ShipMoveCount == 20 then
            local gear = math.random(1, 4)
            ShipMovementComponent:SetBasicGear(CppGear[gear])
            --logwarning("headlessmove ShipMove SetBasicGear.", gear)
        elseif self.ShipMoveCount == 30 then
            local steer = math.random(-1, 1)
            ShipMovementComponent:SteerRight(steer)
            --logwarning("headlessmove ShipMove SteerRight.", steer)
            self.ShipMoveCount = 0
        elseif self.ShipMoveCount == 5 then
            --logwarning("headlessmove ShipMove SteerRight 0.")
            ShipMovementComponent:SteerRight(0)
        end
    end
    self.ShipMoveCount = self.ShipMoveCount + 1
end

local function TransportState(self, pUEActor)
    local rand = math.random(1, 100)
    if rand <= 10 then
        --logwarning("headlessmove TransportState.")
        NetworkManager:GetRPCNetworkProxy():SendToServer(DCProto.c2d_JumpFromTransporter)
    end
end

local function OnTimerFunc(self)
    local tbGamePlayerSelf = self:GetOwner()
    local pUEActor = tbGamePlayerSelf.pUEActor
    if pUEActor == nil then
        logwarning("Client simulates moving failed. pUEActor nil.")
        return
    end

    if (ControlModeSystem.bTransportState == true) then
        TransportState(self, pUEActor)
        return
    end

    if tbGamePlayerSelf:IsShip() then
        ShipMove(self, pUEActor)    
    elseif tbGamePlayerSelf:IsHuman() then
        HumanMove(self, pUEActor)
    end
    
end

local function SimulateMove(self)
    if self.TimerHelper == nil then
        self.TimerHelper = SelfTimerHelperClass()
    end
    self.TimerHelper:NewTimerMethod(self, OnTimerFunc, MOVE_TICK_SECOND, true)
end

function HeadlessMoveComponent:OnCreate(...)
    HeadlessMoveComponent.super.OnCreate(self, ...)
    self.TimerHelper = SelfTimerHelperClass()

    local szCmdLineStr = KismetSystemLibrary.GetCommandLine()
    local tbCmdArgs = StringUtil.Split(szCmdLineStr, ' ')
    for i=1,#tbCmdArgs do
        if tbCmdArgs[i] == "-headlessmoving" then
            log("Client simulates moving...")
            SimulateMove(self)
            break
        end
    end
end

function HeadlessMoveComponent:OnDestroy(...)
    HeadlessMoveComponent.super.OnDestroy(self, ...)
    if self.TimerHelper~= nil then
        self.TimerHelper:ClearAllTimer()
        self.TimerHelper = nil
    end
end

return HeadlessMoveComponent

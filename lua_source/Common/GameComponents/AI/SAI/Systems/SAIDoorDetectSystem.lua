
local luaclass = require("luaclass")
local SAISystemBase = require("SAISystemBase")
local SAIDoorDetectSystem = luaclass("SAIDoorDetectSystem", SAISystemBase)
local GameObjectSystem = dynamic_require("GameObjectSystem")
local SelfEventHelperClass = require("SelfEventHelper")

SAIDoorDetectSystem.nInterval = 1
SAIDoorDetectSystem.pDoorDetectComp = nil
SAIDoorDetectSystem.SelfEventHelper = nil
SAIDoorDetectSystem.tbNearByDoorInstanceId = -1
-- luacheck: push ignore
local function LOG(...)
    log("CJ->SAIDoorDetectSystem:", ...)
end
-- luacheck: pop



function SAIDoorDetectSystem:OnConfig(tbConfig)
    local tbDetectConfig = tbConfig.DoorDetect
    if tbDetectConfig then
        self.bEnabled  = true
        self.nInterval = tbDetectConfig.nInterval
        LOG("door detect start enabled：", self.nInterval)
    else
        self.bEnabled  = false
        LOG("door detect disabled")
    end
end


function SAIDoorDetectSystem:OnInit()
    self.bEnabled  = false
end

local function OpenDoor(self, tbGameDoor)
    local pUEActor = tbGameDoor.pUEActor
    local nCurState = enumtoint(pUEActor:GetCurState())
    if nCurState == 0 then -- closed
        local nState = 0
        local tbGameObject   = self.tbOwner
        local pDoorTransform = pUEActor:GetTransform()
        local pSelfLocation  = tbGameObject:GetLocation()
        local pOutLocation   = KismetMathLibrary.TransformLocation(pDoorTransform, pUEActor.OutPoint)
        local nDistanceOut   = ExtendBlueprintFunctions.GetVectorToVectorDistance(pSelfLocation, pOutLocation)
        local pInLocation    = KismetMathLibrary.TransformLocation(pDoorTransform, pUEActor.InPoint)
        local nDistanceIn    = ExtendBlueprintFunctions.GetVectorToVectorDistance(pSelfLocation, pInLocation)
        if nDistanceOut < nDistanceIn then
            nState = 1
        else
            nState = 2
        end
        pUEActor:SwitchDoor(nState, tbGameObject:GetServerInstanceId())
        LOG("open door:",tbGameObject.szName, nState)
    end
end

local function OnEnterDoor(self, nDoorInstanceId)
    if nDoorInstanceId > 0 then
        local tbGameDoor = GameObjectSystem:FindByInstanceId(nDoorInstanceId)
        if tbGameDoor and tbGameDoor.pUEActor and not tbGameDoor:IsDead() then
            self.tbNearByDoorInstanceId = nDoorInstanceId
            OpenDoor(self, tbGameDoor)
            return
        end
    end

    LOG("enter door ", nDoorInstanceId)
end

local function OnLeaveDoor(self, nInstanceId)
    LOG("leave door ", nInstanceId)
    self.tbNearByDoorInstanceId = -1
end

local function OnHumanBlocked(self, nInstanceId)
    local nDoorInstanceId = self.tbNearByDoorInstanceId
    if nDoorInstanceId > 0 then
        local tbGameDoor = GameObjectSystem:FindByInstanceId(nDoorInstanceId)
        if tbGameDoor and tbGameDoor.pUEActor and not tbGameDoor:IsDead() then
            local pUEActor = tbGameDoor.pUEActor
            local nCurState = enumtoint(pUEActor:GetCurState())
            local tbGameObject   = self.tbOwner
            if nCurState == 0 then -- closed
                OpenDoor(self, tbGameDoor)
            else
                pUEActor:SwitchDoor(0, tbGameObject:GetServerInstanceId())
                LOG("closd door:", tbGameObject.szName)
            end
            return
        end
    end
end

function SAIDoorDetectSystem:OnStart()
    local tbGameObject  = self.tbOwner
    local pAIController = tbGameObject.SAIComponent:GetAIController()
    local pDoorDetectComp = pAIController.DoorDetectComponent
    self.tbNearByDoorInstanceId = -1
    if pDoorDetectComp then
        local SelfEventHelper = SelfEventHelperClass()
        self.SelfEventHelper = SelfEventHelper
        self.pDoorDetectComp = pDoorDetectComp
        pDoorDetectComp:SetEnable(true)
        pDoorDetectComp:SetComponentTickInterval(self.nInterval)
        SelfEventHelper:RegisterCppDelegate(pDoorDetectComp.EnterDoor, self, OnEnterDoor)
        SelfEventHelper:RegisterCppDelegate(pDoorDetectComp.LeaveDoor, self, OnLeaveDoor)
        SelfEventHelper:RegisterCppDelegate(pAIController.NotifyHumanBlocked, self, OnHumanBlocked)
    end
end

function SAIDoorDetectSystem:OnStop()
    LOG("stop door detect")
    if self.SelfEventHelper then
        self.SelfEventHelper:UnregisterAll()
    end
    if self.pDoorDetectComp then
        self.pDoorDetectComp:SetEnable(false)
    end
end

function SAIDoorDetectSystem:OnUninit()

end

return SAIDoorDetectSystem

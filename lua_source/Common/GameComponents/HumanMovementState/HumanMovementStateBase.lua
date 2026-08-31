local luaclass          = require("luaclass")
local HumanMovementStateBase= luaclass("HumanMovementStateBase")

local GameObjectTypeDef = require("GameObjectTypeDef")
local GlobalVariableSystem = dynamic_require("GlobalVariableSystem")
local HumanCapsuleDataTable = require("HumanCapsuleDataTable")
local HumanMovementStateType = require("HumanMovementStateType")
local TeamWatchServerHelper = require("TeamWatchServerHelper")

HumanMovementStateBase.Owner = nil
HumanMovementStateBase.tbParams = nil
HumanMovementStateBase.bRevertToLastState = true
HumanMovementStateBase.nNextState = 0
HumanMovementStateBase.GamePlayer = 0
HumanMovementStateBase.pOwnerActor = 0
HumanMovementStateBase.bSelf = false
HumanMovementStateBase.bServer = false
HumanMovementStateBase.bStantalone = false
HumanMovementStateBase.bClient = false

local OffsetVector = Vector()

function HumanMovementStateBase:Init(tbOwner)
    self.Owner = tbOwner
    self.GamePlayer = tbOwner.Owner
    self.pOwnerActor = self.GamePlayer.pUEActor
    if self.GamePlayer.ObjectType == GameObjectTypeDef.PlayerSelf then
        self.bSelf = true
    end
    self.bServer = GlobalVariableSystem:IsServerLogic()
    self.bStantalone = GlobalVariableSystem:IsStandaloneServer()
    self.bClient = GlobalVariableSystem:IsClient()
end

function HumanMovementStateBase:UnInit(tbOwner)
    self.Owner = tbOwner
end

function HumanMovementStateBase:Active(tbParams)
end

function HumanMovementStateBase:UnActive(tbParams)
end

function HumanMovementStateBase:OnCompleted()
    self.Owner:OnStateCompleted()
end

function HumanMovementStateBase:BlendCameraWithTime()
    local nLastState = self.Owner:GetLastState()
    TeamWatchServerHelper.NotifyViewersMovementState(self.GamePlayer, nLastState, self.nStateType)
end

function HumanMovementStateBase:OnChangeCapsule(OffsetZ, nCapsuleHalfHeight, nLastState)

    OffsetVector.Z = nCapsuleHalfHeight * -1

    -- if self.bSelf then 
        local pLocation = self.pOwnerActor:K2_GetActorLocation()
        pLocation.Z = pLocation.Z + OffsetZ
        self.pOwnerActor:K2_SetActorLocation(pLocation, true, true)
        self.pOwnerActor.Mesh:K2_SetRelativeLocation(OffsetVector)
        destroyUserData(pLocation)
    -- end
    self.pOwnerActor.BaseTranslationOffset = OffsetVector
end

function HumanMovementStateBase:ChangeCapsule()
    local nTemplateId = self.GamePlayer:GetHumanTemplateId()
    local CapsuleData = HumanCapsuleDataTable:GetTemplate(nTemplateId, self.nStateType)
    
    if not CapsuleData then
        return
    end
    -- pUEActor.CharacterMovement.CrouchedHalfHeight = 65
    local nCapsuleRadius = CapsuleData.nCapsuleRadius
    local nCapsuleHalfHeight = CapsuleData.nCapsuleHalfHeight
    if nCapsuleHalfHeight < nCapsuleRadius then  
        nCapsuleHalfHeight = nCapsuleRadius
    end 
    

    -- self.pOwnerActor.CapsuleComponent:SetCapsuleRadius(nCapsuleRadius)
    local nLastState = self.Owner.StateHelper.nLastMovementState
    
    local LastCapsuleData = HumanCapsuleDataTable:GetTemplate(nTemplateId, nLastState)
    if not LastCapsuleData then 
        if self.nStateType ~= HumanMovementStateType.UpRight_State and nLastState ~= HumanMovementStateType.None then 
            LastCapsuleData = HumanCapsuleDataTable:GetTemplate(nTemplateId, HumanMovementStateType.UpRight_State) 
        end
    end 
    
    if not LastCapsuleData then 
        self.pOwnerActor.CapsuleComponent:SetCapsuleSize(nCapsuleRadius, nCapsuleHalfHeight)
        return 
    end

    local OffsetZ = nCapsuleHalfHeight - LastCapsuleData.nCapsuleHalfHeight

    -- 趴下时先设置碰撞体 否则其他人看着会往下掉
    if OffsetZ < 0 then 
        self.pOwnerActor.CapsuleComponent:SetCapsuleSize(nCapsuleRadius, nCapsuleHalfHeight)
    end

    self:OnChangeCapsule(OffsetZ, nCapsuleHalfHeight, nLastState)

    -- 站起来时后设置碰撞体,否则在两个物体中间时会掉下去.
    if OffsetZ >= 0 then 
        self.pOwnerActor.CapsuleComponent:SetCapsuleSize(nCapsuleRadius, nCapsuleHalfHeight)
    end
end 

return HumanMovementStateBase
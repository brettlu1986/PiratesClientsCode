local luaclass = require("luaclass")
local HumanMovementStateBase = require("HumanMovementStateBase")
local HumanMovementStateBase_C = luaclass("HumanMovementStateBase_C", HumanMovementStateBase)
local CameraGameHelper = require("CameraGameHelper")
local ClientEventDef = require("ClientEventDef")
local GameObjectTypeDef = require("GameObjectTypeDef")
local EventManager = require("EventManager")
-- local BattleItemDataTable = require("BattleItemDataTable")
local CommonEventDef = require("CommonEventDef")
local HumanMovementStateType = require("HumanMovementStateType")
local GameCameraSystem = require("GameCameraSystem")
local GameCameraModeGroupDef = require("GameCameraModeGroupDef")
local HumanCameraDataTable          = require("HumanCameraDataTable")
local HumanWeaponCameraTimeDataTable = require("HumanWeaponCameraTimeDataTable")

function HumanMovementStateBase_C:BlendCameraWithTime()
    local nLastState = self.Owner:GetLastState()
    if self.GamePlayer.ObjectType == GameObjectTypeDef.PlayerSelf  then
        if CameraGameHelper.IsNeedMovementBlend(nLastState, self.nStateType) then
            local nWeaponID = self.GamePlayer.HumanWeaponComponent:GetCurrentWeaponTemplateId()
            nWeaponID = nWeaponID and nWeaponID or 0
            local nBlendTime = HumanWeaponCameraTimeDataTable:GetMovementCameraTime(nWeaponID, nLastState, self.nStateType)
            local Offset = HumanCameraDataTable:GetMovementCameraOffset(self.nStateType)
            local nStatePitchMax, nStatePitchMin = HumanCameraDataTable:GetMovementCameraPitchLimit(self.nStateType)

            -- logdebug("the movement value is:: ", nBlendTime, Offset.X, Offset.Y, Offset.Z, self.GamePlayer.nServerInstanceId, debug.traceback())
            EventManager:OnFireEvent(ClientEventDef.EV_MOVEMENT_CAMERE_OFFSET, Offset, nBlendTime, true, nStatePitchMax, nStatePitchMin)
        end
    end
    HumanMovementStateBase_C.super.BlendCameraWithTime(self)

end 

local function IsWatchBattleMode()
    local nGroupDef = GameCameraModeGroupDef
    return GameCameraSystem:IsCameraLogicActive(nGroupDef.ViewTeammateShip) 
            or GameCameraSystem:IsCameraLogicActive(nGroupDef.ViewTeammateHuman)
end

local function IsNewHumanAim()
    local nGroupDef = GameCameraModeGroupDef
    return GameCameraSystem:IsCameraLogicActive(nGroupDef.HumanAiming) 
end

function HumanMovementStateBase_C:OnChangeCapsule(OffsetZ, nCapsuleHalfHeight, nLastState)
    if self.bSelf then  
        if not IsNewHumanAim() then
            if self.nStateType ~= HumanMovementStateType.Swimming then
                local GameCameraManager = GameplayStatics.GetPlayerCameraManager(GWorld, 0)
                if nLastState == HumanMovementStateType.Crawl_State then 
                    EventManager:OnFireEvent(CommonEventDef.EV_DEACTIVE_CRAWL_CAMERA, self.GamePlayer)
                end

                if self.nStateType == HumanMovementStateType.Crawl_State and GameCameraManager ~= nil then   
                    GameCameraManager:ForceToResetFreeViewRotation()
                end
            
                if not IsWatchBattleMode() and GameCameraManager ~= nil and GameCameraManager.GetPlayerCameraActor then
                    local CameraActor = GameCameraManager:GetPlayerCameraActor()
                    CameraActor:K2_DetachFromActor(EDetachmentRule.KeepRelative, EDetachmentRule.KeepRelative, EDetachmentRule.KeepRelative)
                    local pLocation = CameraActor:K2_GetActorLocation()
                    local nLocZ = self.nStateType == HumanMovementStateType.UpRight_State and 0 or pLocation.Z - OffsetZ
                    CameraActor:K2_SetActorLocation(Vector{X=pLocation.X, Y=pLocation.Y, Z=nLocZ }, true, true)
                    CameraActor:K2_AttachToActor(self.pOwnerActor, "", EAttachmentRule.KeepRelative, EAttachmentRule.KeepRelative, EAttachmentRule.KeepRelative, false)
                end
            end
        end
    end

    HumanMovementStateBase_C.super.OnChangeCapsule(self, OffsetZ, nCapsuleHalfHeight, nLastState)
    -- if self.bSelf then 
    --     ExtendBlueprintFunctions.ChangePlayerMeshTranslationOffset(self.pOwnerActor.CharacterMovement, OffsetZ * -1)    
    -- end
end

return HumanMovementStateBase_C
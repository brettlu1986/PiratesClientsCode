local luaclass = require("luaclass")
local GameHorse = require("GameHorse")
local GameHorse_C = luaclass("GameHorse_C", GameHorse)
local GameObjectTypeDef = require("GameObjectTypeDef")
local CommonEventDef = require("CommonEventDef")
local Timer = require("Timer")
-- local SaveGameDef = require("SaveGameDef")
local SettingSystemNew = require("SettingSystemNew")
local SettingClassType = require("SettingClassType")
local ProgressBarTableNew = require("ProgressBarTableNew")

local ClientEventDef = require("ClientEventDef")
local VehicleDataTable = require("VehicleDataTable")
local HumanWeaponStateDef = require("HumanWeaponStateDef")
local AnimationResDataTable = require("AnimationResDataTableNew")

local DELAY_USE_BONE = "DelayUseBone"

local DIE_ANIM_TIMER = "DIE_ANIM_TIMER"
local DIE_STAND_ANIM_KEY = "HorseDieStand"
local DIE_WALK_ANIM_KEY = "HorseDieWalk"
local DIE_RUN_ANIM_KEY = "HorseDieRun"
local DIE_ANIM_DEFAULT_SECTION = "Default"

-- local SCARED_TIMER = "SCARED_TIMER"
local SCARED_ANIMATION_RES = "AnimMontage'/Game/Game/CharacterEx/Roles/Vehicle/AM_SpanishHorse_Brake.AM_SpanishHorse_Brake'"

GameHorse_C.nDriverInstanceId = nil 

-- luacheck: push ignore
local function  LOG(self, ...)
    log("[Vehicle] [GameHorse_C]", self:GetServerInstanceId(), ...)
end
-- luacheck: pop

local function HorseScared(self)
    local pAnimInstance = self.pUEActor.Mesh:GetAnimInstance()
    if pAnimInstance:Montage_IsPlaying(nil) then
        return 
    end
    local pAnimMontage = SCARED_ANIMATION_RES:load()
    local _nTime = pAnimInstance:Montage_Play(pAnimMontage, 1.0, EMontagePlayReturnType.MontageLength, 0.0, false)
    -- Timer.StartOwnerTimer(self, SCARED_TIMER, nil, _nTime)

    self.EventHelper:FireEvent(ClientEventDef.EV_ON_HORSE_SCARED, self:GetServerInstanceId())
end

local function OnPorgressEvent(self, nInstanceId, bStart, nProgressBarId)
    if self.nDriverInstanceId ~= nInstanceId then  
        return 
    end

    Timer.StopOwnerAllTimer(self, true)
    if bStart then 
        local nUseParentBoneMode = ProgressBarTableNew:GetTemplate(nProgressBarId).nUseParentBoneMode
        self.pUEActor.bRightUseParentBone = (1 & nUseParentBoneMode) > 0
        self.pUEActor.bLeftUseParentBone = (1 << 1 & nUseParentBoneMode) > 0
        -- self.pUEActor.bUseParentBone = false
    else  
        Timer.StartOwnerTimer(self, DELAY_USE_BONE, function()
            self.pUEActor.bRightUseParentBone = true
            self.pUEActor.bLeftUseParentBone = true
            -- self.pUEActor.bUseParentBone = true
        end, 1)
    end
end

-- 被周围人开枪吓到
local function OnHumanWeaponStateChanged(self, nNewState, tbPlayer)
    if not self:IsAlive() then
        return
    end
    if nNewState ~= HumanWeaponStateDef.ATTACKING then
        return 
    end
    if not tbPlayer or not tbPlayer.pUEActor then
        return
    end

    local nDistance = self.pUEActor:GetDistanceTo(tbPlayer.pUEActor) / 100
    local tbVehicleData = VehicleDataTable:GetTemplate(self:GetTemplateId())
    if nDistance > tbVehicleData.nBattleStimulationDistance then
        return
    end

    -- HorseScared(self)
end

-- 被周围的马被吓到吓到
local function OnOtherHorseScared(self, nVehicleId)
    if self:GetServerInstanceId() == nVehicleId then
        return 
    end
    
    HorseScared(self)
end

local function OnBindEvent(self, EventHelper, pUEActor)
    EventHelper:RegisterEvent(ClientEventDef.EV_HUMAN_WEAPON_STATE_CHANGED_CLIENT, self, OnHumanWeaponStateChanged)
    EventHelper:RegisterEvent(ClientEventDef.EV_ON_HORSE_SCARED, self, OnOtherHorseScared)
end

function GameHorse_C:OnActorCreated(pUEActor)
    GameHorse_C.super.OnActorCreated(self, pUEActor)
    OnBindEvent(self, self.EventHelper, pUEActor)
end

function GameHorse_C:UnbindUEActor()
    Timer.StopOwnerAllTimer(self, true)
    GameHorse_C.super.UnbindUEActor(self)
end

function GameHorse_C:AttachToVehicle(tbPlayer, bAttach, bForceAttach)
    local tbSettingOperationMode = SettingSystemNew:GetInstance(SettingClassType.Setting_OperationMode)
    local nOperationMode = tbSettingOperationMode:GetVehicleOperationMode()
    if nOperationMode ~= tbSettingOperationMode.ModeDef.WithJoystick and tbPlayer.ObjectType == GameObjectTypeDef.PlayerSelf and tbPlayer.pUEActor then 
        local PlayerInputComponent = tbPlayer.pUEActor.PlayerInputComponent
        PlayerInputComponent.UseGesture = not bAttach
        PlayerInputComponent:ResetMoveDelta()
    end

    if bAttach then
        if not self.nDriverInstanceId then
            self.EventHelper:RegisterEvent(CommonEventDef.EV_PROGRESS_CHANGED, self, OnPorgressEvent)
        end
        self.nDriverInstanceId = tbPlayer:GetServerInstanceId()
    else  
        self.EventHelper:UnregisterAll()
        self.nDriverInstanceId = nil 
    end

    GameHorse_C.super.AttachToVehicle(self, tbPlayer, bAttach, bForceAttach)
end 

function GameHorse_C:ClearDriver(tbPlayer)
    self.nDriverInstanceId = nil 
    if tbPlayer.ObjectType == GameObjectTypeDef.PlayerSelf then 
        local PlayerInputComponent = tbPlayer.pUEActor.PlayerInputComponent
        PlayerInputComponent.UseGesture = true
        PlayerInputComponent:ResetMoveDelta()
        self.EventHelper:UnregisterAll()
    end
    GameHorse_C.super.ClearDriver(self, tbPlayer)
end 

function GameHorse_C:SetDriver(tbPlayer, bAttach, bForce)
    local bSuccess = GameHorse_C.super.SetDriver(self, tbPlayer, bAttach)
    if not bSuccess then
        return false
    end

    local pUEActor = self.pUEActor
    pUEActor.CharacterMovement:DiscardPendingMove()

    if bAttach then
        pUEActor.bUseControllerRotationYaw = true 
        pUEActor.bUseParentBone = true

        if not self.nDriverInstanceId then
            self.EventHelper:RegisterEvent(CommonEventDef.EV_PROGRESS_CHANGED, self, OnPorgressEvent)
        end
        self.nDriverInstanceId = tbPlayer:GetServerInstanceId()
    else
        pUEActor.bUseControllerRotationYaw = false
        pUEActor.bUseParentBone = false

        self.EventHelper:UnregisterEvent(CommonEventDef.EV_PROGRESS_CHANGED)
        self.nDriverInstanceId = nil 
    end
    return true
end

function GameHorse_C:OnDead()
    GameHorse_C.super.OnDead(self)
    local tbVehicleData = VehicleDataTable:GetTemplate(self:GetTemplateId())
    local szAnimKey = DIE_STAND_ANIM_KEY
    local nSpeed = self.pUEActor.Speed / 100
    if nSpeed > tbVehicleData.nRunSpeed then
        szAnimKey = DIE_RUN_ANIM_KEY
    elseif nSpeed > tbVehicleData.nWalkSpeed then
        szAnimKey = DIE_WALK_ANIM_KEY
    end

    local tbParams = {}
    tbParams.nTemplateId = tbVehicleData.nVehicleId
    tbParams.szAnimKey = szAnimKey

    local tbAnimTemplate = AnimationResDataTable:GetTemplate(tbParams)
    local pAnimInstance = self.pUEActor.Mesh:GetAnimInstance()
    local pMontage = tbAnimTemplate.szAnimation:load()
    pAnimInstance:Montage_Play(pMontage, 1.0, EMontagePlayReturnType.MontageLength, 0.0, false)
    local _, nTime = ExtendBlueprintFunctions.GetMontageSectionStartEndTime(pMontage, DIE_ANIM_DEFAULT_SECTION)
    Timer.StartOwnerTimer(self, DIE_ANIM_TIMER, function()
        self.pUEActor.Mesh.bPauseAnims = true
    end, nTime)
end

return GameHorse_C
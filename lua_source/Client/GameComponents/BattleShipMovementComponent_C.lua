-----------------------------------------------------
--File Name    : BattleShipMovementComponent_C.lua
--Author       : Song Fuhao
--Create Time  : 2020-05-21
--Description  : 
-----------------------------------------------------
local luaclass = require("luaclass")
local BattleShipMovementComponent = require("BattleShipMovementComponent")
local BattleShipMovementComponent_C = luaclass("BattleShipMovementComponent_C", BattleShipMovementComponent)

local SoundManager              = require("SoundManager")
local ShipDataTable             = require("ShipDataTable")
local ShipMovementDef           = require("ShipMovementDef")
local ResourceManager           = require("ResourceManager")
local GameObjectTypeDef         = require("GameObjectTypeDef")
local ShipMovingSoundDataTable  = require("ShipMovingSoundDataTable")
local GlobalVariableSystem      = dynamic_require("GlobalVariableSystem")

local ShipGearDef = ShipMovementDef.ShipGearDef
local ShipPostureDef = ShipMovementDef.ShipPostureDef

-- 前四个与PostureDef对应，方便逻辑处理
local SOUND_TYPE = {
    FULL_SAIL   = 0, -- 满帆
    HALF_SAIL   = 1, -- 半帆
    REFF        = 2, -- 收帆
    SINK        = 3, -- 沉没
    STOP        = 4, -- 停船
    STEERING    = 5  -- 转舵
}

local SC_SHIP_RISE_SAIL = 600014
local SC_SHIP_DOWN_SAIL = 600015

BattleShipMovementComponent_C.tbAsyncLoadHandles= nil
BattleShipMovementComponent_C.tbSoundCompMap    = nil
BattleShipMovementComponent_C.tbSoundTemplates  = nil
BattleShipMovementComponent_C.nSoundType        = nil
BattleShipMovementComponent_C.nGearValue        = ShipGearDef.Stopped
BattleShipMovementComponent_C.nPosture          = ShipPostureDef.FullSail
BattleShipMovementComponent_C.nSteering         = 0

local function LOG(...)
    log("[BattleShipMovementComponent_C]", ...)
end

local function LOG_ERROR(...)
    logerror("[BattleShipMovementComponent_C]", ...)
end

local function IsSoundValid(pSoundComp)
    return pSoundComp and isvalidhandle(pSoundComp)
end

local function FadeInSound(self, nSoundType)
    LOG("FadeInSound", nSoundType)
    local pSoundComp = self.tbSoundCompMap[nSoundType]
    if IsSoundValid(pSoundComp) then
        local tbTemplate = self.tbSoundTemplates[nSoundType]
        pSoundComp:FadeIn(tbTemplate.nFadeInDuration, 1, 0, EAudioFaderCurve.Linear)
        return true
    end
    return false
end

local function FadeOutSound(self, nSoundType)
    LOG("FadeOutSound", nSoundType)
    local pSoundComp = self.tbSoundCompMap[nSoundType]
    if IsSoundValid(pSoundComp) then
        local tbTemplate = self.tbSoundTemplates[nSoundType]
        pSoundComp:FadeOut(tbTemplate.nFadeOutDuration, 0, EAudioFaderCurve.Linear)
        return true
    end
    return false
end

local function SwitchSteeringSound(self)
    if self.nSteering == 0 then
        FadeOutSound(self, SOUND_TYPE.STEERING)
    else
        FadeInSound(self, SOUND_TYPE.STEERING)
    end
end

local function SwitchMovingSound(self)
    local nSoundType = SOUND_TYPE.STOP
    if self.nGearValue ~= ShipGearDef.Stopped then
        nSoundType = self.nPosture
    end

    if self.nSoundType ~= nSoundType then
        FadeOutSound(self, self.nSoundType)
        if FadeInSound(self, nSoundType) then
            self.nSoundType = nSoundType
        end
    end
end

-- 异步加载之后，再真正的SpawnSound
local function SpawnSoundIntenal(self, nSoundType, pSoundRes)
    local pSoundComp = GameplayStatics.CreateSound2D(GWorld, pSoundRes, 1, 1, 0, nil, false, false)
    if pSoundComp == nil then
        LOG("Spawn sound failed, nSoundType =", nSoundType)
        return
    end
    self.tbSoundCompMap[nSoundType] = pSoundComp

    if nSoundType == SOUND_TYPE.STEERING then
        SwitchSteeringSound(self)
    else
        SwitchMovingSound(self)
    end
end

local function SpawnAllSound(self)
    local tbShipTemplate = ShipDataTable:GetTemplate(self.nShipTemplateId)
    if tbShipTemplate == nil then
        LOG_ERROR("SpawnAllSound failed, ship template is nil, nShipTemplateId =", self.nShipTemplateId)
        return
    end
    local nShipCategroy = tbShipTemplate.nCategory
    LOG("SpawnAllSound nShipCategroy =", nShipCategroy)

    self.tbSoundTemplates = ShipMovingSoundDataTable:GetSoundResMap(nShipCategroy)
    self.tbSoundCompMap = {}

    if self.tbSoundTemplates then
        self.tbAsyncLoadHandles = {}
        for nSoundType, tbTemplate in pairs(self.tbSoundTemplates) do
            local nHandle = ResourceManager:LoadAsync(tbTemplate.szSoundPath, function(szAssetName, pSoundRes, _nHandle)
                LOG("Sound loaded. nSoundType, szAssetName =", nSoundType, szAssetName)
                self.tbAsyncLoadHandles[nSoundType] = nil
                SpawnSoundIntenal(self, nSoundType, pSoundRes)
            end, false)
            if self.tbSoundCompMap[nSoundType] == nil then
                self.tbAsyncLoadHandles[nSoundType] = nHandle
            end
        end
    else
        LOG_ERROR("SpawnAllSound failed, cannot find sound templates.")
    end
end

local function DestroyAllSound(self)
    LOG("DestroyAllSound")
    if self.tbSoundCompMap then
        for nSoundType, pSoundComp in pairs(self.tbSoundCompMap) do
            if IsSoundValid(pSoundComp) then
                LOG("Destroy Sound", nSoundType)
                pSoundComp:K2_DestroyComponent(pSoundComp)
            end
        end
        self.tbSoundCompMap = nil
    end
    if self.tbAsyncLoadHandles then
        for nSoundType, nHandle in pairs(self.tbAsyncLoadHandles) do
            LOG("Cancel sound load", nSoundType)
            ResourceManager:CancelLoadAsync(nHandle)
            self.tbAsyncLoadHandles = nil
        end
    end
end

local function OnGearValueChanged(self, pGearValue)
    local nGearValue = enumtoint(pGearValue)
    LOG("OnGearValueChanged nGearValue =", nGearValue)

    if self.nGearValue ~= nGearValue then
        self.nGearValue = nGearValue
        SwitchMovingSound(self)
    end
end

local function OnShipInputDataChanged(self, pInputData)
    local nPosture = enumtoint(pInputData.Posture)
    local nSteering = pInputData.SteerScale
    LOG("OnShipInputDataChanged nPosture, nSteering =", nPosture, nSteering)

    if nPosture ~= self.nPosture then
        self.nPosture = nPosture
        SwitchMovingSound(self)

        local nSoundId = (nPosture > self.nPosture) and SC_SHIP_RISE_SAIL or SC_SHIP_DOWN_SAIL
        SoundManager:PlaySoundEffect(nSoundId)
    end
    if nSteering ~= self.nSteering then
        self.nSteering = nSteering
        SwitchSteeringSound(self)
    end
end

function BattleShipMovementComponent_C:UninitSoundLogic()
    LOG("UninitSoundLogic")
    local DelegateComponent = self.Owner.DelegateComponent
    DelegateComponent.OnGearValueChanged:Unbind(OnGearValueChanged, self)
    DelegateComponent.OnShipInputDataChanged:Unbind(OnShipInputDataChanged, self)
    DelegateComponent.OnCharacterPostDead:Unbind(self.UninitSoundLogic, self)
    DestroyAllSound(self)
end

function BattleShipMovementComponent_C:InitSoundLogic()
    LOG("InitSoundLogic")
    SpawnAllSound(self)
    local DelegateComponent = self.Owner.DelegateComponent
    DelegateComponent.OnGearValueChanged:Bind(OnGearValueChanged, self)
    DelegateComponent.OnShipInputDataChanged:Bind(OnShipInputDataChanged, self)
    DelegateComponent.OnCharacterPostDead:Bind(self.UninitSoundLogic, self)
end

function BattleShipMovementComponent_C:OnActorCreated(...)
    BattleShipMovementComponent_C.super.OnActorCreated(self, ...)

    if (self.Owner:GetObjectType() == GameObjectTypeDef.PlayerSelf) and GlobalVariableSystem.bShipSoundEnabled then
        self:InitSoundLogic()
    end
end

function BattleShipMovementComponent_C:OnActorDestroyed(...)
    if (self.Owner:GetObjectType() == GameObjectTypeDef.PlayerSelf) and GlobalVariableSystem.bShipSoundEnabled then
        self:UninitSoundLogic()
    end

    BattleShipMovementComponent_C.super.OnActorCreated(self, ...)
end

return BattleShipMovementComponent_C
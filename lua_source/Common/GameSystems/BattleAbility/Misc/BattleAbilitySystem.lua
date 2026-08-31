-----------------------------------------------------
--File Name    : BattleAbilitySystem.lua
--Author       : Song Fuhao
--Create Time  : 2020-03-20
--Description  : 用于管理全局的BattleAbility相关逻辑
-----------------------------------------------------
local BattleAbilitySystem = {}

-- require
local L10N = require("L10N")
local StringUtil = require("StringUtil")
local CampSystem = require("CampSystem")
local SkillDataTable = require("SkillDataTable")
local BattleAbilityDefine = require("BattleAbilityDefine")
local BattleBuffDataTable = require("BattleBuffDataTable")
local AbilityParamParseUtils = require("AbilityParamParseUtils")
local SummonObjectDataTable = require("SummonObjectDataTable")
local AbilityParticleEffectResDataTable = require("AbilityParticleEffectResDataTable")
-- local AbilityMaterialEffectResDataTable = require("AbilityMaterialEffectResDataTable")
local GameObjectSystem = dynamic_require("GameObjectSystem")
local AbilityPostProcessEffectResDataTable = require("AbilityPostProcessEffectResDataTable")
local ResourceManager = require("ResourceManager")

-- 静态函数
local fnGetAllActorsOfClass     = GameplayStatics.GetAllActorsOfClass
local fnGetActorsInSectorRange  = ExtendBlueprintFunctions.GetActorsInSectorRange
local fnGetPawnsInCircleRange   = ExtendBlueprintFunctions.GetPawnsInCircleRange
local fnGetPawnsInRectRange     = ExtendBlueprintFunctions.GetPawnsInRectRange

-- 常量定义
local RANGE_TYPE                = BattleAbilityDefine.RangeType
local TARGET_TYPE               = BattleAbilityDefine.TargetType
local INVALID_ID                = -1
local ABILITY_DESC_PARAM_PATTERN= "{((.-)%.(.-),?(%d-))}"
local ACTION_GROUP_PATTERN      = "{(.-)}"
local ACTION_ADD_BUFF           = "AddBuff"
local ACTION_SUMMON_OBJECT      = "SummonObject"
local ACTION_SPLIT_CHAR         = ";"
local DEFAULT_TRANSFORM         = Transform()
local DEFAULT_ROTATOR           = Rotator()

BattleAbilitySystem.tbAllAsyncHandles = nil
BattleAbilitySystem.tbAllLensEffects = nil

local GetActionParamValue       = nil
local function GetBuffParamValue(nBuffId, nLevel, szMainKey, szSubKey)
    local tbTemplate = BattleBuffDataTable:GetTemplate(nBuffId)
    return GetActionParamValue(tbTemplate.szActionList, nLevel, szMainKey, szSubKey)
end

local function GetSummonObjectParamValue(nSummonObjectId, nLevel, szMainKey, szSubKey)
    local tbTemplate = SummonObjectDataTable:GetTemplate(nSummonObjectId)
    if tbTemplate[szSubKey] then
        return tbTemplate[szSubKey]
    end
    return GetBuffParamValue(tbTemplate.StatusId, nLevel, szMainKey, szSubKey)
end

GetActionParamValue = function(szActionList, nLevel, szMainKey, szSubKey)
    local nRetValue = nil
    local tbActionList = StringUtil.Split(szActionList, ACTION_SPLIT_CHAR)
    for _,szActionInfo in ipairs(tbActionList) do
        local szActionName, tbParams = AbilityParamParseUtils.GetParamListWithLevel(szActionInfo, nLevel)
        if szActionName == szMainKey then
            nRetValue = tbParams[szSubKey]
        elseif szActionName == ACTION_ADD_BUFF then
            nRetValue = GetBuffParamValue(tbParams.Value, nLevel, szMainKey, szSubKey)
        elseif szActionName == ACTION_SUMMON_OBJECT then
            -- SummonObject的Action有属性重载
            nRetValue = tbParams[szSubKey]
            if nRetValue then
                return nRetValue
            end
            nRetValue = GetSummonObjectParamValue(tbParams.Id, nLevel, szMainKey, szSubKey)
        end
        if nRetValue then
            return nRetValue
        end
    end
    return nRetValue
end

local function GetSkillParamValue(nSkillId, nLevel, szMainKey, szSubKey)
    local nRetValue = nil
    local tbTemplate = SkillDataTable:GetTemplate(nSkillId)
    local iteratorFunc = string.gmatch(tbTemplate.szActionGroupList, ACTION_GROUP_PATTERN       )
    for szActionList in iteratorFunc do
        nRetValue = GetActionParamValue(szActionList, nLevel, szMainKey, szSubKey)
        if nRetValue then
            return nRetValue
        end
    end
    return nRetValue
end

local function GetAbilityDesc(fnParamGetter, l10nDesc, nId, nLevel)
    local tbNames = {}
    local tbArgs = {}
    local iteratorFunc = string.gmatch(L10N:ToString(l10nDesc), ABILITY_DESC_PARAM_PATTERN)
    for szMatch, szMainKey, szSubKey, szRatio in iteratorFunc do
        local nParam = fnParamGetter(nId, nLevel, szMainKey, szSubKey)
        local nRatio = StringUtil.ToNumber(szRatio, 1)
        table.insert(tbNames, szMatch)
        table.insert(tbArgs, nParam and (math.abs(nParam) * nRatio) or "None")
    end
    return L10N:FormatByName(l10nDesc, tbNames, tbArgs)
end

local function GetAbilityEffectComponent(tbCharacter)
    local pUEActor = tbCharacter and tbCharacter.pUEActor
    local pAbilityEffectComponent = pUEActor and pUEActor.AbilityEffectComponent
    return pAbilityEffectComponent
end


local function AsyncLoadWithCharacter(self, tbCharacter, szRes, fnCallback)
    local nCharacterInstanceId = tbCharacter and tbCharacter:GetServerInstanceId()
    if not nCharacterInstanceId then
        logerror("PlayParticleEffect failed, nCharacterInstanceId is nil")
        return INVALID_ID
    end

    local nAsyncHandle = ResourceManager:LoadAsync(szRes, function(_, pRes, nHandle)
        -- 因为资源是异步加载，所以加载完可能Character和pUEActor就不在了
        local tbCharacterEx = GameObjectSystem:FindByInstanceId(nCharacterInstanceId)
        local pCharacter = tbCharacterEx and tbCharacterEx.pUEActor
        local pAbilityEffectComponent = pCharacter and pCharacter.AbilityEffectComponent
        if pAbilityEffectComponent then
            self.tbAllAsyncHandles[nHandle] = fnCallback(tbCharacterEx, pCharacter, pAbilityEffectComponent, pRes)
        end
    end, false)
    self.tbAllAsyncHandles[nAsyncHandle] = self.tbAllAsyncHandles[nAsyncHandle] or INVALID_ID
    return nAsyncHandle
end

local function CancelAsyncLoadWithCharacter(self, tbCharacter, nAsyncHandle, fnCallback)
    local nBPEffectId = self.tbAllAsyncHandles and self.tbAllAsyncHandles[nAsyncHandle]
    if not nBPEffectId then
        return
    end

    if nBPEffectId == INVALID_ID then
        ResourceManager:CancelLoadAsync(nAsyncHandle)
    else
        local pAbilityEffectComponent = GetAbilityEffectComponent(tbCharacter)
        if pAbilityEffectComponent then
            fnCallback(pAbilityEffectComponent, nBPEffectId)
        end
    end
    self.tbAllAsyncHandles[nAsyncHandle] = nil
end

--[[
    逻辑辅助判断接口
]]
-- 检查Pawn是否为目标
function BattleAbilitySystem:CheckIsTargetPawn(tbOwnerPawn, tbTargetPawn, nTargetType)
    if tbTargetPawn == nil then
        return false
    end
    if GameObjectSystem:IsCharacter(tbTargetPawn) == false then
        return false
    end
    local bTeammate = CampSystem:IsFriendRelation(tbTargetPawn, tbOwnerPawn)
    local bSelf = tbTargetPawn == tbOwnerPawn
    if nTargetType == TARGET_TYPE.ENEMY then                    -- 敌方全体
        return not bTeammate
    elseif nTargetType == TARGET_TYPE.TEAMMATE_AND_SELF then    -- 友方全体
        return bTeammate
    elseif nTargetType == TARGET_TYPE.TEAMMATE then             -- 除自己的友方
        return (not bSelf) and bTeammate
    elseif nTargetType == TARGET_TYPE.SELF then                 -- 自己
        return bSelf
    elseif nTargetType == TARGET_TYPE.ALL then                  -- 敌我双方所有单位
        return true
    end
    return false
end

-- 获取范围内目标
function BattleAbilitySystem:GetPawnsInRange(pLocation, pRotation, nRangeType, tbRangeParams)
    local tbUEPawns = {}
    if nRangeType == RANGE_TYPE.All then                        -- 全范围
        tbUEPawns = fnGetAllActorsOfClass(GWorld, Pawn)
    else
        if nRangeType == RANGE_TYPE.SECTOR then                 -- 扇形
            tbUEPawns = fnGetActorsInSectorRange(GWorld, Pawn, pLocation, pRotation, tbRangeParams[1], tbRangeParams[2])
        elseif nRangeType == RANGE_TYPE.CIRCLE then             -- 圆形
            tbUEPawns = fnGetPawnsInCircleRange(GWorld, pLocation, tbRangeParams[1])
        elseif nRangeType == RANGE_TYPE.RECT then               -- 矩形
            tbUEPawns = fnGetPawnsInRectRange(GWorld, pLocation, pRotation, KismetMathLibrary.MakeVector(tbRangeParams[1], tbRangeParams[2], 10000))
        end
    end
    local tbRetPawns = {}
    for i,v in ipairs(tbUEPawns) do
        local tbPawn = GameObjectSystem:FindByUEActor(v)
        if tbPawn then
            table.insert(tbRetPawns, tbPawn)
        end
    end
    return tbRetPawns
end

--[[
    获取相关文字描述
]]
-- 获取技能的描述文字
function BattleAbilitySystem:GetSkillDesc(nSkillId, nLevel)
    local tbResTemplate = SkillDataTable:GetResTemplate(nSkillId)
    return GetAbilityDesc(GetSkillParamValue, tbResTemplate.l10nDesc, nSkillId, nLevel)
end

-- 获取Buff的描述文字
function BattleAbilitySystem:GetBuffDesc(nBuffId, nLevel)
    local tbResTemplate = BattleBuffDataTable:GetResTemplate(nBuffId)
    return GetAbilityDesc(GetBuffParamValue, tbResTemplate.l10nDesc, nBuffId, nLevel)
end

--[[
    粒子接口
]]
-- 播放一组粒子特效
function BattleAbilitySystem:PlayParticleEffects(tbCharacter, tbTemplateIds, nOverlapTime)
    local tbAsyncHandles = {}
    if tbTemplateIds then
        for i,v in ipairs(tbTemplateIds) do
            tbAsyncHandles[i] = BattleAbilitySystem:PlayParticleEffect(tbCharacter, v, nOverlapTime)
        end
    end
    return tbAsyncHandles
end

-- 播放粒子特效
function BattleAbilitySystem:PlayParticleEffect(tbCharacter, nTemplateId, nOverlapTime, tbOptionalParams)
    local tbTemplate = AbilityParticleEffectResDataTable:GetTemplate(nTemplateId)
    if not tbTemplate then
        logerror("PlayParticleEffect failed, Template is nil, nTemplateId =", nTemplateId)
        return INVALID_ID
    end
    local szFxRes = tbTemplate.szFxRes
    if not szFxRes then
        logerror("PlayParticleEffect failed, szFxRes is nil, nTemplateId =", nTemplateId)
        return INVALID_ID
    end

    return AsyncLoadWithCharacter(self, tbCharacter, szFxRes,
        function(tbCharacterEx, pCharacter, pAbilityEffectComponent, pFxRes)
            local nDuration = nOverlapTime and nOverlapTime or tbTemplate.nDuration
            local bAutoDestroy = nDuration <= 0
            local nFxScale = tbTemplate.nBaseScale
            if tbTemplate.bFxAutoScale then
                if tbCharacterEx:IsShip() then
                    nFxScale = nFxScale * pCharacter:GetShipBaseScale()
                end
            end
            local nBPEffectId = INVALID_ID
            local bDestroyOnStop = tbTemplate.bDestroyOnStop
            local szSocketName = tbTemplate.szAttachedFxSocketName
            local szComponentName = tbTemplate.szAttachedComponentName

            local pAttachedComponent = nil
            if szComponentName then
                -- 先在角色身上找Component
                pAttachedComponent = pCharacter[szComponentName]

                -- 如果没在角色身上找到Component，且玩家还是船形态，去ShipMaster上找
                if (not pAttachedComponent) and (tbCharacterEx:IsShip()) then
                    pAttachedComponent = pCharacter.ShipModelActor[szComponentName]
                end
            end

            -- 没有查到AttachComponent的话直接用RootComponent
            if not pAttachedComponent then
                szSocketName = ""
                pAttachedComponent = pCharacter:K2_GetRootComponent()
            end

            if tbTemplate.bAttachToCharacter then
                local bAbsoluteRotation = tbTemplate.bAbsoluteRotation
                nBPEffectId = pAbilityEffectComponent:SpawnEmitterAttached(pFxRes, pAttachedComponent, szSocketName, DEFAULT_TRANSFORM, nFxScale, nDuration, bAutoDestroy, bDestroyOnStop, bAbsoluteRotation)
            else
                local pLocation = pAttachedComponent:GetSocketLocation(szSocketName)
                local pRotation = pAttachedComponent:GetSocketRotation(szSocketName)

                if tbOptionalParams and tbOptionalParams.Location then
                    pLocation.X = tbOptionalParams.Location.X
                    pLocation.Y = tbOptionalParams.Location.Y
                    pLocation.Z = tbOptionalParams.Location.Z
                end
                nBPEffectId = pAbilityEffectComponent:SpawnEmitterAtLocation(pFxRes, pLocation, pRotation, nFxScale, nDuration, bAutoDestroy, bDestroyOnStop)
            end
            return nBPEffectId
        end
    )
end

function BattleAbilitySystem:UpdateParticleEffects(tbCharacter, tbAsyncHandles)
end

function BattleAbilitySystem:UpdateParticleEffect(tbCharacter, nAsyncHandle)
end

function BattleAbilitySystem:StopParticleEffects(tbCharacter, tbAsyncHandles)
    if not tbAsyncHandles then
        return
    end
    for _, nAsyncHandle in ipairs(tbAsyncHandles) do
        BattleAbilitySystem:StopParticleEffect(tbCharacter, nAsyncHandle)
    end
end

function BattleAbilitySystem:StopParticleEffect(tbCharacter, nAsyncHandle)
    CancelAsyncLoadWithCharacter(self, tbCharacter, nAsyncHandle, function(pAbilityEffectComponent, nBPEffectId)
        pAbilityEffectComponent:RemoveEmitterById(nBPEffectId)
    end)
end

--[[
    声音接口
]]
-- 播放声音
function BattleAbilitySystem:PlaySound(tbCharacter, szSoundRes, bMulticast, bAutoDestroy, pLocation, fFadeInTime, fFadeOutTime, fVolume)
    if not szSoundRes then
        return INVALID_ID
    end

    return AsyncLoadWithCharacter(self, tbCharacter, szSoundRes,
        function(tbCharacterEx, pCharacter, pAbilityEffectComponent, pSoundRes)
            -- bMulticast = bMulticast ~= nil and bMulticast or true
            if bAutoDestroy == nil then
                bAutoDestroy = true
            end

            pLocation = pLocation ~= nil and pLocation or pCharacter:K2_GetActorLocation()
            fFadeInTime = fFadeInTime ~= nil and fFadeInTime or 0
            fFadeOutTime = fFadeOutTime ~= nil and fFadeOutTime or 0
            fVolume = fVolume ~= nil and fVolume or 1

            return pAbilityEffectComponent:SpawnSoundAtLocation(pSoundRes, pLocation, DEFAULT_ROTATOR, fFadeInTime, fFadeOutTime, fVolume, bAutoDestroy)
        end
    )
end

function BattleAbilitySystem:UpdateSound(tbCharacter, nAsyncHandle)
end

function BattleAbilitySystem:StopSound(tbCharacter, nAsyncHandle)
    CancelAsyncLoadWithCharacter(self, tbCharacter, nAsyncHandle, function(pAbilityEffectComponent, nBPEffectId)
        pAbilityEffectComponent:RemoveSoundById(nBPEffectId)
    end)
end

--[[
    后处理接口
]]
function BattleAbilitySystem:PlayPostProcessEffect(tbCharacter, nResId)
    local tbTemplate = AbilityPostProcessEffectResDataTable:GetTemplate(nResId)
    if not tbTemplate then
        return INVALID_ID
    end

    local nAsyncHandle = AsyncLoadWithCharacter(self, tbCharacter, tbTemplate.szDataRes,
        function(tbCharacterEx, pCharacter, pAbilityEffectComponent, pDataRes)
            local nPriority = tbTemplate.nPriority
            local nBPEffectId = pAbilityEffectComponent:PlayPostProcessEffect(pDataRes, nPriority)
            log("BattleAbilitySystem:PlayPostProcessEffect exec nBPEffectId =", nBPEffectId)
            return nBPEffectId
        end
    )
    log("BattleAbilitySystem:PlayPostProcessEffect nResId, nAsyncHandle =", nResId, nAsyncHandle)
    return nAsyncHandle
end

function BattleAbilitySystem:UpdatePostProcessEffect(tbCharacter, nAsyncHandle)
end

function BattleAbilitySystem:StopPostProcessEffect(tbCharacter, nAsyncHandle)
    log("BattleAbilitySystem:StopPostProcessEffect nAsyncHandle =", nAsyncHandle)
    CancelAsyncLoadWithCharacter(self, tbCharacter, nAsyncHandle, function(pAbilityEffectComponent, nBPEffectId)
        log("BattleAbilitySystem:StopPostProcessEffect exec nBPEffectId =", nBPEffectId)
        pAbilityEffectComponent:RemovePostProcessById(nBPEffectId)
    end)
end

--[[
    材质接口
]]
-- 播放材质特效
function BattleAbilitySystem:PlayMaterialEffect(tbCharacter, nMaterialEffectType, nOverlapTime)
end

function BattleAbilitySystem:UpdateMaterialEffect(tbCharacter)
end

function BattleAbilitySystem:StopMaterialEffect(tbCharacter)
end

function BattleAbilitySystem:PlayLensEffect(tbCharacter, szLensEffectRes)
    if StringUtil.IsEmptyString(szLensEffectRes) then
        return INVALID_ID
    end
    local nAsyncHandle = ResourceManager:LoadAsync(szLensEffectRes, function(_, pLensEffectRes, nHandle)
        local pController = tbCharacter.pUEActor and tbCharacter.pUEActor:GetController()
        if pController then
            pController:ClientAddCameraLensEffect(pLensEffectRes)
            self.tbAllLensEffects[nHandle] = pLensEffectRes
        else
            ResourceManager:Unhold(pLensEffectRes)
        end
    end, true)
    return nAsyncHandle
end

function BattleAbilitySystem:StopLensEffect(tbCharacter, nAsyncHandle)
    if nAsyncHandle == INVALID_ID then
        return
    end
    local pLensEffectRes = self.tbAllLensEffects and self.tbAllLensEffects[nAsyncHandle]
    if pLensEffectRes then
        local pController = tbCharacter.pUEActor and tbCharacter.pUEActor:GetController()
        if pController then
            pController:ClientRemoveCameraLensEffect(pLensEffectRes)
        end
        ResourceManager:Unhold(pLensEffectRes)
    else
        ResourceManager:CancelLoadAsync(nAsyncHandle)
    end
    if self.tbAllLensEffects then
        self.tbAllLensEffects[nAsyncHandle] = nil
    end
end

function BattleAbilitySystem:Init()
    self.tbAllAsyncHandles = {}
    self.tbAllLensEffects = {}
end

function BattleAbilitySystem:Uninit()
    for nAsyncHandle, nBPEffectId in pairs(self.tbAllAsyncHandles) do
        if nBPEffectId == INVALID_ID then
            ResourceManager:CancelLoadAsync(nAsyncHandle)
        end
    end
    for nAsyncHandle, pLensEffectRes in pairs(self.tbAllLensEffects) do
        if pLensEffectRes then
            ResourceManager:Unhold(pLensEffectRes)
        else
            ResourceManager:CancelLoadAsync(nAsyncHandle)
        end
    end
    self.tbAllAsyncHandles = nil
    self.tbAllLensEffects = nil
end

return BattleAbilitySystem

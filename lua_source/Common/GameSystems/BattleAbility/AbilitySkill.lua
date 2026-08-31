local luaclass = require("luaclass")
local AbilitySkill = luaclass("AbilitySkill")

local StringUtil = require("StringUtil")
local SkillDataTable = require("SkillDataTable")
local AbilityEventBase = require("AbilityEventBase")
local GameObjectTypeDef = require("GameObjectTypeDef")
local BattleAbilitySystem = require("BattleAbilitySystem")
local BattleAbilityDefine = require("BattleAbilityDefine")
local SelfTimerHelperClass = require("SelfTimerHelper")
local SelfAbilityHelperClass = require("SelfAbilityHelper")
local AbilityParamParseUtils = require("AbilityParamParseUtils")
local PropUtil = require("PropUtil")

local ABILITY_CONDITION_CD_SUFFIX               = "CD"
local ABILITY_CONDITION_MAX_CAST_COUNT_SUFFIX   = "MaxCastCount"
local ABILITY_CONSUMABLE_EP                     = "EP"
local ABILITY_ACTION_GROUP_PATTERN              = "(%d+)={(.-)}"
local DEFAULT_SKILL_LEVEL                       = 1

AbilitySkill.Owner          = nil
AbilitySkill.OwnerPawn      = nil
AbilitySkill.nTemplateId    = 0
AbilitySkill.nLevel         = 1
AbilitySkill.tbTemplate     = nil
AbilitySkill.tbResTemplate  = nil
AbilitySkill.tbEventTargets = nil

AbilitySkill.TimerHelper    = nil
AbilitySkill.AbilityHelper  = nil

AbilitySkill.tbEvents       = nil
AbilitySkill.tbConditions   = nil
AbilitySkill.tbConsumables  = nil
AbilitySkill.tbActionGroups = nil
AbilitySkill.CDTimer        = nil

AbilitySkill.nCastCount     = 0
AbilitySkill.bServer        = false
AbilitySkill.bEnabled       = true
AbilitySkill.nCdTime        = 0

local function OnEventTriggerCast(self, tbParams)
    if self:CheckCondition() then
        if tbParams and tbParams.tbTargetPawns then
            self.tbEventTargets = tbParams.tbTargetPawns
        end
        self:Cast()
        return true
    end
    return false
end

local function OnEventTriggerUndo(self, tbParams)
    if tbParams and tbParams.tbTargetPawns then
        self.tbEventTargets = tbParams.tbTargetPawns
    end
    self:ExcuteActionGroupEnd()
    return true
end

-- 开始CD
local function StartCD(self)
    local nCdTime = self.nCdTime
    if nCdTime > 0 then
        self:ClearCD()
        self.CDTimer = self.TimerHelper:NewTimerMethod(self, self.ClearCD, nCdTime)
    end
end

-- 处理消耗
local function HandleConsume(self)
    for k,v in pairs(self.tbConsumables) do
        k:HandleConsume(self, v)
    end
end

local function GetEffectiveTargetType(self)
    local nEffectiveTargetType = self.tbTemplate.nEffectiveTargetType
    local EffectiveTypeDefine = BattleAbilityDefine.EFFECTIVE_TARGET_TYPE
    local TargetType = PropUtil.TARGET_TYPE
    if nEffectiveTargetType == EffectiveTypeDefine.HUMAN then
        return TargetType.HUMAN
    elseif nEffectiveTargetType == EffectiveTypeDefine.SHIP then
        return TargetType.SHIP
    elseif nEffectiveTargetType == EffectiveTypeDefine.SHIP_AND_HUMAN then
        return TargetType.AUTO
    else
        error("AbilityBuffServer GetEffectiveTargetType failed. No nEffectiveTargetType = "..nEffectiveTargetType..". Buff template id: ".. self.nTemplateId)
        return nil
    end
end

-- 初始化技能释放条件列表
local function InitEvents(self)
    self.tbEvents = {}

    -- 遍历主动触发时间配置
    local tbEventList = StringUtil.Split(self.tbTemplate.szEventList, ";")
    for i,v in ipairs(tbEventList) do
        local szName, tbParams = AbilityParamParseUtils.GetParamList(v)
        local AbilityEventClass = require(BattleAbilityDefine.ABILITY_EVENT_PREFIX .. szName)
        local AbilityEvent = AbilityEventClass()
        AbilityEvent:Create(self, self.OwnerPawn, tbParams, OnEventTriggerCast, OnEventTriggerUndo)
        self.tbEvents[AbilityEvent] = tbParams
    end
end

-- 初始化技能释放条件列表
local function InitConditions(self)
    self.tbConditions = {}

    -- 最大次数不为0时，插入最大次数条件
    local nMaxCastCount = self.tbTemplate.nMaxCastCount
    if nMaxCastCount > 0 then
        local AbilityConditionMaxCount = require(BattleAbilityDefine.ABILITY_CONDITION_PREFIX .. ABILITY_CONDITION_MAX_CAST_COUNT_SUFFIX)
        self.tbConditions[AbilityConditionMaxCount] = nMaxCastCount
    end

    -- CD时间不为0时，插入CD条件
    local AbilityConditionCD = require(BattleAbilityDefine.ABILITY_CONDITION_PREFIX .. ABILITY_CONDITION_CD_SUFFIX)
    self.tbConditions[AbilityConditionCD] = self.nCdTime

    -- 遍历前置条件配置
    local tbConditionList = StringUtil.Split(self.tbTemplate.szConditionList, ";")
    for i,v in ipairs(tbConditionList) do
        local szName, tbParams = AbilityParamParseUtils.GetParamList(v)
        local AbilityCondition = require(BattleAbilityDefine.ABILITY_CONDITION_PREFIX .. szName)
        self.tbConditions[AbilityCondition] = tbParams
    end
end

-- 初始化消耗列表
local function InitConsumables(self)
    self.tbConsumables = {}

    -- 遍历消耗列表配置
    local tbConsumableList = StringUtil.Split(self.tbTemplate.szConsumableList, ";")
    for i,v in ipairs(tbConsumableList) do
        local szName, tbParams = AbilityParamParseUtils.GetParamList(v)
        local AbilityConsumable = require(BattleAbilityDefine.ABILITY_CONSUMABLE_PREFIX .. szName)
        self.tbConsumables[AbilityConsumable] = tbParams
        self.bChargeSkill = (szName == ABILITY_CONSUMABLE_EP)
    end
end

-- 初始化ActionGroup
local function InitActionGroups(self)
    self.tbActionGroups = {}
    local iteratorFunc = string.gmatch(self.tbTemplate.szActionGroupList, ABILITY_ACTION_GROUP_PATTERN) -- 返回的迭代器用于给Action分组
    for szIndex, szActionInfos in iteratorFunc do
        local tbActionInfoList = StringUtil.Split(szActionInfos, ";") -- 分割多个Action
        local tbActions = {}
        for i,v in ipairs(tbActionInfoList) do
            local szName, tbParams = AbilityParamParseUtils.GetParamListWithLevel(v, self.nLevel)
            local AbilityActionClass = require(BattleAbilityDefine.ABILITY_ACTION_PREFIX .. szName)
            local tbAbilityAction = AbilityActionClass()
            tbAbilityAction:Create(self, self.OwnerPawn, self.OwnerPawn, tbParams, GetEffectiveTargetType(self))
            tbActions[i] = tbAbilityAction
        end
        self.tbActionGroups[tonumber(szIndex)] = tbActions
    end
end

local function PlaySkillMontage(self)
    local pMontage = self.tbResTemplate.szMontageRes:load()
    self.OwnerPawn:PlaySkillMontage(self, pMontage)
end

-- public function
function AbilitySkill:Create(Owner, nTemplateId, nLevel, bServer)
    -- log("[Skill] Skill Create, id =", nTemplateId)
    self.Owner = Owner
    self.OwnerPawn = Owner.Owner
    self.nTemplateId = nTemplateId
    self.nLevel = nLevel and nLevel or DEFAULT_SKILL_LEVEL
    self.bServer = bServer

    self.TimerHelper = SelfTimerHelperClass()
    self.AbilityHelper = SelfAbilityHelperClass()

    self.tbTemplate = SkillDataTable:GetTemplate(nTemplateId)
    if not self.tbTemplate then
        error('Skill init failed, cannot find template. nTemplateId =', nTemplateId)
    end
    self.nCdTime = self.tbTemplate.nCdTime
    if self.tbTemplate.nResId then
        self.tbResTemplate = SkillDataTable:GetResTemplate(nTemplateId)
    end

    InitConditions(self)
    InitConsumables(self)
    if bServer then
        InitActionGroups(self)
        InitEvents(self)
        if self.OwnerPawn.ObjectType == GameObjectTypeDef.PlayerSelf then
            self:SetEnabled(true)
        end
    end
end

function AbilitySkill:Destroy()
    if self.bServer then
        self:SetEnabled(false)
    end
    if self.TimerHelper then
        self.TimerHelper:ClearAllTimer()
        self.TimerHelper = nil
    end
    self.tbTemplate = nil
    self.tbResTemplate = nil

    self.tbEvents = nil
    self.tbConditions = nil
    self.tbConsumables = nil
    self.tbActionGroups = nil
    self.CDTimer = nil
end

function AbilitySkill:SetEnabled(bEnabled)
    self.bEnabled = bEnabled
    local func = bEnabled and AbilityEventBase.Activate or AbilityEventBase.Deactivate
    for k,v in pairs(self.tbEvents) do
        func(k)
    end
end

--[[
    技能释放阶段
]]
-- 预释放技能(预留接口，目前没有任何实现)
function AbilitySkill:PreCast()
end

-- 释放技能
function AbilitySkill:Cast()
    -- log("[Skill] Skill Cast, id =", self.nTemplateId)
    self.nCastCount = self.nCastCount + 1
    StartCD(self)
    if self.bServer then
        HandleConsume(self)
        if self.tbTemplate.bUseTimeline then
            PlaySkillMontage(self)
        else
            local OwnerPawn = self.OwnerPawn
            local tbResTemplate = self.tbResTemplate
            BattleAbilitySystem:PlayParticleEffects(OwnerPawn, tbResTemplate.tbFxIds)
            if tbResTemplate.tbTargetFxIds then
                local tbTargetPawns = self:GetSkillTargetPawn()
                for i,v in ipairs(tbTargetPawns) do
                    BattleAbilitySystem:PlayParticleEffects(v, tbResTemplate.tbFxIds)
                end
            end
            BattleAbilitySystem:PlaySound(OwnerPawn, tbResTemplate.szSoundRes, false)
            self:ExcuteActionGroup(1)
            self:ExcuteSubSkill()
        end
    end
end

-- 执行ActionGroup
function AbilitySkill:ExcuteActionGroup(nActionGroupIndex)
    nActionGroupIndex = nActionGroupIndex and nActionGroupIndex or 1
    local tbParams = {}
    tbParams.tbTargetPawns = self:GetSkillTargetPawn()
    tbParams.nLevel = self.nLevel
    tbParams.nTargetType = self.tbTemplate.nTargetType
    local pLocation, pRotation = self:GetCenterTargetInfo()
    tbParams.tbCenterTargetInfo =
    {
        pCenterLocation = pLocation,
        pCenterRotation = pRotation
    }

    local tbActionGroup = self.tbActionGroups[nActionGroupIndex]
    if tbActionGroup then
        for i,v in pairs(tbActionGroup) do
            v:Do(tbParams)
        end
    else
        logerror("AbilitySkill ExcuteAction Failed, can't find ActionGroup, index =", nActionGroupIndex)
    end
end

-- 执行ActionGroup
function AbilitySkill:ExcuteActionGroupEnd(nActionGroupIndex)
    nActionGroupIndex = nActionGroupIndex and nActionGroupIndex or 1
    local tbParams = {}
    tbParams.tbTargetPawns = self:GetSkillTargetPawn()
    tbParams.nLevel = self.nLevel
    tbParams.nTargetType = self.tbTemplate.nTargetType
    local pLocation, pRotation = self:GetCenterTargetInfo()
    tbParams.tbCenterTargetInfo =
    {
        pCenterLocation = pLocation,
        pCenterRotation = pRotation
    }

    local tbActionGroup = self.tbActionGroups[nActionGroupIndex]
    if tbActionGroup then
        for i,v in pairs(tbActionGroup) do
            v:Undo(tbParams)
        end
    else
        logerror("AbilitySkill ExcuteAction Failed, can't find ActionGroup, index =", nActionGroupIndex)
    end
end

-- 执行子技能
function AbilitySkill:ExcuteSubSkill()
    local nSubSkillId = self.tbTemplate.nSubSkillId
    if nSubSkillId > 0 then
        self.Owner:RequestCastSkill(nSubSkillId)
    end
end

-- 技能释放条件检测
function AbilitySkill:CheckCondition()
    self.Owner:RefreshTargetPawn()
    -- 先检查消耗
    for k,v in pairs(self.tbConsumables) do
        if not k:CheckCondition(self, v) then
            return false, k:GetConditionID()
        end
    end
    -- 检查前置条件
    for k,v in pairs(self.tbConditions) do
        if not k:CheckCondition(self, v) then
            return false, k:GetConditionID()
        end
    end
    return true
end

-- 获取技能生效参考中心目标信息
function AbilitySkill:GetCenterTargetInfo()
    local nCenterTarget = self.tbTemplate.nCenterTarget
    local pOwnerPawn = self.OwnerPawn.pUEActor
    local pTarget = pOwnerPawn
    if nCenterTarget == 2 then
        local tbTargetPawn = self.Owner.tbTargetPawn
        if tbTargetPawn and tbTargetPawn.pUEActor then
            pTarget = tbTargetPawn.pUEActor
        end
    end
    local pLocation = nil
    local pRotation = nil
    if pTarget then
        pLocation = EngineExtActorShell.GetActorLocation(pTarget)
        pRotation = EngineExtActorShell.GetActorRotation(pTarget)
        pRotation.Yaw = pRotation.Yaw + self.tbTemplate.nCenterAngleOffset
        local pForwardVector = KismetMathLibrary.GetForwardVector(pRotation)
        local pNormalForwardVector = KismetMathLibrary.Normal(pForwardVector, GDefaultTolerance)
        local pLocationDelta = KismetMathLibrary.Multiply_VectorFloat(pNormalForwardVector, self.tbTemplate.nCenterOffset)
        pLocation = KismetMathLibrary.Add_VectorVector(pLocation, pLocationDelta)
    end
    return pLocation, pRotation
end

-- 获取技能目标对象List
function AbilitySkill:GetSkillTargetPawn()
    local tbTemplate = self.tbTemplate
    local nTargetType = tbTemplate.nTargetType
    if nTargetType == 4 then
        return { self.OwnerPawn }
    elseif nTargetType == 6 then
        return self.tbEventTargets
    end

    local tbRet = {}
    local pLocation, pRotation = self:GetCenterTargetInfo()
    local tbPawnsInRange = BattleAbilitySystem:GetPawnsInRange(pLocation, pRotation, tbTemplate.nRangeType, tbTemplate.tbRangeParams)
    for i,v in ipairs(tbPawnsInRange) do
        if BattleAbilitySystem:CheckIsTargetPawn(self.OwnerPawn, v, nTargetType) then
            table.insert(tbRet, v)
        end
    end
    return tbRet
end

function AbilitySkill:GetCDRemainingTime()
    if self.CDTimer then
        return self.CDTimer:GetRemainingTime()
    end
    return 0
end

function AbilitySkill:IsInCD()
    return self.CDTimer ~= nil
end

-- 清除CD
function AbilitySkill:ClearCD()
    self.TimerHelper:ClearTimer(self.CDTimer)
    self.CDTimer = nil
end

function AbilitySkill:IsIgnoreGlobalCD()
    return self.tbTemplate.bIgnoreGlobalCD
end

function AbilitySkill:GetChargeConsumeValue()
    local AbilityConsumable = require(BattleAbilityDefine.ABILITY_CONSUMABLE_PREFIX .. ABILITY_CONSUMABLE_EP)
    for k,v in pairs(self.tbConsumables) do
        if k == AbilityConsumable then
            return v.Value
        end
    end
    return 0
end

function AbilitySkill:ShowSkillRange(nLifeTime)
    if self.tbTemplate.bHideSkillRange then
        return
    end
    local pGameMode = GameplayStatics.GetGameMode(GWorld)
    local nRangeType = self.tbTemplate.nRangeType
    local tbRangeParams = self.tbTemplate.tbRangeParams
    local RangeType = BattleAbilityDefine.RangeType
    local pOwnerPawnUEActor = self.OwnerPawn.pUEActor
    local pSkillRange = nil
    if nRangeType == RangeType.SECTOR then
        pSkillRange = pGameMode.SkillRangeManager:ShowSectorRange(pOwnerPawnUEActor, nLifeTime, tbRangeParams[1], tbRangeParams[2])
    elseif nRangeType == RangeType.CIRCLE then
        pSkillRange = pGameMode.SkillRangeManager:ShowCircleRange(pOwnerPawnUEActor, nLifeTime, tbRangeParams[1])
    elseif nRangeType == RangeType.RECT then
        pSkillRange = pGameMode.SkillRangeManager:ShowRectRange(pOwnerPawnUEActor, nLifeTime, tbRangeParams[1], tbRangeParams[2])
    end
    if pSkillRange then
        pSkillRange:AttachToActor(pOwnerPawnUEActor)
    end
    self.pSkillRange = pSkillRange
end

function AbilitySkill:HideSkillRange()
    if self.pSkillRange then
        self.pSkillRange:Hide()
        self.pSkillRange = nil
    end
end

return AbilitySkill

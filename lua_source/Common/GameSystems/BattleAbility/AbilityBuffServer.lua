local luaclass = require("luaclass")
local AbilityBuffServer = luaclass("AbilityBuffServer")

-- require
local StringUtil = require("StringUtil")
local LuaDelegateClass = require("LuaDelegate")
local BattleAbilityDefine = require("BattleAbilityDefine")
local BattleBuffDataTable = require("BattleBuffDataTable")
local SelfTimerHelperClass = require("SelfTimerHelper")
local AbilityParamParseUtils = require("AbilityParamParseUtils")
local SelfAbilityHelperClass = require("SelfAbilityHelper")
local EventManager = require("EventManager")
local CommonEventDef = require("CommonEventDef")
local PropUtil = require("PropUtil")
local PropName = require("PropName")
local GlobalVariableSystem = dynamic_require("GlobalVariableSystem")
local GameObjectSystem = dynamic_require("GameObjectSystem")

local ALLOW_REDUCE_TIME_GROUP_ID = BattleAbilityDefine.BUFF_GROUP_TYPE.ALLOW_REDUCE_TIME

-- variable
AbilityBuffServer.Owner                = nil
AbilityBuffServer.tbInstigator         = nil
AbilityBuffServer.nTemplateId          = 0
AbilityBuffServer.tbTemplate           = nil
AbilityBuffServer.nInstanceId          = 0

AbilityBuffServer.TimerHelper          = nil
AbilityBuffServer.AbilityHelper        = nil

AbilityBuffServer.tbEvents             = nil
AbilityBuffServer.tbConditions         = nil
AbilityBuffServer.tbPostCheckConditions= nil
AbilityBuffServer.tbActions            = nil

AbilityBuffServer.nOverlapCount        = 0
AbilityBuffServer.nUpdateTime          = 0

AbilityBuffServer.LifeTimeEndDelegate  = nil

local function VerifyEventParams(self, tbParams)
    if tbParams == nil then
        tbParams = {}
    end
    if tbParams.tbTargetPawns == nil then
        if self.tbTemplate.bEffectToInstigator then
            tbParams.tbTargetPawns = {self.tbInstigator}
        else
            tbParams.tbTargetPawns = {self.OwnerPawn}
        end
    end
    return tbParams
end

-- 检查条件并执行Buff内Action
local function OnEventTriggerDo(self, tbParams)
    if self:CheckCondition() then
        tbParams = VerifyEventParams(self, tbParams)
        for i,v in ipairs(self.tbActions) do
            v:Do(tbParams)
        end
        return true
    end
    return false
end

local function OnEventTriggerUndo(self, tbParams)
    tbParams = VerifyEventParams(self, tbParams)
    for i,v in ipairs(self.tbActions) do
        v:Undo(tbParams)
    end
    return true
end

local function OnEventTriggerPostDo(self, tbParams)
    if not self:PostCheckCondition() then
        EventManager:OnFireEvent(CommonEventDef.EV_TRIGGER_REMOVE_BUFF, self)
    end
end

local function GetLifeTime(self)
    local nTime = self.tbTemplate.nTime
    if GameObjectSystem:IsCharacter(self.OwnerPawn)
    and self.OwnerPawn:IsShip()
    and self.tbTemplate.nGroupId == ALLOW_REDUCE_TIME_GROUP_ID then
        nTime = nTime * self.OwnerPawn.ShipBattlePropertyComponent:GetProp(PropName.nShipDebuffTimeRatio)
    end
    return nTime
end

local function StartLifeTimer(self)
    local nTime = GetLifeTime(self)
    if nTime > 0 then
        self.TimerHelper:ClearTimer(self.LifeTimer)
        self.LifeTimer = self.TimerHelper:NewTimerMethod(self, function()
            self.LifeTimeEndDelegate:Fire()
        end, nTime)
    end
end

-- 设置Buff触发事件的开关
local function ActivateEvent(self)
    for i,v in ipairs(self.tbEvents) do
        v:Activate()
    end
end

-- 设置Buff触发事件的开关
local function DeactivateEvent(self)
    for i,v in ipairs(self.tbEvents) do
        v:Deactivate()
    end
end

local function InitEvents(self)
    self.tbEvents = {}

    local tbEventList = StringUtil.Split(self.tbTemplate.szEventList, ";")
    for i,v in ipairs(tbEventList) do
        local szName, tbParams = AbilityParamParseUtils.GetParamListWithLevel(v, self.nLevel)
        local AbilityEventClass = require(BattleAbilityDefine.ABILITY_EVENT_PREFIX .. szName)
        local AbilityEvent = AbilityEventClass()
        AbilityEvent:Create(self, self.OwnerPawn, tbParams, OnEventTriggerDo, OnEventTriggerUndo, OnEventTriggerPostDo)
        self.tbEvents[i] = AbilityEvent
    end
end

local function InitConditionsInternal(szInputConditionList, tbOutput)
    local tbConditionList = StringUtil.Split(szInputConditionList, ";")
    for i,v in ipairs(tbConditionList) do
        local szName, tbParams = AbilityParamParseUtils.GetParamList(v)
        local AbilityCondition = require(BattleAbilityDefine.ABILITY_CONDITION_PREFIX .. szName)
        tbOutput[AbilityCondition] = tbParams
    end
end

local function InitConditions(self)
    self.tbConditions = {}
    InitConditionsInternal(self.tbTemplate.szConditionList, self.tbConditions)
end

local function InitPostCheckConditions(self)
    self.tbPostCheckConditions = {}
    InitConditionsInternal(self.tbTemplate.szPostCheckList, self.tbPostCheckConditions)
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

local function InitActions(self)
    self.tbActions = {}

    local tbActionList = StringUtil.Split(self.tbTemplate.szActionList, ";")
    for i,v in ipairs(tbActionList) do
        local szName, tbParams = AbilityParamParseUtils.GetParamListWithLevel(v, self.nLevel)
        local AbilityActionClass = require(BattleAbilityDefine.ABILITY_ACTION_PREFIX .. szName)
        local tbAbilityAction = AbilityActionClass()
        tbAbilityAction:Create(self, self.OwnerPawn, self.tbInstigator, tbParams, GetEffectiveTargetType(self))
        self.tbActions[i] = tbAbilityAction
    end
end

function AbilityBuffServer:Create(Owner, tbInstigator, nTemplateId, nLevel, nInstanceId, nOverlapCount)
    log("[Buff] AbilityBuffServer Create Buff, id =", nTemplateId)

    self.tbTemplate = BattleBuffDataTable:GetTemplate(nTemplateId)
    assert(self.tbTemplate, "nTemplateId: "..nTemplateId)

    self.Owner = Owner
    self.OwnerPawn = Owner.Owner
    self.tbInstigator = tbInstigator
    self.nTemplateId = nTemplateId
    self.nLevel = nLevel or 1
    self.nInstanceId = nInstanceId
    self.nUpdateTime = GlobalVariableSystem:GetDSTimeSeconds()
    self.nOverlapCount = nOverlapCount or 1

    self.TimerHelper = SelfTimerHelperClass()
    self.AbilityHelper = SelfAbilityHelperClass()
    self.LifeTimeEndDelegate = LuaDelegateClass()

    InitEvents(self)
    InitConditions(self)
    InitPostCheckConditions(self)
    InitActions(self)

    return true
end

function AbilityBuffServer:Destroy()
    log("[Buff] AbilityBuffServer Destroy Buff, id =", self.nTemplateId)
    DeactivateEvent(self)
    if self.TimerHelper then
        self.TimerHelper:ClearAllTimer()
        self.TimerHelper = nil
    end
    self.AbilityHelper = nil

    self.tbEvents = nil
    self.tbConditions = nil
    self.tbPostCheckConditions = nil
    self.tbActions = nil

    self.tbTemplate = nil
    self.tbResTemplate = nil
end

-- 处理Buff的叠加刷新
function AbilityBuffServer:Activate()
    log("[Buff] AbilityBuffServer Activate Buff, id =", self.nTemplateId)
    StartLifeTimer(self)
    for i=1, self.nOverlapCount do
        ActivateEvent(self)
    end
end

-- 处理Buff的叠加刷新
function AbilityBuffServer:Update(nOverlapCount)
    log("[Buff] AbilityBuffServer Update Buff, id =", self.nTemplateId)
    nOverlapCount = nOverlapCount or 1
    local nLastCount = self.nOverlapCount
    self.nOverlapCount =  math.min(nLastCount + nOverlapCount, self.tbTemplate.nMaxOverlap)
    self.nUpdateTime = GlobalVariableSystem:GetDSTimeSeconds()
    StartLifeTimer(self)
    for i=1,(self.nOverlapCount - nLastCount) do
        ActivateEvent(self)
    end
end

local function CheckConditionInternal(self, tbConditions)
    if tbConditions == nil then
        return true
    end
    for k,v in pairs(tbConditions) do
        if not k:CheckConditionWithTargetType(self, v, GetEffectiveTargetType(self)) then
            return false, k:GetConditionID()
        end
    end
    return true
end

-- 触发时条件检测
function AbilityBuffServer:CheckCondition()
    return CheckConditionInternal(self, self.tbConditions)
end

-- 触发后条件检测
function AbilityBuffServer:PostCheckCondition()
    return CheckConditionInternal(self, self.tbPostCheckConditions)
end

-- 获取Buff剩余时间
function AbilityBuffServer:GetRemainingTime()
    if self.LifeTimer then
        return self.LifeTimer:GetRemainingTime()
    end
    return 0
end

return AbilityBuffServer

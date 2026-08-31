-----------------------------------------------------
--File Name    : SkillComponentBase.lua
--Author       : Song Fuhao
--Create Time  : 2017-04-20
--Description  : 船只技能控制（Common基类）
-----------------------------------------------------
local luaclass = require("luaclass")
local GameComponentBaseClass = require("GameComponentBase")
local SkillComponentBase = luaclass("SkillComponentBase", GameComponentBaseClass)

local PropName = require("PropName")
local DungeonIni = require("DungeonIni")
local EventManager = require("EventManager")
local SkillDataTable = require("SkillDataTable")
local CommonEventDef = require("CommonEventDef")
local AbilitySkillClass = require("AbilitySkill")
-- local GameObjectTypeDef = require("GameObjectTypeDef")
local ShipSkillDataTable = require("ShipSkillDataTable")
local SkillCastFailedDef = require("SkillCastFailedDef")
local SelfEventHelperClass = require("SelfEventHelper")
local SelfTimerHelperClass = require("SelfTimerHelper")
local NetworkManager = dynamic_require("NetworkManager")
-- local GameObjectSystem = dynamic_require("GameObjectSystem")
-- local GlobalVariableSystem = dynamic_require("GlobalVariableSystem")

-- 创建技能实例并加入列表
local function CreateSkill(self, nSkillID, nSkillLevel)
    local Skill = AbilitySkillClass()
    Skill:Create(self, nSkillID, nSkillLevel, self.bServer)
    self.tbSkillList[nSkillID] = Skill
    local nSubSkillId = Skill.tbTemplate.nSubSkillId
    if nSubSkillId > 0 then
        CreateSkill(self, nSubSkillId, nSkillLevel)
    end
    return Skill
end

local function UninitSkill(self)
    if self.tbSkillList then
        for _,v in pairs(self.tbSkillList) do
            v:Destroy()
        end
    end
    self.tbSkillList = nil
end

local function InitSkill(self)
    self.tbSkillList = {}
    local nTemplateId = self.Owner:GetShipTemplateId()
    if nTemplateId ~= -1 then
        self.nCurrentShipId = nTemplateId
        self.tbSkillInfoList = ShipSkillDataTable:GetDefaultSkillInfo(nTemplateId).skill_list
        for _, tbSkillInfo in ipairs(self.tbSkillInfoList) do
            CreateSkill(self, tbSkillInfo.skill_id, tbSkillInfo.level)
        end
    end
end

local function OnShipTemplateIdChanged(self, nShipTemplateId)
    if self.nCurrentShipId ~= nShipTemplateId and self.Owner:IsHuman() then
        UninitSkill(self)
        InitSkill(self)
    end
end

-- public
SkillComponentBase.RPCNetworkProxy  = nil
SkillComponentBase.EventHelper      = nil
SkillComponentBase.TimerHelper      = nil
SkillComponentBase.tbSkillList      = nil
SkillComponentBase.tbSkillInfoList  = nil
SkillComponentBase.pUEComponent     = nil
SkillComponentBase.bServer          = false
SkillComponentBase.nGlobalCDTime    = DungeonIni.tbAbility.nGlobalCDTime
SkillComponentBase.tbTargetPawn     = nil
SkillComponentBase.nCurrentShipId   = -1

function SkillComponentBase:OnCreate(Owner, tbParams)
    SkillComponentBase.super.OnCreate(self, Owner, tbParams)
    self.RPCNetworkProxy = NetworkManager:GetRPCNetworkProxy()
    self.EventHelper = SelfEventHelperClass()
    self.TimerHelper = SelfTimerHelperClass()
end

function SkillComponentBase:OnActorCreated(pUEActor)
    SkillComponentBase.super.OnActorCreated(self, pUEActor)
    self.pUEComponent = pUEActor.AbilityComponent
    assert(self.pUEComponent, 'Can not find AbilityComponent on ' .. KismetSystemLibrary.GetDisplayName(pUEActor))

    InitSkill(self)

    self.Owner.ShipBattlePropertyComponent:BindPropChanged(PropName.nShipTemplateId, OnShipTemplateIdChanged, self)
end

function SkillComponentBase:OnActorDestroyed(pUEActor)
    self.EventHelper:UnregisterAll()
    self.TimerHelper:ClearAllTimer()
    UninitSkill(self)
    self.Owner.ShipBattlePropertyComponent:UnbindPropChanged(PropName.nShipTemplateId, OnShipTemplateIdChanged, self)
    SkillComponentBase.super.OnActorDestroyed(self, pUEActor)
end

function SkillComponentBase:OnDestroy()
    self.EventHelper = nil
    self.TimerHelper = nil
    SkillComponentBase.super.OnDestroy(self)
end

function SkillComponentBase:AcquireSkill(nSkillID, nSkillLevel)
    if self.tbSkillList[nSkillID] then
        logwarning('[Skill] SkillComponentBase AcquireSkill failed, skill is exist.')
        return
    end
    CreateSkill(self, nSkillID, nSkillLevel)
end

-- 通过ID获取技能示例
-- @param nSkillID 技能ID
function SkillComponentBase:GetSkillByID(nSkillID)
    local Skill = self.tbSkillList[nSkillID]
    if not Skill then
        logwarning('[Skill] SkillComponentBase GetSkillByID Failed, can not find skill by SkillID, ship_id =', self.Owner:GetTemplateId(),', skill_id =', nSkillID)
        return nil
    end
    return Skill
end

-- 请求释放技能
-- @param nSkillID 技能ID
function SkillComponentBase:RequestCastSkill(nSkillID)
    -- log('[Skill] RequestCastSkill, nSkillID =', nSkillID)
    local Skill = self:GetSkillByID(nSkillID)
    if not Skill then
        return false, SkillCastFailedDef.UNKNOWN_SKILL
    end

    local bRet, nFailedReasonID = self:CheckCondition(Skill)
    if not bRet then
        self:CastSkillFailed(Skill, nFailedReasonID)
        return false, nFailedReasonID
    end

    self:PreCastSkill(Skill)
    return true
end

-- 启用/禁用技能
function SkillComponentBase:SetSkillEnabled(nSkillID, bEnabled)
    -- log('[Skill] SetSkillEnabled, nSkillID =', nSkillID, " Eanbled :", bEnabled)
    local Skill = self:GetSkillByID(nSkillID)
    if Skill then
        Skill:SetEnabled(bEnabled)
    end
end

-- 判断是否可以释放技能
-- @param Skill 对应技能实例
-- @return bRet 是否可以释放技能
-- @return nFailedReasonID Cast失败原因ID
function SkillComponentBase:CheckCondition(Skill)
    if not self.pUEComponent:IsReady() then
        return false, SkillCastFailedDef.SKILL_CASTING
    end
    if (not Skill:IsIgnoreGlobalCD()) and self:IsInGlobalCD() then
        return false, SkillCastFailedDef.SKILL_IN_CD
    end
    return Skill:CheckCondition()
end

-- 技能释放失败
-- @param nSkillID 技能ID
-- @param nFailedReasonID Cast失败原因ID
function SkillComponentBase:CastSkillFailed(Skill, nFailedReasonID)
    -- if (nFailedReasonID ~= SkillCastFailedDef.SKILL_IN_CD) and (nFailedReasonID ~= SkillCastFailedDef.CHARGE_NOT_ENOUGH) then
        -- log('[Skill] CastSkillFailed, nSkillID =', tostring(Skill.nTemplateId), ', Reason =', L10N:ToString(SkillCastFailedText:GetText(nFailedReasonID)))
    -- end
end

-- 预释放技能
-- @param Skill 对应技能实例
function SkillComponentBase:PreCastSkill(Skill)
    self:CastSkill(Skill)
end

-- 释放技能
-- @param Skill 对应技能实例
function SkillComponentBase:CastSkill(Skill)
    if not Skill:IsIgnoreGlobalCD() then
        self:StartGlobalCD()
    end
    Skill:Cast()
end

function SkillComponentBase:GetSkillInfoList()
    return self.tbSkillInfoList
end

-- 根据技能类型获取当前角色身上对应技能
function SkillComponentBase:GetSkillIdListByType(nType, tbInOutIds)
    if(tbInOutIds == nil) then
        return tbInOutIds
    end

    for k,v in pairs(self.tbSkillList) do
        if (v.tbTemplate.nType == nType) and SkillDataTable:IsActiveSkill(v.nTemplateId) then
            table.insert(tbInOutIds, k)
        end
    end
    return tbInOutIds
end

function SkillComponentBase:StartGlobalCD()
    if self.nGlobalCDTime > 0 then
        self:ClearGlobalCD()
        self.GlobalCDTimer = self.TimerHelper:NewTimerMethod(self, self.ClearGlobalCD, self.nGlobalCDTime)
        EventManager:OnFireEvent(CommonEventDef.EV_SKILL_GLOBAL_CD_STARTED, self.nGlobalCDTime)
    end
end

function SkillComponentBase:ClearGlobalCD()
    if self.GlobalCDTimer then
        self.TimerHelper:ClearTimer(self.GlobalCDTimer)
        self.GlobalCDTimer = nil
    end
end

function SkillComponentBase:IsInGlobalCD()
    return self.GlobalCDTimer ~= nil
end

function SkillComponentBase:GetGlobalCDRemainingTime()
    if self.GlobalCDTimer then
        return self.GlobalCDTimer:GetRemainingTime()
    end
    return 0
end

function SkillComponentBase:GetGlobalCDTime()
    return self.nGlobalCDTime
end

function SkillComponentBase:ResetSkillCD()
    self:ClearGlobalCD()
    for k,v in pairs(self.tbSkillList) do
        v:ClearCD()
    end
end

function SkillComponentBase:RefreshTargetPawn()
    --[[ 跟富豪沟通，代码无用，注释掉保证单机本不会报错
    -- 单机模式下、NPC或者自动战斗的玩家，直接从蓝图中读取TargetPawn，否则取协议中传入的
    if GlobalVariableSystem:IsClient()
    or (self.Owner.ObjectType == GameObjectTypeDef.Npc)
    or ((self.Owner.ObjectType == GameObjectTypeDef.Player) and (self.Owner.BattleAIComponent.bEnable)) then
        local pTargetShip = self.Owner.pUEActor.ShipAimSystemComponent.TargetShip
        self.tbTargetPawn = GameObjectSystem:FindByUEActor(pTargetShip)
    end
    ]]
end

function SkillComponentBase:OnPawnDead()
    for i,v in ipairs(self.tbSkillList) do
        v:ClearCD()
    end
    self:ClearGlobalCD()
end

function SkillComponentBase:OnPawnReborn()
    -- 基类中暂无实现，派生类中有实现
end

return SkillComponentBase

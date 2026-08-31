local luaclass = require("luaclass")
local UILogicBase = require("UILogicBase")
local ULWatchBattleBuff = luaclass("ULWatchBattleBuff", UILogicBase)
-- local GamePlayerSelfHelper = require("GamePlayerSelfHelper")

local BattleBuffDataTable = require("BattleBuffDataTable")
local BattleBuffResDataTable = require("BattleBuffResDataTable")
local BattleAbilitySystem = require("BattleAbilitySystem")
local BattleAbilityDefine = require("BattleAbilityDefine")

local EffectiveTypeDefine = BattleAbilityDefine.EFFECTIVE_TARGET_TYPE
local POISION_CIRCLE_POST_EFF = 2
local SHIP_SHINNING_BOMB_EFF = 4

ULWatchBattleBuff.tbWatchBattleBuffs = nil

-- 是否为有效的目标状态
local function IsEffectiveTarget(self, tbTemplate)
    if tbTemplate == nil then  
        return false
    end
    local nEffectiveTargetType = tbTemplate.nEffectiveTargetType
    if nEffectiveTargetType == EffectiveTypeDefine.SHIP_AND_HUMAN then
        return true
    end
    local bIsHuman = self.Owner.tbCurrrentWatchObj:IsHuman()
    if (bIsHuman and nEffectiveTargetType == EffectiveTypeDefine.HUMAN) or
        (not bIsHuman and nEffectiveTargetType == EffectiveTypeDefine.SHIP) then
        return true
    end
    return false
end

local function GetFoundBuff(self, nInstanceId)
    for k, v in ipairs(self.tbWatchBattleBuffs) do  
        if v.nInstanceId == nInstanceId then  
            return v
        end
    end
    return nil
end

local function RemoveFoundBuff(self, nInstanceId)
    local nWillRemove = -1
    for k, v in ipairs(self.tbWatchBattleBuffs) do  
        if v.nInstanceId == nInstanceId then  
            nWillRemove = k
            break
        end
    end
    if nWillRemove ~= -1 then
        table.remove(self.tbWatchBattleBuffs, nWillRemove)
    end
end

local function OnBuffAdded(self, nInstanceId, nTemplateId, nLevel, nOverlapCount, nUpdateTime)
    local tbTemplate = BattleBuffDataTable:GetTemplate(nTemplateId)
    if not IsEffectiveTarget(self, tbTemplate)then
        return
    end
    local tbResTemplate = BattleBuffResDataTable:GetTemplate(tbTemplate.nResId)
    if not tbResTemplate then  
        return
    end
    
    if (tbResTemplate.nPostProcessEffectId == POISION_CIRCLE_POST_EFF or 
        tbResTemplate.nPostProcessEffectId == SHIP_SHINNING_BOMB_EFF) then   
        local tbBuffTemp = {}
        tbBuffTemp.nPostProcessRetId = BattleAbilitySystem:PlayPostProcessEffect(self.Owner.tbCurrrentWatchObj, tbResTemplate.nPostProcessEffectId)
        tbBuffTemp.nInstanceId = nInstanceId
        tbBuffTemp.tbTemplate = tbTemplate
        table.insert(self.tbWatchBattleBuffs, tbBuffTemp) 
    end

    -- local PlayerSelf = GamePlayerSelfHelper:Get()
    -- logdebug("on watch math buff OnBuffAdded:", PlayerSelf.nServerInstanceId, nInstanceId, nTemplateId)
end

local function OnBuffUpdated(self, nInstanceId, nOverlapCount, nUpdateTime)

    local tbWatchBuff = GetFoundBuff(self, nInstanceId)
    if tbWatchBuff then   
        -- local PlayerSelf = GamePlayerSelfHelper:Get()
        -- logdebug("on watch math buff OnBuffUpdated:", PlayerSelf.nServerInstanceId, nInstanceId)
        BattleAbilitySystem:UpdatePostProcessEffect(self.Owner.tbCurrrentWatchObj, tbWatchBuff.nPostProcessRetId)
    end
end

function ULWatchBattleBuff:ClearWatchBuff()
    if self.tbWatchBattleBuffs == nil then  
        return
    end
    for _, v in ipairs(self.tbWatchBattleBuffs) do   
        BattleAbilitySystem:StopPostProcessEffect(self.Owner.tbCurrrentWatchObj, v.nPostProcessRetId)
        RemoveFoundBuff(self, v.nInstanceId)
    end
end

local function OnBuffRemoved(self, nInstanceId)
    local tbWatchBuff = GetFoundBuff(self, nInstanceId)
    if tbWatchBuff then   
        BattleAbilitySystem:StopPostProcessEffect(self.Owner.tbCurrrentWatchObj, tbWatchBuff.nPostProcessRetId)
        RemoveFoundBuff(self, tbWatchBuff.nInstanceId)
    end

    -- local PlayerSelf = GamePlayerSelfHelper:Get()
    -- logdebug("on watch math buff OnBuffRemoved:", PlayerSelf.nServerInstanceId, nInstanceId )
end

function ULWatchBattleBuff:RefreshCurrentMateBuff()
    --unregister last
    local EventHelper = self.EventHelper
    local Owner = self.Owner
    if Owner.tbLastWatchObj then
        for _, v in ipairs(self.tbWatchBattleBuffs) do   
            BattleAbilitySystem:StopPostProcessEffect(Owner.tbLastWatchObj, v.nPostProcessRetId)
            RemoveFoundBuff(self, v.nInstanceId)
        end
        local BuffComponentClient = Owner.tbLastWatchObj.BuffComponentClient
        EventHelper:UnregisterLuaDelegate(BuffComponentClient.OnBuffAddDelegate, OnBuffAdded, self)
        EventHelper:UnregisterLuaDelegate(BuffComponentClient.OnBuffRemoveDelegate, OnBuffRemoved, self)
        EventHelper:UnregisterLuaDelegate(BuffComponentClient.OnBuffRefreshDelegate, OnBuffUpdated, self)
    end
   
    self.tbWatchBattleBuffs = {}
    if Owner.tbCurrrentWatchObj then
        local BuffComponentClient = Owner.tbCurrrentWatchObj.BuffComponentClient
        local tbBuffs = BuffComponentClient:GetAllBuffs()
        for _, tbBuff in pairs(tbBuffs) do
            OnBuffAdded(self, tbBuff.nInstanceId, tbBuff.nTemplateId, tbBuff.nLevel, tbBuff.nOverlapCount, tbBuff.nUpdateTime)
        end

        EventHelper:RegisterLuaDelegate(BuffComponentClient.OnBuffAddDelegate, OnBuffAdded, self)
        EventHelper:RegisterLuaDelegate(BuffComponentClient.OnBuffRemoveDelegate, OnBuffRemoved, self)
        EventHelper:RegisterLuaDelegate(BuffComponentClient.OnBuffRefreshDelegate, OnBuffUpdated, self)
    end
end

function ULWatchBattleBuff:OnLoad()
    -- bind prefab
end

function ULWatchBattleBuff:OnEnter()
    --Owner is UIWatchBattle
    --local Owner = self.Owner
end

function ULWatchBattleBuff:OnBindEvent(EventHelper)
end

function ULWatchBattleBuff:OnUnload()
    self:ClearWatchBuff()
    --unload res
end

return ULWatchBattleBuff
-----------------------------------------------------
--File Name    : BuffComponentServer.lua
--Author       : Song Fuhao
--Create Time  : 2017-09-22
--Description  : 战斗内Buff管理（Server）
-----------------------------------------------------

local luaclass = require("luaclass")
local GameComponentBaseClass = require("GameComponentBase")
local BuffComponentServer = luaclass("BuffComponentServer", GameComponentBaseClass)

-- require
local Proto = require("DungeonCommonProtoNames")
local PropName = require("PropName")
local LuaDelegate = require("LuaDelegate")
local EventManager = require("EventManager")
local CommonEventDef = require("CommonEventDef")
local SelfEventHelper = require("SelfEventHelper")
local AbilityBuffServer = require("AbilityBuffServer")
local BattleBuffDataTable = require("BattleBuffDataTable")
local BattleAbilityDefine = require("BattleAbilityDefine")
-- local NetworkManager = dynamic_require("NetworkManager")
local GameObjectSystem = dynamic_require("GameObjectSystem")
local GameObjectTypeDef = require("GameObjectTypeDef")

local TYPE_ADD = Proto.d2c_CharacterBuffChanged_EBuffChangedType.ADD
local TYPE_REMOVE = Proto.d2c_CharacterBuffChanged_EBuffChangedType.REMOVE
local TYPE_UPDATE = Proto.d2c_CharacterBuffChanged_EBuffChangedType.UPDATE

-- 用于生成全局buff唯一id使用
local nNextAvailableBuffId = 1

BuffComponentServer.tbProtoBuffs = nil  -- 用于Proto同步
BuffComponentServer.tbBuffMap = {}
BuffComponentServer.OnBuffAddDelegate = nil
BuffComponentServer.OnBuffRemoveDelegate = nil
BuffComponentServer.OnBuffRefreshDelegate = nil

local function Log(self, ...)
    log("[BuffComponentServer]", self.Owner.szName, ...)
end

local function GetInstMap(self, nBuffId, bCreateIfNotFind)
    local tbInstMap = self.tbBuffMap[nBuffId]
    if (not tbInstMap) and bCreateIfNotFind then
        tbInstMap = {}
        self.tbBuffMap[nBuffId] = tbInstMap
    end
    return tbInstMap
end

local function GetBuffNewInstanceId()
    local nInstanceId = nNextAvailableBuffId
    nNextAvailableBuffId = nNextAvailableBuffId + 1
    return nInstanceId
end

-- 检查是否存在该buff
local function IsExistBuff(self, tbBuff)
    local tbInstMap = GetInstMap(self, tbBuff.nTemplateId)
    if tbInstMap then
        return tbInstMap[tbBuff.nInstanceId]
    end
    return false
end

-- 检查是否存在互斥关系(数量不多，暂时不优化此算法)
local function CheckMutex(tbMutexsA, tbMutexsB)
    if tbMutexsA and tbMutexsB then
        for _,m in ipairs(tbMutexsA) do
            for _,n in ipairs(tbMutexsB) do
                if m == n then
                    return true
                end
            end
        end
    end
    return false
end

-- 通过互斥关系移除Buff
local function RemoveBuffByMutexs(self, tbMutexs)
    for nBuffId,v in pairs(self.tbBuffMap) do
        local tbTemplate = BattleBuffDataTable:GetTemplate(nBuffId)
        if CheckMutex(tbMutexs, tbTemplate.tbMutexs) then
            self:RemoveBuffById(nBuffId)
        end
    end
end

-- 检查是否为可以添加的对象
local function CheckAddableTargetType(self, nAddableTargetType)
    if nAddableTargetType == BattleAbilityDefine.BUFF_ADDABLE_TARGET_TYPE.SHIP_AND_HUMAN then
        return true
    else
        local bIsHuman = GameObjectSystem:IsCharacter(self.Owner) and self.Owner:IsHuman()
        if (nAddableTargetType == BattleAbilityDefine.BUFF_ADDABLE_TARGET_TYPE.HUMAN and bIsHuman) or
            (nAddableTargetType == BattleAbilityDefine.BUFF_ADDABLE_TARGET_TYPE.SHIP and not bIsHuman) 
            or (self.Owner:GetObjectType() == GameObjectTypeDef.DestructibleObject) then
            return true
        else
            return false
        end
    end
end

-- local function MulticastBuffChangeToAllClient(self, tbProtoBuff, nChangedType)
--     local d2c_CharacterBuffChanged = {
--         nOwnerInstanceId = self.Owner:GetServerInstanceId(),
--         tbBuff = tbProtoBuff,
--         BuffChangedType = nChangedType
--     }
--     NetworkManager:GetRPCNetworkProxy():Multicast(Proto.d2c_CharacterBuffChanged, d2c_CharacterBuffChanged, false)
-- end

-- 同步Buff改动（先同步至RepComponent，再发Multicast）
local function SyncBuffChanged(self, tbChangedBuff, nChangedType)
    if not GameObjectSystem:IsCharacter(self.Owner) then
        return
    end
    
    local tbProtoBuff = nil
    local nProtoBuffIndex = nil
    local nInstanceId = tbChangedBuff.nInstanceId
    for i,v in ipairs(self.tbProtoBuffs) do
        if v.instance_id == nInstanceId then
            tbProtoBuff = v
            nProtoBuffIndex = i
            break
        end
    end
    if tbProtoBuff then
        if nChangedType == TYPE_REMOVE then
            table.remove(self.tbProtoBuffs, nProtoBuffIndex)
        else
            tbProtoBuff.update_time = tbChangedBuff.nUpdateTime
            tbProtoBuff.overlap_count = tbChangedBuff.nOverlapCount
        end
    else
        tbProtoBuff = {
            instance_id = tbChangedBuff.nInstanceId,
            template_id = tbChangedBuff.nTemplateId,
            update_time = tbChangedBuff.nUpdateTime,
            overlap_count = tbChangedBuff.nOverlapCount,
            level = tbChangedBuff.nLevel
        }
        if nChangedType ~= TYPE_REMOVE then
            table.insert(self.tbProtoBuffs, tbProtoBuff)
        end
    end

    local PropComponent = self.Owner.ShipBattlePropertyComponent
    PropComponent:SetPropOriginValue(PropName.rCharacterAllBuff, {buffs = self.tbProtoBuffs})
    Log(self, "SyncBuffChanged", t2s(PropComponent:GetProp(PropName.rCharacterAllBuff)))
    -- MulticastBuffChangeToAllClient(self, tbProtoBuff, nChangedType)
end

local function UpdateBuff(self, tbBuff, nOverlapCount)
    Log(self, "UpdateBuff nBuffId, nInstanceId =", tbBuff.nTemplateId, tbBuff.nInstanceId)
    assert(not tbBuff.tbTemplate.bIndividual, "Buff illegal update. BuffTemplateId: "..tbBuff.nTemplateId)

    tbBuff:Update(nOverlapCount)

    SyncBuffChanged(self, tbBuff, TYPE_UPDATE)
    self.OnBuffRefreshDelegate:Fire(tbBuff.nTemplateId, tbBuff.tbTemplate.nTime, tbBuff.nOverlapCount, tbBuff.nLevel, tbBuff.nInstanceId)
    EventManager:OnFireEvent(CommonEventDef.EV_ON_BUFF_REFRESH, self.Owner, tbBuff.nTemplateId, tbBuff.tbTemplate.nTime, tbBuff.nOverlapCount, tbBuff.nLevel, tbBuff.nInstanceId)
    return tbBuff.nInstanceId
end

local function RemoveBuff(self, tbBuff)
    local tbInstMap = GetInstMap(self, tbBuff.nTemplateId)
    if tbInstMap and tbInstMap[tbBuff.nInstanceId] then
        tbInstMap[tbBuff.nInstanceId] = nil
        Log(self, "RemoveBuff nBuffId, nInstanceId =", tbBuff.nTemplateId, tbBuff.nInstanceId)
        SyncBuffChanged(self, tbBuff, TYPE_REMOVE)
        self.OnBuffRemoveDelegate:Fire(tbBuff.nTemplateId, tbBuff.nInstanceId)
        EventManager:OnFireEvent(CommonEventDef.EV_ON_BUFF_REMOVE, self.Owner, tbBuff.nTemplateId, tbBuff.nInstanceId)

        tbBuff:Destroy()
    end
    -- 移除该instance之后不再有此id的buff时，在tbBuffMap中移除
    if next(tbInstMap) == nil then
        self.tbBuffMap[tbBuff.nTemplateId] = nil
        Log(self, "Remove buff element in buff map, buffid =", tbBuff.nTemplateId)
    end
end

local function AddBuff(self, tbInstigator, nBuffId, nOverlapCount, nLevel)
    local nInstanceId = GetBuffNewInstanceId()
    Log(self, "AddBuff nBuffId, nInstanceId =", nBuffId, nInstanceId)

    -- create
    local tbBuff = AbilityBuffServer()
    tbBuff:Create(self, tbInstigator, nBuffId, nLevel, nInstanceId, nOverlapCount)
    self.EventHelper:RegisterLuaDelegate(tbBuff.LifeTimeEndDelegate, function() RemoveBuff(self, tbBuff) end)
    local tbInstMap = GetInstMap(self, nBuffId, true)
    tbInstMap[nInstanceId] = tbBuff

    -- notify
    SyncBuffChanged(self, tbBuff, TYPE_ADD)
    self.OnBuffAddDelegate:Fire(nBuffId, tbBuff.tbTemplate.nTime, tbBuff.nOverlapCount, tbBuff.nLevel, nInstanceId)
    EventManager:OnFireEvent(CommonEventDef.EV_ON_BUFF_ADD, self.Owner, nBuffId, tbBuff.tbTemplate.nTime, tbBuff.nOverlapCount, tbBuff.nLevel, nInstanceId)

    -- activate
    tbBuff:Activate()
    return nInstanceId
end

local function OnPawnDead(self, tbDeadObject)
    if tbDeadObject == self.Owner then
        self:RemoveAllBuff()
    end
end

local function RemoveBuffByEventTrigger(self, tbBuff)
    if IsExistBuff(self, tbBuff) then
        RemoveBuff(self, tbBuff)
    end
end

local function RemoveBuffOnSwitch(self)
    local tbToBeDeleted = {}
    for nBuffId,v in pairs(self.tbBuffMap) do
        local tbTemplate = BattleBuffDataTable:GetTemplate(nBuffId)
        local nRemoveType = tbTemplate.nRemoveTypeOnSwitch
        if nRemoveType == BattleAbilityDefine.BUFF_REMOVE_TYPE_ON_SWITCH.ALWAYS then
            table.insert(tbToBeDeleted, nBuffId)
        else
            local bIsHuman = GameObjectSystem:IsCharacter(self.Owner) and self.Owner:IsHuman()
            if (nRemoveType == BattleAbilityDefine.BUFF_REMOVE_TYPE_ON_SWITCH.SHIP_TO_HUMAN and not bIsHuman) or
               (nRemoveType == BattleAbilityDefine.BUFF_REMOVE_TYPE_ON_SWITCH.HUMAN_TO_SHIP and bIsHuman) then
                table.insert(tbToBeDeleted, nBuffId)
            end
        end
    end

    for _, v in ipairs(tbToBeDeleted) do
        self:RemoveBuffById(v)
    end
end

local function AddBuffByIdWithCauser(self, nCauserId, nBuffId, nOverlapCount, nLevel)
    local tbRealCauser = GameObjectSystem:FindByInstanceId(nCauserId)
    return self:AddBuffWithInstigator(tbRealCauser, nBuffId, nOverlapCount, nLevel)
end

function BuffComponentServer:OnCreate(Owner, tbParams)
    BuffComponentServer.super.OnCreate(self, Owner, tbParams)
    self.tbProtoBuffs = {}

    self.EventHelper = SelfEventHelper()
    self.OnBuffAddDelegate = LuaDelegate()
    self.OnBuffRemoveDelegate = LuaDelegate()
    self.OnBuffRefreshDelegate = LuaDelegate()
end

function BuffComponentServer:OnActorCreated(pUEActor)
    BuffComponentServer.super.OnActorCreated(self, pUEActor)
    local Helper = self.EventHelper
    local pUEComponent = pUEActor.AbilityComponent
    Helper:RegisterCppDelegate(pUEComponent.OnAddBuffByIdWithCauser     , self, AddBuffByIdWithCauser)
    Helper:RegisterCppDelegate(pUEComponent.OnAddBuffById               , self, self.AddBuffById)
    Helper:RegisterCppDelegate(pUEComponent.OnRemoveBuffById            , self, self.RemoveBuffById)
    Helper:RegisterCppDelegate(pUEComponent.OnRemoveBuffByGroupId       , self, self.RemoveBuffByGroupId)
    Helper:RegisterCppDelegate(pUEComponent.OnRemoveAllBuff             , self, self.RemoveAllBuff)
    Helper:RegisterEvent(CommonEventDef.EV_GAME_OBJECT_ON_PAWN_DEAD     , self, OnPawnDead)
    Helper:RegisterEvent(CommonEventDef.EV_TRIGGER_REMOVE_BUFF          , self, RemoveBuffByEventTrigger)
end

function BuffComponentServer:OnActorDestroyed(pUEActor)
    self.EventHelper:UnregisterAll()
    RemoveBuffOnSwitch(self)
    BuffComponentServer.super.OnActorDestroyed(self, pUEActor)
end

function BuffComponentServer:OnDestroy()
    self.EventHelper:UnregisterAll()
    self:RemoveAllBuff()
    BuffComponentServer.super.OnDestroy(self)
end

function BuffComponentServer:AddBuffById(nBuffId, nOverlapCount, nLevel)
    return self:AddBuffWithInstigator(nil, nBuffId, nOverlapCount, nLevel)
end

function BuffComponentServer:AddBuffWithInstigator(tbInstigator, nBuffId, nOverlapCount, nLevel)
    Log(self, "AddBuffWithInstigator tbInstigatorName, nBuffId, nOverlapCount, nLevel =", tbInstigator and tbInstigator.szName, nBuffId, nOverlapCount, nLevel)
    if self.Owner:IsDead() then
		return nil
    end

    local tbTemplate = BattleBuffDataTable:GetTemplate(nBuffId)
    if not tbTemplate then
        logerror("AddBuff failed, tbTemplate is nil, nBuffId =", nBuffId, debug.traceback())
        return nil
    end

    if not CheckAddableTargetType(self, tbTemplate.nAddableTargetType) then
        return nil
    end

    -- 移除互斥buff
    RemoveBuffByMutexs(self, tbTemplate.tbMutexs)

    local tbInstMap = GetInstMap(self, nBuffId)
    if tbInstMap == nil then
        -- 没有加过此Buff直接添加
        return AddBuff(self, tbInstigator, nBuffId, nOverlapCount, nLevel)
    else
        -- 当前身上已有此Buff
        local BUFF_INDIVIDUAL_TYPE = BattleAbilityDefine.BUFF_INDIVIDUAL_TYPE
        if tbTemplate.nIndividualType == BUFF_INDIVIDUAL_TYPE.NONE then
            -- 独立类型为空时，刷新这个buff
            local _, tbFirstBuff = next(tbInstMap)
            return UpdateBuff(self, tbFirstBuff, nOverlapCount)
        elseif tbTemplate.nIndividualType == BUFF_INDIVIDUAL_TYPE.ALL then
            -- 独立类型为总是独立时，添加个新buff
            return AddBuff(self, tbInstigator, nBuffId, nOverlapCount, nLevel)
        elseif tbTemplate.nIndividualType == BUFF_INDIVIDUAL_TYPE.BY_INSTIGATOR then
            -- 独立类型为按施加者独立时
            local bExistedBuff = nil
            for _, tbBuff in pairs(tbInstMap) do
                if tbBuff.tbInstigator == tbInstigator then
                    bExistedBuff = tbBuff
                    break
                end
            end
            if bExistedBuff then
                return UpdateBuff(self, bExistedBuff, nOverlapCount)
            else
                return AddBuff(self, tbInstigator, nBuffId, nOverlapCount, nLevel)
            end
        end
    end
end

function BuffComponentServer:RemoveBuffById(nBuffId)
    Log(self, "RemoveBuffById nBuffId =", nBuffId)
    local tbInstMap = GetInstMap(self, nBuffId)
    if tbInstMap and next(tbInstMap) then
        for k,v in pairs(tbInstMap) do
            RemoveBuff(self, v)
        end
    end
end

function BuffComponentServer:RemoveBuffByInstanceId(nBuffId, nBuffInstanceId)
    Log(self, "RemoveBuffByInstanceId nBuffId, nBuffInstanceId =", nBuffId, nBuffInstanceId)
    local tbInstMap = GetInstMap(self, nBuffId)
    if tbInstMap and next(tbInstMap) then
        local tbBuff = tbInstMap[nBuffInstanceId]
        if tbBuff then
            RemoveBuff(self, tbBuff)
        end
    end
end

function BuffComponentServer:RemoveBuffByGroupId(nGroupId)
    Log(self, "RemoveBuffByGroupId nGroupId =", nGroupId)
    for nBuffId,v in pairs(self.tbBuffMap) do
        local tbTemplate = BattleBuffDataTable:GetTemplate(nBuffId)
        if tbTemplate.nGroupId == nGroupId then
            self:RemoveBuffById(nBuffId)
        end
    end
end

function BuffComponentServer:RemoveBuffExcludeGroupId(nGroupId)
    Log(self, "RemoveBuffExcludeGroupId nGroupId =", nGroupId)
    for nBuffId,v in pairs(self.tbBuffMap) do
        local tbTemplate = BattleBuffDataTable:GetTemplate(nBuffId)
        if tbTemplate.nGroupId ~= nGroupId then
            self:RemoveBuffById(nBuffId)
        end
    end
end

function BuffComponentServer:RemoveBuffByTypeId(nTypeId)
    Log(self, "RemoveBuffByTypeId nTypeId =", nTypeId)
    for nBuffId,v in pairs(self.tbBuffMap) do
        local tbTemplate = BattleBuffDataTable:GetTemplate(nBuffId)
        if tbTemplate.nType == nTypeId then
            self:RemoveBuffById(nBuffId)
        end
    end
end

function BuffComponentServer:RemoveAllBuff()
    Log(self, "RemoveAllBuff")
    for k,_ in pairs(self.tbBuffMap) do
        self:RemoveBuffById(k)
    end
    self.tbBuffMap = {}
end

function BuffComponentServer:IsExistBuffById(nBuffId)
    local tbInstMap = GetInstMap(self, nBuffId)
    return tbInstMap and next(tbInstMap)
end

function BuffComponentServer:IsExistBuffByInstanceId(nBuffId, nBuffInstanceId)
    local tbInstMap = GetInstMap(self, nBuffId)
    if tbInstMap then
        return tbInstMap[nBuffInstanceId]
    end
    return false
end

return BuffComponentServer

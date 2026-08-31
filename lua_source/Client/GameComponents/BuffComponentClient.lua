-----------------------------------------------------
--File Name    : BuffComponentClient.lua
--Author       : Song Fuhao
--Create Time  : 2017-09-22
--Description  : 战斗内Buff管理（Client），主要是处理表现逻辑
-----------------------------------------------------

local luaclass = require("luaclass")
local GameComponentBaseClass = require("GameComponentBase")
local BuffComponentClient = luaclass("BuffComponentClient", GameComponentBaseClass)

local PropName = require("PropName")
local LuaDelegate = require("LuaDelegate")
local AbilityBuffClient = require("AbilityBuffClient")

BuffComponentClient.tbBuffMapByInstanceId = nil
BuffComponentClient.OnBuffAddDelegate = nil
BuffComponentClient.OnBuffRemoveDelegate = nil
BuffComponentClient.OnBuffRefreshDelegate = nil

local function Log(self, ...)
    log("[BuffComponentClient]", self.Owner.szName, ...)
end

local function RemoveBuff(self, nInstanceId, bImmediate)
    local tbBuff = self.tbBuffMapByInstanceId[nInstanceId]
    if tbBuff then
        local nTemplateId = tbBuff.nTemplateId
        tbBuff:Destroy(bImmediate)
        self.tbBuffMapByInstanceId[nInstanceId] = nil
        self.OnBuffRemoveDelegate:Fire(nInstanceId, nTemplateId)
        Log(self, "RemoveBuff nBuffId, nInstanceId =", nTemplateId, nInstanceId)
    end
end

local function IsBuffUpdated(tbBuff, nUpdateTime)
    return math.floor((nUpdateTime - tbBuff.nUpdateTime) * 1000) ~= 0
end

local function AddOrUpdateBuff(self, tbProtoBuff)
    local nInstanceId = tbProtoBuff.instance_id
    local nTemplateId = tbProtoBuff.template_id
    local nLevel = tbProtoBuff.level
    local nOverlapCount = tbProtoBuff.overlap_count
    local nUpdateTime = tbProtoBuff.update_time
    local tbBuff = self.tbBuffMapByInstanceId[nInstanceId]
    if tbBuff then
        if IsBuffUpdated(tbBuff, nUpdateTime) then
            tbBuff:Update(nOverlapCount, nUpdateTime)
            self.OnBuffRefreshDelegate:Fire(nInstanceId, nOverlapCount, nUpdateTime)
            Log(self, "UpdateBuff nBuffId, nInstanceId, nOverlapCount=, nUpdateTime=", nTemplateId, nInstanceId, nOverlapCount, nUpdateTime)
        end
    else
        self.tbBuffMapByInstanceId[nInstanceId] = AbilityBuffClient()
        self.tbBuffMapByInstanceId[nInstanceId]:Create(self, nInstanceId, nTemplateId, nLevel, nOverlapCount, nUpdateTime)
        self.OnBuffAddDelegate:Fire(nInstanceId, nTemplateId, nLevel, nOverlapCount, nUpdateTime)
        Log(self, "AddBuff nBuffId, nInstanceId, nLevel, nOverlapCount, nUpdateTime=", nTemplateId, nInstanceId, nLevel, nOverlapCount, nUpdateTime)
    end
end

-- 移除已过期的Buff
local function RemoveExpiredBuff(self, tbProtoBuffs)
    local function IsExistInProtoBuff(nInstanceId)
        for _, tbProtoBuff in ipairs(tbProtoBuffs) do
            if tbProtoBuff.instance_id == nInstanceId then
                return true
            end
        end
        return false
    end

    for nInstanceId, tbBuff in pairs(self.tbBuffMapByInstanceId) do
        if not IsExistInProtoBuff(nInstanceId) then
            RemoveBuff(self, nInstanceId, false)
        end
    end
end

-- @public
-- 同步角色身上的Buff，只由ShipBattlePropertyComponent调用
local function SyncBuffs(self, rCharacterAllBuff)
    local tbProtoBuffs = rCharacterAllBuff.buffs
    if tbProtoBuffs then
        Log(self, "SyncBuffs", t2s(tbProtoBuffs))
        RemoveExpiredBuff(self, tbProtoBuffs)
        for _, tbProtoBuff in ipairs(tbProtoBuffs) do
            AddOrUpdateBuff(self, tbProtoBuff)
        end
    end
end

-- @protected
-- @override
function BuffComponentClient:OnCreate(Owner, tbParams)
    BuffComponentClient.super.OnCreate(self, Owner, tbParams)
    self.tbBuffMapByInstanceId = {}
    self.OnBuffAddDelegate = LuaDelegate()
    self.OnBuffRemoveDelegate = LuaDelegate()
    self.OnBuffRefreshDelegate = LuaDelegate()
    self.Owner.ShipBattlePropertyComponent:BindPropChanged(PropName.rCharacterAllBuff, SyncBuffs, self)
end

-- @protected
-- @override
function BuffComponentClient:OnDestroy()
    self.Owner.ShipBattlePropertyComponent:UnbindPropChanged(PropName.rCharacterAllBuff, SyncBuffs, self)
    for nInstanceId, _ in pairs(self.tbBuffMapByInstanceId) do
        RemoveBuff(self, nInstanceId, true)
    end
    self.tbBuffMapByInstanceId = nil
    self.OnBuffRefreshDelegate = nil
    self.OnBuffRemoveDelegate = nil
    self.OnBuffAddDelegate = nil
    BuffComponentClient.super.OnDestroy()
end

-- @protected
-- @override
function BuffComponentClient:OnActorCreated(pUEActor)
    BuffComponentClient.super.OnActorCreated(pUEActor)
    for _, tbBuff in pairs(self.tbBuffMapByInstanceId) do
        tbBuff:StartOnSwitch()
    end
end

-- @protected
-- @override
function BuffComponentClient:OnActorDestroyed(pUEActor)
    for _, tbBuff in pairs(self.tbBuffMapByInstanceId) do
        tbBuff:StopOnSwitch()
    end
    BuffComponentClient.super.OnActorDestroyed(pUEActor)
end

-- @public
-- 获取当前角色身上所有Buff
function BuffComponentClient:GetAllBuffs()
    return self.tbBuffMapByInstanceId
end

-- @public
-- 根据BuffId判断角色身上是否有某个Buff
function BuffComponentClient:IsExistBuffById(nTargetBuffId)
    if self.tbBuffMapByInstanceId then
        for _, tbBuff in pairs(self.tbBuffMapByInstanceId) do
            if nTargetBuffId == tbBuff.nTemplateId then
                return true
            end
        end
    end
    return false
end

-- @public
-- 根据BuffInstanceId判断角色身上是否有某个Buff
function BuffComponentClient:IsExistBuffByInstanceId(nTargetInstanceId)
    if self.tbBuffMapByInstanceId then
        for nInstanceId, _ in pairs(self.tbBuffMapByInstanceId) do
            if nTargetInstanceId == nInstanceId  then
                return true
            end
        end
    end
    return false
end

return BuffComponentClient

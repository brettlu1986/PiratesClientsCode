local luaclass = require("luaclass")
local BattlePropertyComponentBase = require("BattlePropertyComponentBase")
local DestructibleObjectPropertyComponent = luaclass("DestructibleObjectPropertyComponent", BattlePropertyComponentBase)
local PropName = require("PropName")
local DestructibleObjectNewDataTable = require("DestructibleObjectNewDataTable")
local GlobalVariableSystem = dynamic_require("GlobalVariableSystem")
local GameObjectSystem = dynamic_require("GameObjectSystem")
local DelayTimer = require("DelayTimer")
local BPDamageType = require("BPDamageType")
local D2CHelper = require("D2CHelper")
local EventManager = require("EventManager")
local CommonEventDef = require("CommonEventDef")
local PropNameDestructible = require("PropNameDestructible")

local DEAD_HP = 0.001
local DESTROY_ACTOR_TIME = 0.5

--
local CALC_DAMAGE   = {
    [BPDamageType.ShipBullet]       = require("DDC_ShipBullet"),                    -- 船的子弹伤害
    -- [BPDamageType.ShipIncendiary]   = require("HDC_ShipIncendiary"),                -- 船的臼炮燃烧弹
    -- [BPDamageType.ShipFlamer]       = require("HDC_ShipFlamer"),                    -- 船的喷火器伤害
    [BPDamageType.ShipThrownItem]   = require("DDC_ShipThrownItem"),                -- 船的投掷物
    [BPDamageType.HumanGrenade]     = require("HDC_HumanGrenade"),                  -- 人的手雷伤害
    [BPDamageType.HumanThrowWeapon] = require("HDC_HumanThrowWeapon"),              -- 飞刀飞斧
}

DestructibleObjectPropertyComponent.tbTemplateData = nil
DestructibleObjectPropertyComponent.nHpId     = PropName.nDestructibleObjectHp
DestructibleObjectPropertyComponent.tbDelayHandle = nil
DestructibleObjectPropertyComponent.pTakeRadialDamage = nil

local function DestroyDelayHandle(self)
    if self.tbDelayHandle ~= nil then
        DelayTimer:ClearTimer(self.tbDelayHandle)
        self.tbDelayHandle = nil
    end
end

local function OnBreak(self)
    log("[destructible object] break")
    if GlobalVariableSystem:IsServerLogic() then
        self.Owner.pUEActor:SetBreak()
    end

    local fnDestroyActor = function()
        DestroyDelayHandle(self)
        GameObjectSystem:DestroyDestructibleObjectInGameModeByInstanceId(self.Owner.nServerInstanceId)
    end
    if self.tbDelayHandle == nil then
        self.tbDelayHandle = DelayTimer:DelayRun(fnDestroyActor, DESTROY_ACTOR_TIME)
    end
end

local function OnHpChanged(self)

end

local function HandleDamageWithType(self, nHp, nDamageType, nDamage)
    local nRate = self.tbTemplateData.tbDamageRate[nDamageType]
    if nRate ~= nil then
        nDamage = nDamage * nRate / 100
        return nDamage
    end
    return 0
end

local function HandleDamageWithMinHp(self, nHp, nDamageType, nDamage)
    if nHp < nDamage then    -- 血量大于最小值时，允许非有效伤害类型将血量扣到最小值
        nDamage = nHp
    end
    return nDamage
end

local function OnTakeRadialDamage(self, _, nActualDamage, pDamageType, _, pHitResult, _, pDamageCauser)
    local nDamageType = enumtoint(pDamageType.LuaEnum)
    log("[destructible object] OnTakeRadialDamage nActualDamage:%f, nDamageType:%d", nActualDamage, nDamageType)
    local fnCalculate = CALC_DAMAGE[nDamageType]
    if fnCalculate then
        fnCalculate(self.Owner, nActualDamage, pDamageCauser, pHitResult)
    end
end

-- 检查是否忽略伤害
local function CheckIgnoreDamage(self, nDamageType, tbCauser)
    -- 检查现在是否可以受伤
    if not GlobalVariableSystem:GetDungeonDamageEnabled() then
        return true
    end

    return false
end

-- 通知玩家受到伤害
local function NotifyTakeDamage(self, tbCauser, nDamage, nDamageType, nHp, tbDamageExtraData)
    local nWeaponTemplateId = 0
    if tbDamageExtraData and tbDamageExtraData.nWeaponTemplateId then
        nWeaponTemplateId = tbDamageExtraData.nWeaponTemplateId
    end

    local nRegionType = 0
    if tbDamageExtraData and tbDamageExtraData.nRegionType then
        nRegionType = tbDamageExtraData.nRegionType
    end
    D2CHelper:NotifyOnHitPlayer(self.Owner, tbCauser, nDamage, nDamageType, nHp, nWeaponTemplateId, nRegionType)
    EventManager:OnFireEvent(CommonEventDef.EV_ON_TAKE_DAMAGE, self.Owner, tbCauser, nDamage, nDamageType, nHp, nWeaponTemplateId, tbDamageExtraData)
end

function DestructibleObjectPropertyComponent:OnCreate(Owner, tbParams)
    -- log("create property", Owner.nTemplateId)
    self.tbTemplateData = DestructibleObjectNewDataTable:GetTemplate(Owner.nTemplateId)
    if self.tbTemplateData == nil then
        error(string.format("[destructible object] not find Destructible object data: %d", Owner.nTemplateId))
    end

    DestructibleObjectPropertyComponent.super.OnCreate(self, Owner, tbParams)

    return true
end

function DestructibleObjectPropertyComponent:OnDestroy()
    DestroyDelayHandle(self)
    self.tbTemplateData = nil
    DestructibleObjectPropertyComponent.super.OnDestroy(self)
end

function DestructibleObjectPropertyComponent:OnActorCreated(pUEActor)
    DestructibleObjectPropertyComponent.super.OnActorCreated(self, pUEActor)

    self:BindRepProperties(PropNameDestructible.GetRepIds())
    -- 可破坏物无法接受KMCharactor的事件
    self.pTakeRadialDamage = self.EventHelper:RegisterCppDelegate(pUEActor.OnTakeRadialDamage, self, OnTakeRadialDamage)
end

function DestructibleObjectPropertyComponent:OnActorDestroyed(pUEActor)
    if self.pTakeRadialDamage ~= nil then
        self.EventHelper:UnregisterCppDelegate(self.pTakeRadialDamage)
        self.pTakeRadialDamage = nil
    end
    DestructibleObjectPropertyComponent.super.OnActorDestroyed(self, pUEActor)
end

function DestructibleObjectPropertyComponent:DefineProperties(fnDefine, tbParams)
    local nDefaultMaxHp = self:GetDefaultMaxHp()
    fnDefine(self, self.nHpId           , nDefaultMaxHp     , OnHpChanged)      -- 血量
end

function DestructibleObjectPropertyComponent:GetDefaultMaxHp()
    return self.tbTemplateData.nMaxHp
end

function DestructibleObjectPropertyComponent:GetIsDead()
    return self:GetProp(self.nHpId) <= 0
end

function DestructibleObjectPropertyComponent:ApplyDamage(tbCauser, nDamageType, nDamage, tbDamageExtraData)
    assert(GlobalVariableSystem:IsServerLogic(), "[destructible object] DestructibleObject ApplyDamage is a server only function.")
    assert(nDamage >= 0)

    local nHp = self:GetHp()
    if CheckIgnoreDamage(self, nDamageType) then
        -- 伤害被免疫时也发通知
        local nNotifyDamage = 0
        if GlobalVariableSystem:IsNotifyDamageWhenIgnoreDamage() then
            nNotifyDamage = nDamage
        end

        NotifyTakeDamage(self, tbCauser, nNotifyDamage, nDamageType, nHp, tbDamageExtraData)
    else
        nDamage = HandleDamageWithType(self, nHp, nDamageType, nDamage)
        nDamage = HandleDamageWithMinHp(self, nHp, nDamageType, nDamage)
        NotifyTakeDamage(self, tbCauser, nDamage, nDamageType, nHp, tbDamageExtraData)
        nHp = nHp - nDamage
        self:SetPropOriginValue(self.nHpId, nHp)
        if nHp <= DEAD_HP then
            OnBreak(self)
        end
    end
end

function DestructibleObjectPropertyComponent:OnResetBattleProperties()
    -- self:SetPropOriginValue(self.nHpId, self:GetMaxHp())
end

return DestructibleObjectPropertyComponent
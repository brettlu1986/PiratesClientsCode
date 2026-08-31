local luaclass = require("luaclass")
local AgentStatistics = luaclass("AgentStatistics")
local SelfEventHelperClass  = require("SelfEventHelper")
local AgentStatisticsDef    = require("AgentStatisticsDef")
local CommonEventDef        = require("CommonEventDef")
local DamageTypeEx          = require("DamageTypeEx")

AgentStatistics.SelfEventHelper = nil
AgentStatistics.tbProperties = nil
AgentStatistics.tbOwner = nil
AgentStatistics.nLastWeaponDamagedType = nil
AgentStatistics.nLastWeaponDamagedTime = 0
AgentStatistics.nLastDamagedType = nil

-- luacheck: push ignore
local function LOG(...)
    log("CJ->AgentStatistics:", ...)
end
-- luacheck: pop

local function Register(self, nProperty)
    self.tbProperties[nProperty] = 0
end

local function OnTookDamage(self, tbTaker, tbCauser, nDamage, nDamageType)
    if tbCauser == self.tbOwner and tbTaker and nDamage and nDamage > 0 then
        nDamage = math.floor(nDamage)
        self:AddProperty(AgentStatisticsDef.DAMAGE, nDamage)
        if nDamageType ~= DamageTypeEx.SHIP_FIRING
            and nDamageType ~= DamageTypeEx.SHIP_LEAKING
            and nDamageType ~= DamageTypeEx.HUMAN_FIREBOMB then
                self:AddProperty(AgentStatisticsDef.DAMAGE_COUNT, 1)
        end
    elseif tbTaker == self.tbOwner then
        self.nLastDamagedType = nDamageType
        if DamageTypeEx.IsCausedByShip(nDamageType) or DamageTypeEx.IsCausedByHuman(nDamageType) then
            self.nLastWeaponDamagedType = nDamageType
            self.nLastWeaponDamagedTime = os.time()
        end
    end
end

local function OnPawnDead(self, tbDead, tbCauser)
    if tbCauser == self.tbOwner and tbDead then
        self:AddProperty(AgentStatisticsDef.KILL, 1)
    end
end

function AgentStatistics:Init(tbGameObject)
    self.tbOwner = tbGameObject
    self.tbProperties = { }
    self.SelfEventHelper = SelfEventHelperClass()
    self.nLastWeaponDamagedTime = 0
    local nMax = AgentStatisticsDef.Max()
    for i=1,nMax do
        Register(self, i)
    end
    local SelfEventHelper = self.SelfEventHelper
    SelfEventHelper:RegisterEvent(CommonEventDef.EV_GAME_OBJECT_ON_PAWN_PRE_DEAD, self, OnPawnDead)
    SelfEventHelper:RegisterEvent(CommonEventDef.EV_ON_TAKE_DAMAGE, self, OnTookDamage)
end

function AgentStatistics:Clear()
    for k, v in pairs(self.tbProperties) do
        self.tbProperties[k] = 0
    end
end

function AgentStatistics:AddProperty(nProperty, nNum)
    if self.tbProperties[nProperty] then
        self.tbProperties[nProperty] = self.tbProperties[nProperty] + nNum
        --LOG("add property ", nProperty , " ", nNum)
    else
        logerror("try to add a invalid property of AgentStatistics ", nProperty)
    end
end

function AgentStatistics:GetProperty(nProperty)
    if self.tbProperties[nProperty] then
        return self.tbProperties[nProperty]
    end
    logerror("try to get invalid property of AgentStatistics ", nProperty)
end

function AgentStatistics:ClearProperty(nProperty)
    if self.tbProperties[nProperty] then
        self.tbProperties[nProperty] = 0
    else
        logerror("try to add a invalid property of AgentStatistics ", nProperty)
    end
end

function AgentStatistics:IsDamagedInSeconds(nTime)
    return os.time() - self.nLastWeaponDamagedTime <= nTime
end

function AgentStatistics:Uinit()
    self:Clear()
    self.SelfEventHelper:UnregisterAll()
end

return AgentStatistics
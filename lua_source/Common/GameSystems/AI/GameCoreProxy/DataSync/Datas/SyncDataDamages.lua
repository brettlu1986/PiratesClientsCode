local luaclass = require("luaclass")
local SyncDataBase = require("SyncDataBase")
local SyncDataDamages = luaclass("SyncDataDamages", SyncDataBase)
local DamageTypeEx = require("DamageTypeEx")
local CommonEventDef = require("CommonEventDef")

SyncDataDamages.tbDamageCauserLocation = nil
SyncDataDamages.nDamageType = 0
SyncDataDamages.nLastTime = 0
SyncDataDamages.nLastHitDamageActorId = 0
SyncDataDamages.tbDamageRegionCount = nil

local nMaxRemenberTime = 5 * 10

local ACTOR_TYPE = {
    HUMAN = 1,
    SHIP = 2,
    NUM = 2,
}

-- luacheck: push ignore
local function LOG(...)
    log("CJ->SyncDataDamages:", ...)
end

-- luacheck: pop

function SyncDataDamages:OnSync(tbPack)
    if self.nDamageType ~= DamageTypeEx.UNKNOWN then
        tbPack.took_damage = tbPack.took_damage or {}
        tbPack.took_damage.position = self.tbDamageCauserLocation
        tbPack.took_damage.type = self.nDamageType
        self.nLastTime = self.nLastTime - 1
        if self.nLastTime <= 0 then
            self.nDamageType = DamageTypeEx.UNKNOWN
        end
    else
        tbPack.took_damage = nil
    end
    tbPack.last_damaged_actor_id = self.nLastHitDamageActorId
    local nActorType = self:GetActorType()
    tbPack.make_damage = tbPack.make_damage or {}
    tbPack.make_damage.damage_regions = self.tbDamageRegionCount[nActorType]
end

function SyncDataDamages:GetActorType()
    if self.tbOwner:IsHuman() then
        return ACTOR_TYPE.HUMAN
    end
    return ACTOR_TYPE.SHIP
end

function SyncDataDamages:OnTookDamage(tbTaker, tbCauser, nDamage, nDamageType, nHp, nWeaponTemplateId, tbDamageExtraData)
    if tbTaker == self.tbOwner and tbCauser and tbCauser.nServerInstanceId then
        local nX, nY, nZ = tbCauser:GetLocationXYZ()
        self.tbDamageCauserLocation.x = nX
        self.tbDamageCauserLocation.y = nY
        self.tbDamageCauserLocation.z = nZ
        self.nDamageType = nDamageType
        self.nLastTime = nMaxRemenberTime
    elseif tbCauser == self.tbOwner and tbTaker.nServerInstanceId then
        self.nLastHitDamageActorId = tbTaker.nServerInstanceId
        if tbDamageExtraData and tbDamageExtraData.nRegionType then
            local nActorType = self:GetActorType()
            local tbDamageRegionCount = self.tbDamageRegionCount[nActorType]
            local nRegionType = tbDamageExtraData.nRegionType
            local bFound = false
            for i,v in ipairs(tbDamageRegionCount) do
                if v.id == nRegionType then
                    v.count = v.count + 1
                    bFound = true
                    break
                end
            end
            if not bFound then
                local tbNewRegion = {
                    id = nRegionType,
                    count = 1,
                }
                table.insert(tbDamageRegionCount, tbNewRegion)
            end
        end
    end
end

function SyncDataDamages:BindEvent(SelfEventHelper)
    SelfEventHelper:RegisterEvent(CommonEventDef.EV_ON_TAKE_DAMAGE, self, self.OnTookDamage)

end

function SyncDataDamages:UnbindEvent(SelfEventHelper)
    SelfEventHelper:UnregisterAll()
end


function SyncDataDamages:OnStart()
    self.tbDamageCauserLocation = {}
    self.nDamageType = DamageTypeEx.UNKNOWN
    self.tbDamageRegionCount = {}
    for i=1,ACTOR_TYPE.NUM do
        self.tbDamageRegionCount[i] = {}
    end
end


function SyncDataDamages:OnStop()

end

return SyncDataDamages
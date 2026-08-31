local luaclass = require("luaclass")
local HumanWeaponInstant = require("HumanWeaponInstant")
local HumanWeaponInstant_C = luaclass("HumanWeaponInstant_C", HumanWeaponInstant)

local HumanWeaponHelper = require("HumanWeaponHelper")
local GameObjectSystem = dynamic_require("GameObjectSystem")
local PropName = require("PropName")

local tbTemp1 = {}
local tbTemp2 = {}
local tbTempAttckOncePacket = {}

local function CopyVector(Dest, From)
    Dest.X = From.X
    Dest.Y = From.Y
    Dest.Z = From.Z
end

local function VectorToTempTable1(Vector)
    CopyVector(tbTemp1, Vector)
    return tbTemp1
end

local function VectorToTempTable2(Vector)
    CopyVector(tbTemp2, Vector)
    return tbTemp2
end

local function VectorToNewTable(Vector)
    return {
        X = Vector.X,
        Y = Vector.Y,
        Z = Vector.Z
    }
end

local function AttackOnce(self, tbProperty)
    local pWeaponActor = self.pWeaponActor
    local StartPos, EndPos, _ShotDir, pHitResult, bHit = pWeaponActor:CalculateHit()
    StartPos = VectorToTempTable1(StartPos)

    local Taker
    if(bHit) then
        Taker = GameObjectSystem:FindByUEActor(pHitResult.Actor)
        bHit = Taker ~= nil
        if not HumanWeaponHelper.CanBeAttacked(Taker) or Taker and Taker:IsDead() then   
            bHit = false
        end 
    end
    EndPos = VectorToTempTable2(EndPos)
    if(bHit) then
        local nTakerId = Taker:GetServerInstanceId()
        -- local TempEndPos = VectorToTempTable2(pHitResult.ImpactPoint)
        local nHitBodyType = HumanWeaponHelper.GetHitBodyType(pHitResult)

        if(self.bServer) then
            -- 单机逻辑
            self:AttackOnceInServer(nTakerId, StartPos, EndPos, nHitBodyType)
        else
            HumanWeaponHelper.SendGunAttackOnceRequest(self.nInstanceId, nTakerId, StartPos, EndPos, nHitBodyType)
        end
    else
        if(not self.bServer) then
            HumanWeaponHelper.SendGunAttackRoute(self.nInstanceId, StartPos, EndPos, false)
        else
            self:DecreaseAmmo(self:GetOwnerProperty(PropName.nBulletCostPerAttack))
        end

        -- 本地播命中特效
        tbTempAttckOncePacket[1] = EndPos
        self:OnHitNotifies(StartPos, tbTempAttckOncePacket)
    end
end

local function AttackMulti(self, tbProperty, nAttackCount)
    local pWeaponActor = self.pWeaponActor
    local nWeaponInstanceId = self.nInstanceId

-- luacheck: push ignore 231

    local StartPos, TempStartPos, EndPos, ShotDir, pHitResult, bHit, Taker
    local tbHitTakers = {}
    local tbHitEnds = {}
    local tbHitTypes = {}
    local tbMissEnds = {}

    for i=1, nAttackCount do
        TempStartPos, EndPos, ShotDir, pHitResult, bHit = pWeaponActor:CalculateHit()
        if(StartPos == nil) then
            StartPos = VectorToTempTable1(TempStartPos)
        end

        if(bHit) then
            if pHitResult.Actor then 
                Taker = GameObjectSystem:FindByUEActor(pHitResult.Actor)
                if not HumanWeaponHelper.CanBeAttacked(Taker) or Taker and Taker:IsDead() then   
                    bHit = false
                end 
            else
                bHit = false
            end
        end

        if(bHit) then
            table.insert(tbHitTakers, Taker:GetServerInstanceId())
            table.insert(tbHitEnds, VectorToNewTable(EndPos))
            table.insert(tbHitTypes, HumanWeaponHelper.GetHitBodyType(pHitResult))
        else
            table.insert(tbMissEnds, VectorToNewTable(EndPos))
        end
    end

    if(#tbHitTakers > 0) then
        -- 击中的
        HumanWeaponHelper.SendGunAttackMultiRequest(nWeaponInstanceId, tbHitTakers, StartPos, tbHitEnds, tbHitTypes, tbMissEnds)

        if(self.bServer) then
            -- 单机逻辑
            self:AttackMultiInServer(tbHitTakers, StartPos, tbHitEnds, tbHitTypes, tbMissEnds)
        end
    else
        -- 转发未击中的
        if(not self.bServer) then
            HumanWeaponHelper.SendGunAttackRoute(nWeaponInstanceId, StartPos, tbMissEnds, true)
        else
            self:DecreaseAmmo(self:GetOwnerProperty(PropName.nBulletCostPerAttack))
        end
    end

    if(#tbMissEnds > 0) then
        -- 本地播命中特效
        self:OnHitNotifies(StartPos, tbMissEnds)
    end

-- luacheck: pop
end

function HumanWeaponInstant_C:AttackInClient(tbAttackInfo)
    HumanWeaponInstant_C.super.AttackInClient(self, tbAttackInfo)

    local tbProperty = self:GetProperty()
    local nAttackCount = self:GetOwnerProperty(PropName.nBulletCostPerAttack) * self:GetOwnerProperty(PropName.nBulletCountPerAttack)

    if(nAttackCount > 1) then
        AttackMulti(self, tbProperty, nAttackCount)
    else
        AttackOnce(self, tbProperty)
    end
    self:ShakeCamera()
end

function HumanWeaponInstant_C:OnHitNotifies(StartPos, tbAttackEnds, tbTackers, tbDamageTypes)
    local pWeaponActor = self.pWeaponActor
    pWeaponActor.BulletRange = self:GetOwnerProperty(PropName.nAttackRegion)*100

    HumanWeaponInstant_C.super.OnHitNotifies(self, StartPos, tbAttackEnds, tbTackers, tbDamageTypes)
end

return HumanWeaponInstant_C
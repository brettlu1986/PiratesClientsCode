local luaclass = require("luaclass")
local HumanWeaponWand = require("HumanWeaponWand")
local HumanWeaponWand_C = luaclass("HumanWeaponWand_C", HumanWeaponWand)
local GameObjectSystem = dynamic_require("GameObjectSystem")
local HumanWeaponHelper = require("HumanWeaponHelper")
local AutoBattleSystem = require("AutoBattleSystem")
local HumanWeaponHitEffectHelper = require("HumanWeaponHitEffectHelper")

local tbTemp1 = {}
local tbTemp2 = {}
local pTempVector1 = Vector()
local pTempVector2 = Vector()
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

local function TableToTempVector1(tbVector)
    CopyVector(pTempVector1, tbVector)
    return pTempVector1
end

local function TableToTempVector2(tbVector)
    CopyVector(pTempVector2, tbVector)
    return pTempVector2
end

function HumanWeaponWand_C:OnHitActor(StartPos, HitDir, pHitResult, nProjectileIndex)
    local Dir = VectorToTempTable2(HitDir)

    local tbTakerIds,tbHitEnds = self:GetTakerIdsAndHitEnds(StartPos, Dir)

    -- 播放击中动画
    -- if tbTakerIds then
        -- for _, nTakerId in pairs(tbTakerIds) do
            -- local tbTaker = GameObjectSystem:FindByInstanceId(nTakerId)
            -- self:PlayHitAnimation(tbTaker)
        -- end
    -- end

    self:OnHitNotifies(StartPos, HitDir)

    VectorToTempTable1(StartPos)
    if(tbTakerIds) then
        local nWeaponInstanceId = self.nInstanceId
        if(self.bServer) then
            -- 单机逻辑
            self:AttackMultiInServer(tbTakerIds, StartPos, tbHitEnds, nil--[[tbHitBodyTypes]], nil--[[tbMissEnds]], nil--[[tbOriginalHitTypes]], {nProjectileIndex})
        else 
            HumanWeaponHelper.SendGunAttackMultiRequest(nWeaponInstanceId, tbTakerIds, tbTemp1, tbHitEnds, nil--[[tbHitBodyTypes]], nil--[[tbMissEnds]], {nProjectileIndex})
        end        
    else 
        if(not self.bServer) then
            HumanWeaponHelper.SendProjectAttackRoute(self.nInstanceId, tbTemp1, Dir, false, {nProjectileIndex})
        end

    end
end

function HumanWeaponWand_C:OnRepGunAttackOnceResult(tbRepData)
end

function HumanWeaponWand_C:OnRepGunAttackMultiResult(tbRepData)
    if(tbRepData == nil) then
        return
    end
    if(not self.bSelf or AutoBattleSystem:InAutoBattle()) then
        -- 自己已经播过了
        self:PlayAttackMontage()
        self.pWeaponActor:PlayAttackEffect()
    end    
    local Dir = tbRepData.hit_ends[1]
    if not Dir then  
        return 
    end 
    if(not self.bSelf) then
        self:OnHitNotifies(TableToTempVector2(tbRepData.start), TableToTempVector1(Dir))
    end
end

function HumanWeaponWand_C:OnRepPorjectGunAttackRoute(tbRepData)
    if(tbRepData == nil) then
        return
    end

    local Dir = tbRepData.ends[1]
    if not Dir then  
        return 
    end 
    self:OnHitNotifies(TableToTempVector2(tbRepData.start), TableToTempVector1(Dir))
end


function HumanWeaponWand_C:OnHitNotifies(StartPos, Dir)
    local pWeaponActor = self.pWeaponActor
    local OnHitNotify = pWeaponActor.OnHitNotify
    local pHitPlayer, pHitResult = OnHitNotify(pWeaponActor, StartPos, Dir)

    if pHitPlayer then
        local nUniqueID = ExtendBlueprintFunctions.GetObjectUniqueID(pHitPlayer)
        local tbObject = GameObjectSystem:FindByUniqueId(nUniqueID)
        local nHumanBodyDef = HumanWeaponHelper.GetHitBodyType(pHitResult)
        HumanWeaponHitEffectHelper:PlayHitEffectAndSound(tbObject, nHumanBodyDef, self.nTemplateId, pHitResult)
    end

end

function HumanWeaponWand_C:AmmoCheck()
end

return HumanWeaponWand_C
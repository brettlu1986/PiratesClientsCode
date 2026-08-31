local HumanWeaponHitEffectHelper = {}

local BattleHumanEffectDataTable = require("BattleHumanEffectDataTable")
local BattleAbilitySystem = require("BattleAbilitySystem")
local GameObjectTypeDef = require("GameObjectTypeDef")
local HumanWeaponHelper = require("HumanWeaponHelper")
local SoundEffectData = require("SoundEffectData")
local PropName = require("PropName")

local function GetHumanArmorId(tbPlayer)
    local HumanBattlePropertyComponent = tbPlayer.HumanBattlePropertyComponent
    if HumanBattlePropertyComponent then
        local nCurrentArmorTemplatedId = tbPlayer.HumanBattlePropertyComponent:GetProp(PropName.nCurrentArmorTemplateId)
        if nCurrentArmorTemplatedId < 0 then
            return 0
        end
        return nCurrentArmorTemplatedId
    end
    return 0
end

function HumanWeaponHitEffectHelper:PlayHitEffectAndSound(tbPlayer, nHumanBodyDef, nHumanWeaponTemplateId, pHitResult, nDamageFactor)
    if not tbPlayer or (tbPlayer.ObjectType ~= GameObjectTypeDef.PlayerSelf and tbPlayer.ObjectType ~= GameObjectTypeDef.PlayerOther and tbPlayer.ObjectType ~= GameObjectTypeDef.Npc) or
       not tbPlayer:IsHuman() then
        return
    end

    local szDefaultType = "Body"
    local pReleationLocation = HumanWeaponHelper.GetLocationByHitType(tbPlayer.pUEActor, szDefaultType)
    local X = pReleationLocation.X
    local Y = pReleationLocation.Y
    local Z = pReleationLocation.Z

    --local X, Y, Z = EngineExtActorShell.GetActorLocationXYZ(tbPlayer.pUEActor)

    if pHitResult then
        local pImpactPoint = pHitResult.ImpactPoint
        X = pImpactPoint.X
        Y = pImpactPoint.Y
        Z = pImpactPoint.Z
    end

    local nArmorId = GetHumanArmorId(tbPlayer)
    local bThump = (nDamageFactor and nDamageFactor > 1)
    local bSelfIsTaker = (tbPlayer.ObjectType == GameObjectTypeDef.PlayerSelf)
    local nEmitterId, nSoundId, fVolume = BattleHumanEffectDataTable:GetEffectId(nArmorId, nHumanWeaponTemplateId, nHumanBodyDef, bThump, bSelfIsTaker)
    --log("HumanWeaponHitEffectHelper:PlayHitEffectAndSound: ",tbPlayer.szName, nArmorId, nHumanBodyDef, nHumanWeaponTemplateId, nEmitterId, nSoundId)
    if nEmitterId and nEmitterId > 0 then
        local tbParams = {}
        tbParams.Location = {}
        tbParams.Location.X = X
        tbParams.Location.Y = Y
        tbParams.Location.Z = Z

        BattleAbilitySystem:PlayParticleEffect(tbPlayer, nEmitterId, nil, tbParams)
    end

    if nSoundId and nSoundId > 0 then
        local szSoundPath = SoundEffectData:GetSoundPath(nSoundId)
        if szSoundPath then
            BattleAbilitySystem:PlaySound(tbPlayer, szSoundPath, nil, true, nil, nil, nil, fVolume)
        end
    end
end

return HumanWeaponHitEffectHelper
local BattleNpcHelper = {}

local GameObjectTypeDef = require("GameObjectTypeDef")
local CampDef = require("CampDefine")
local SpawnerDef = require("SpawnerDef")

local pTempVector = Vector()

function BattleNpcHelper:CheckIdentifier(tbIdentifier, Npc, bSpawner)
    if(Npc == nil) then
        return false
    end

    if bSpawner then
        if Npc.nSpawnerType & SpawnerDef.SpawnerType.ALL_NPC <= 0 then
        -- if Npc.nSpawnerType ~= SpawnerDef.SpawnerType.NPC then
            return false
        end
    elseif Npc.ObjectType ~= GameObjectTypeDef.Npc then
        return false
    end

    local nCampType = tbIdentifier.nCampType
    if(nCampType ~= nil and nCampType ~= CampDef.Type.CAMP_NONE) then
        if(Npc.BattleCampComponent ~= nil
            and nCampType ~= Npc.BattleCampComponent:GetCampType()) then
            return false
        end

        if(Npc.nCampType ~= nil and Npc.nCampType ~= nCampType) then
            return false
        end
    end

    local bRet = true

    local nTemplateId = tbIdentifier.nTemplateId
    if(nTemplateId ~= nil) then
        bRet = bRet and nTemplateId == Npc.nTemplateId
    end


    local szTag = tbIdentifier.szTag
    if(szTag ~= nil) then
        bRet = bRet and szTag == Npc.szTag
    end

    local nGroupIndex = tbIdentifier.nGroupIndex
    if(nGroupIndex ~= nil) then
        bRet = bRet and nGroupIndex == Npc.nGroupIndex
    end

    local nSubGroupIndex = tbIdentifier.nSubGroupIndex
    if(nSubGroupIndex ~= nil) then
        bRet = bRet and nSubGroupIndex == Npc.nSubGroupIndex
    end
    return bRet
end

function BattleNpcHelper:ParseIdentifier(tbIdentifier, tbJsonData)
    tbIdentifier.nCampType = tbJsonData.CampType
    tbIdentifier.nTemplateId = tbJsonData.TemplateId
    tbIdentifier.szTag = tbJsonData.Tag
    tbIdentifier.nGroupIndex = tbJsonData.Group
    tbIdentifier.nSubGroupIndex = tbJsonData.SubGroup
end

function BattleNpcHelper:GetIdentifierInfo(tbIdentifier)
    local szRet = ""
    local nCampType = tbIdentifier.nCampType
    if(nCampType ~= nil and nCampType ~= CampDef.Type.CAMP_NONE) then
        szRet = szRet.."CampType: "..nCampType..", "
    end

    local nTemplateId = tbIdentifier.nTemplateId
    if(nTemplateId ~= nil) then
        szRet = szRet.."TemplateId: "..nTemplateId..", "
    end

    local szTag = tbIdentifier.szTag
    if(szTag ~= nil) then
        szRet = szRet.."Tag: "..szTag..","
    end

    local nGroupIndex = tbIdentifier.nGroupIndex
    if(nGroupIndex ~= nil) then
        szRet = szRet.."GroupIndex: "..nGroupIndex..","
    end

    local nSubGroupIndex = tbIdentifier.nSubGroupIndex
    if(nSubGroupIndex ~= nil) then
        szRet = szRet.."nSubGroupIndex: "..nSubGroupIndex..","
    end
    return szRet
end

function BattleNpcHelper:Teleport(tbNpc, tbTransform, bResetMovement)
    assert(tbNpc)
    assert(tbNpc.pUEActor)
    assert(tbTransform)
    pTempVector.X = tbTransform.X ~= nil and tbTransform.X or 0
    pTempVector.Y = tbTransform.Y ~= nil and tbTransform.Y or 0
    pTempVector.Z = tbTransform.Z ~= nil and tbTransform.Z or 0
    local nYaw = tbTransform.Yaw ~= nil and tbTransform.Yaw or 0
    bResetMovement = bResetMovement == nil or bResetMovement

    if (tbNpc:IsShip()) then
        local pShipMovementComponent = tbNpc.pUEActor.ShipMovementComponent
        assert(isvalidhandle(pShipMovementComponent))
        pShipMovementComponent:TeleportShip(pTempVector, nYaw, bResetMovement)
    else
        local pCharacterMovement = tbNpc.pUEActor.CharacterMovement
        assert(isvalidhandle(pCharacterMovement))
        pCharacterMovement:TeleportHuman(pTempVector, nYaw, bResetMovement, true)
    end
end

return BattleNpcHelper
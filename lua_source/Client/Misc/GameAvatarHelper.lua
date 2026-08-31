local GameAvatarHelper = {}

local ShipDataTable = require("ShipDataTable")
local HumanWeaponAvatarResPartDef = require("HumanWeaponAvatarResPartDef")

local tbShipResMap = {}
tbShipResMap.flag1 = "ShipFlag1"
tbShipResMap.flag2 = "ShipFlag2"
tbShipResMap.flag3 = "ShipFlag3"
tbShipResMap.sail = "ShipSail"
tbShipResMap.camouflage = "ShipBody"
tbShipResMap.figurehead = "ShipFigureHead"
tbShipResMap.light = "ShipLight"
tbShipResMap.anchor = "ShipAnchor"
tbShipResMap.sail_pattern = "ShipSailPattern"
tbShipResMap.armor = "ShipArmor"
tbShipResMap.captain_cabin = "ShipCaptainCabin"




local tbShipTemplateResMap = {}
tbShipTemplateResMap.flag1 = "nFlag1"
tbShipTemplateResMap.flag2 = "nFlag2"
tbShipTemplateResMap.flag3 = "nFlag3"
tbShipTemplateResMap.sail = "nSail"
tbShipTemplateResMap.camouflage = "nBody"
tbShipTemplateResMap.figurehead = "nFigureHead"
tbShipTemplateResMap.light = "nLight"
tbShipTemplateResMap.anchor = "nAnchor"
tbShipTemplateResMap.sail_pattern = "nSailPattern"


function GameAvatarHelper:ConvertServerShipRes(szKey)
    return tbShipResMap[szKey]
end

-- proto key
local function CollectTemplateRes(tbResData, tbTResMap, tbTResData)
    local nResData, nTempResData
    if(tbTResData) then
        for szKey, szPartIdName in pairs(tbTResMap) do
            if(tbResData) then
                nResData = tbResData[szKey]
            else
                nResData = nil
            end
            if(nResData == nil or nResData <= 0) then
                nTempResData = tbTResData[szPartIdName]
                if(nTempResData > 0) then
                    if(tbResData == nil) then
                        tbResData = {}
                    end
                    tbResData[szKey] = nTempResData
                end
            end
        end
    end
    return tbResData
end

local function UpdateAvatarData(pAvatarComponent, tbResMap, tbResData, tbAvatarExtraConfigs)
    if(pAvatarComponent == nil or tbResData == nil) then
        return false
    end

    local nValue
    for szKey, szPartName in pairs(tbResMap) do
        if(tbResData) then
            nValue = tbResData[szKey]
        else
            nValue = nil
        end
        if(nValue ~= nil and nValue > 0) then
            if tbAvatarExtraConfigs and tbAvatarExtraConfigs[szPartName] ~= nil then
                local tbConfig = tbAvatarExtraConfigs[szPartName]
                pAvatarComponent:AddPartByName(szPartName, nValue, false, tbConfig.nPriority, tbConfig.bMerged)
            else
                pAvatarComponent:AddPartByName(szPartName, nValue, false, 0, true)
            end
        else
            pAvatarComponent:RemovePartByName(szPartName, false)
        end
    end

    pAvatarComponent:CommitAsync()
    return true
end

function GameAvatarHelper:UpdateShipAvatar(pAvatarComponent, tbResData, nShipTemplateId, tbTResData)
    if(tbTResData == nil) then
        local tbTData = ShipDataTable:GetTemplate(nShipTemplateId)
        tbTResData = tbTData and tbTData.tbResData
    end
    tbResData = CollectTemplateRes(tbResData, tbShipTemplateResMap, tbTResData)
    return UpdateAvatarData(pAvatarComponent, tbShipResMap, tbResData)
end




--------------------------Human Weapon Avatar---------------------------


local tbWeaponResMap = {}
tbWeaponResMap[HumanWeaponAvatarResPartDef.Muzzle] = "WeaponMuzzle"
tbWeaponResMap[HumanWeaponAvatarResPartDef.HandGuard] = "WeaponHandGuard"
tbWeaponResMap[HumanWeaponAvatarResPartDef.Sight] = "WeaponSight"
tbWeaponResMap[HumanWeaponAvatarResPartDef.Stock] = "WeaponStock"
tbWeaponResMap[HumanWeaponAvatarResPartDef.Magazine] = "WeaponMagazine"
tbWeaponResMap[HumanWeaponAvatarResPartDef.Trunk]   = "WeaponTrunk"




function GameAvatarHelper.UpdateWeaponAvatar(pAvatarComponent, tbResData)
    return UpdateAvatarData(pAvatarComponent, tbWeaponResMap, tbResData)
end

------------------------------Human Avatar------------------------------

local HumanAvatarDef        = require("HumanAvatarDef")
local AvatarColorDataTable  = require("AvatarColorDataTable")

local HumanPartName = HumanAvatarDef.PartName
local ProtoFieldName = HumanAvatarDef.ProtoFieldName
local ProtoFieldNameToPartName = HumanAvatarDef.ProtoFieldNameToPartName
local tbHumanAvatarExtraConfigs = {}
tbHumanAvatarExtraConfigs[HumanPartName.Hat]       =  {nPriority = 1, bMerged = false}
tbHumanAvatarExtraConfigs[HumanPartName.Hair]      =  {nPriority = 1, bMerged = false}
tbHumanAvatarExtraConfigs[HumanPartName.Head]      =  {nPriority = 1, bMerged = false}
tbHumanAvatarExtraConfigs[HumanPartName.Upper]     =  {nPriority = 1, bMerged = false}
tbHumanAvatarExtraConfigs[HumanPartName.Lower]     =  {nPriority = 1, bMerged = false}
tbHumanAvatarExtraConfigs[HumanPartName.Shoe]      =  {nPriority = 1, bMerged = false}



local function GetHumanAvatarExtraConfigs()
    return tbHumanAvatarExtraConfigs
end


function GameAvatarHelper.UpdateHumanAvatar(pAvatarComponent, tbResData)
    if(pAvatarComponent == nil or tbResData == nil) then
        return false
    end
    local nHairColor = tbResData[ProtoFieldName.HairColor]
    if nHairColor and nHairColor > 0 then
        local tbColorTemplate = AvatarColorDataTable:GetTemplate(nHairColor)
        pAvatarComponent:SetHairColor(tbColorTemplate.nRed,tbColorTemplate.nGreen, tbColorTemplate.nBlue, false)
    end
    local nSkinColor = tbResData[ProtoFieldName.SkinColor]
    if nSkinColor and nSkinColor > 0 then
        local tbColorTemplate = AvatarColorDataTable:GetTemplate(nSkinColor)
        pAvatarComponent:SetSkinColor(tbColorTemplate.nRed,tbColorTemplate.nGreen, tbColorTemplate.nBlue, false)
    end

    local tbAvatarExtraConfigs = GetHumanAvatarExtraConfigs()
    local nValue
    for szKey, szPartName in pairs(ProtoFieldNameToPartName) do
        if(tbResData) then
            nValue = tbResData[szKey]
        else
            nValue = nil
        end
        if(nValue ~= nil and nValue > 0) then
            if tbAvatarExtraConfigs and tbAvatarExtraConfigs[szPartName] ~= nil then
                local tbConfig = tbAvatarExtraConfigs[szPartName]
                pAvatarComponent:AddPartByName(szPartName, nValue, false, tbConfig.nPriority, tbConfig.bMerged)
            else
                pAvatarComponent:AddPartByName(szPartName, nValue, false, 0, true)
            end
        else
            pAvatarComponent:RemovePartByName(szPartName, false)
        end
    end

    pAvatarComponent:CommitAsync()
    -- pAvatarComponent:GetOwner().Mesh:SetVisibility(false, true)
    return true
end


return GameAvatarHelper
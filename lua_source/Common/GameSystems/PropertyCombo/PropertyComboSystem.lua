-----------------------------------------------------
--File Name    : PropertyComboSystem.lua
--Author       : Song Fuhao
--Create Time  : 2019-03-26
--Description  : 用于管理外围系统对副本内属性的叠加
-----------------------------------------------------
local PropertyComboSystem = {}

local L10N = require("L10N")
local PropName = require("PropName")
local PropertyComboDataTable = require("PropertyComboDataTable")
local PropertyComboDefineDataTable = require("PropertyComboDefineDataTable")
local PropertyComboOperationTypeDef = require("PropertyComboOperationTypeDef")
local PropertyComboDescParser = require("PropertyComboDescParser")

local OPREATION_TYPE = {
    BOTH = -1,
    PLUS = PropertyComboOperationTypeDef.PLUS,
    MULTIPLY = PropertyComboOperationTypeDef.MULTIPLY,
}
local PROP_COMPONENT_TYPE = {
    HUMAN = 1,
    SHIP = 2,
}
local tbRegisterInfos = nil
local tbCustomParserMap = nil

PropertyComboSystem.PROP_COMPONENT_TYPE = PROP_COMPONENT_TYPE

local function RegisterComponentProperty(nComponentType, szPropKey, nOperationType, nPropId)
    if nOperationType == OPREATION_TYPE.BOTH then
        RegisterComponentProperty(nComponentType, szPropKey, OPREATION_TYPE.PLUS, nPropId)
        RegisterComponentProperty(nComponentType, szPropKey, OPREATION_TYPE.MULTIPLY, nPropId)
        return
    end
    local tbRegisterInfo = {}
    tbRegisterInfo.nComponentType = nComponentType
    tbRegisterInfo.nPropId = nPropId
    tbRegisterInfo.nOperationType = nOperationType
    tbRegisterInfo.szPropKey = szPropKey
    tbRegisterInfos[szPropKey] = tbRegisterInfos[szPropKey] or {}
    tbRegisterInfos[szPropKey][nOperationType] = tbRegisterInfo
end

local function RegisterProperty(self)
    local R = RegisterComponentProperty
    local C = PROP_COMPONENT_TYPE
    local P = PropName
    local O = OPREATION_TYPE
    R(C.SHIP    , "ShipAttack"                      , O.BOTH        , P.nShipAttack)
    R(C.SHIP    , "ShipBulletTriggerRadius"         , O.PLUS        , P.nBulletTriggerRangeDelta)
    R(C.SHIP    , "ShipBulletTriggerRadius"         , O.MULTIPLY    , P.nBulletTriggerRangeRatio)
    R(C.SHIP    , "ShipBulletMinDamage"             , O.BOTH        , P.nBulletMinRadiusDamageAddition)
    R(C.SHIP    , "ShipFiringRotationRange"         , O.PLUS        , P.nFiringRotationRangeDelta)
    R(C.SHIP    , "ShipFiringRotationRange"         , O.MULTIPLY    , P.nFiringRotationRangeRatio)
    R(C.SHIP    , "ShipBulletSpeed"                 , O.PLUS        , P.nBulletSpeedDelta)
    R(C.SHIP    , "ShipBulletSpeed"                 , O.MULTIPLY    , P.nBulletSpeedRatio)
    R(C.SHIP    , "ShipFiringInterval"              , O.PLUS        , P.nFiringIntervalDelta)
    R(C.SHIP    , "ShipFiringInterval"              , O.MULTIPLY    , P.nFiringIntervalRatio)
    R(C.SHIP    , "ShipBulletReloadTime"            , O.PLUS        , P.nReloadSpeedDelta)
    R(C.SHIP    , "ShipBulletReloadTime"            , O.MULTIPLY    , P.nReloadSpeedRatio)
    R(C.SHIP    , "ShipBulletDeviation"             , O.MULTIPLY    , P.nShipBulletDeviationRatio)
    R(C.SHIP    , "ShipBulletAimDeviation"          , O.MULTIPLY    , P.nShipBulletAimDeviationRatio)
    R(C.SHIP    , "ShipBurningProb"                 , O.MULTIPLY    , P.nBurningProb)
    R(C.SHIP    , "ShipLeakingProb"                 , O.MULTIPLY    , P.nLeakingProb)
    R(C.SHIP    , "ShipBurningProofProb"            , O.MULTIPLY    , P.nBurningProofProb)
    R(C.SHIP    , "ShipLeakingProofProb"            , O.MULTIPLY    , P.nLeakingProofProb)
    R(C.SHIP    , "ShipBurningDamageRatioCaused"    , O.BOTH        , P.nBurningDamageRatioCaused)
    R(C.SHIP    , "ShipLeakingDamageRatioCaused"    , O.BOTH        , P.nLeakingDamageRatioCaused)
    R(C.SHIP    , "ShipBurningDamageRatioTaken"     , O.BOTH        , P.nBurningDamageRatioTaken)
    R(C.SHIP    , "ShipLeakingDamageRatioTaken"     , O.BOTH        , P.nLeakingDamageRatioTaken)
    R(C.SHIP    , "ShipFiringRange"                 , O.PLUS        , P.nFiringRangeDelta)
    R(C.SHIP    , "ShipFiringRange"                 , O.MULTIPLY    , P.nFiringRangeRatio)
    -- R(C.SHIP  , "ShipFiringMinRange"             , O.PLUS        , P.nShipFiringMinRangeDelta)
    -- R(C.SHIP  , "ShipFiringMinRange"             , O.MULTIPLY    , P.nShipFiringMinRangeRatio)
    R(C.SHIP    , "ShipPerfectFiringRangeEnd"       , O.BOTH        , P.nPerfectFiringRangeEnd)
    R(C.SHIP    , "ShipPerfectFiringRangeBegin"     , O.BOTH        , P.nPerfectFiringRangeBegin)
    R(C.SHIP    , "ShipHeadDamage"                  , O.MULTIPLY    , P.nShipHeadDamageRatio)
    R(C.SHIP    , "ShipBodyDamage"                  , O.MULTIPLY    , P.nShipBodyDamageRatio)
    R(C.SHIP    , "ShipSternDamage"                 , O.MULTIPLY    , P.nShipSternDamageRatio)
    R(C.SHIP    , "ShipSailDamage"                  , O.MULTIPLY    , P.nShipSailDamageRatio)
    R(C.SHIP    , "ShipDeckDamage"                  , O.MULTIPLY    , P.nShipDeckDamageRatio)
    R(C.SHIP    , "ShipCaptainRoomDamage"           , O.MULTIPLY    , P.nShipCaptainRoomDamageRatio)
    R(C.SHIP    , "ShipLinearSpeed"                 , O.MULTIPLY    , P.nLinearMaxSpeedAddition)
    R(C.SHIP    , "ShipAngularSpeed"                , O.MULTIPLY    , P.nAngularMaxSpeedAddition)
    R(C.SHIP    , "ShipMaxHp"                       , O.BOTH        , P.nShipMaxHpBase)
    R(C.SHIP    , "ShipMaxDyingHp"                  , O.BOTH        , P.nShipMaxDyingHp)
    R(C.SHIP    , "ShipRescuedHp"                   , O.BOTH        , P.nShipRescuedHp)
    R(C.SHIP    , "ShipDyingHpReduceSpeed"          , O.BOTH        , P.nShipDyingHpReduceSpeed)
    R(C.SHIP    , "ShipRescuedTime"                 , O.BOTH        , P.nShipRescuedTime)
    R(C.SHIP    , "ShipItemUsingTime"               , O.BOTH        , P.nShipItemUsingTime)
    R(C.SHIP    , "ShipWeaponDamageInterval"        , O.PLUS        , P.nWeaponDamageIntervalDelta)
    R(C.SHIP    , "ShipWeaponDamageInterval"        , O.MULTIPLY    , P.nWeaponDamageIntervalRatio)
    R(C.SHIP    , "ShipListenRange"                 , O.BOTH        , P.nShipListenRange)
    R(C.SHIP    , "ShipMoraleConsumedSpeed"         , O.MULTIPLY    , P.nShipMoraleConsumedSpeed)
    R(C.SHIP    , "ShipPickupRange"                 , O.BOTH        , P.nShipPickupRange)
    R(C.SHIP    , "ShipPartDurability"              , O.BOTH        , P.nShipPartDurability)
    R(C.SHIP    , "ShipRecoveredHpByKilling"        , O.MULTIPLY    , P.nShipRecoveredHpByKilling)
    R(C.SHIP    , "ShipDebuffTime"                  , O.MULTIPLY    , P.nShipDebuffTimeRatio)
    R(C.SHIP    , "ShipSmallCannonDamage"           , O.BOTH        , P.nSmallCannonDamageAddition)
    R(C.SHIP    , "ShipPowderKegDamage"             , O.BOTH        , P.nPowderKegDamageAddition)
    R(C.SHIP    , "ShipCarronadeDamage"             , O.BOTH        , P.nCarronadeDamageAddition)
    R(C.SHIP    , "ShipTorpedoDamage"               , O.BOTH        , P.nTorpedoDamageAddition)
    R(C.SHIP    , "ShipSakersDamage"                , O.BOTH        , P.nSakersDamageAddition)
    R(C.SHIP    , "ShipDartleDamage"                , O.BOTH        , P.nDartleDamageAddition)
    R(C.SHIP    , "ShipAssaultGunDamage"            , O.BOTH        , P.nAssaultGunDamageAddition)
    R(C.SHIP    , "ShipSnipeGunDamage"              , O.BOTH        , P.nSnipeGunDamageAddition)
    R(C.SHIP    , "ShipEmbolonDamage"               , O.BOTH        , P.nEmbolonDamageAddition)
    R(C.SHIP    , "ShipFlamerDamage"                , O.BOTH        , P.nFlamerDamageAddition)
    R(C.SHIP    , "ShipSternCannonDamage"           , O.BOTH        , P.nSternCannonDamageAddition)
    R(C.SHIP    , "ShipPowderKegFiringRoundCount"   , O.PLUS        , P.nPowderKegFiringRoundCountDelta)
    R(C.SHIP    , "ShipCarronadeFiringRoundCount"   , O.PLUS        , P.nCarronadeFiringRoundCountDelta)
    R(C.SHIP    , "ShipDamageRatioToNpc"            , O.MULTIPLY    , P.nShipDamageRatioToNpc)
    R(C.SHIP    , "ShipDamageRatioFromNpc"          , O.MULTIPLY    , P.nShipDamageRatioFromNpc)
    R(C.SHIP    , "ShipDamageRatio"                 , O.MULTIPLY    , P.nShipDamageRatio)
    R(C.SHIP    , "ShipDyingDamageRatio"            , O.MULTIPLY    , P.nShipDamageRatio)

    R(C.HUMAN   , "HumanAttack"                     , O.BOTH        , P.nHumanAttack)
    R(C.HUMAN   , "HumanAttackInterval"             , O.BOTH        , P.nHumanAttackInterval)
    R(C.HUMAN   , "HumanReloadTime"                 , O.BOTH        , P.nHumanReloadTime)
    -- R(C.HUMAN , "HumanDeviation"                 , O.MULTIPLY    , P.nHumanDeviationRatio)
    -- R(C.HUMAN , "HumanAimDeviation"              , O.MULTIPLY    , P.nHumanAimDeviationRatio)
    R(C.HUMAN   , "HumanMaxHp"                      , O.BOTH        , P.nHumanMaxHpBase)
    R(C.HUMAN   , "HumanMaxDyingHp"                 , O.BOTH        , P.nHumanMaxDyingHp)
    R(C.HUMAN   , "HumanRescuedHp"                  , O.BOTH        , P.nHumanRescuedHp)
    R(C.HUMAN   , "HumanDyingHpReduceSpeed"         , O.BOTH        , P.nHumanDyingHpReduceSpeed)
    R(C.HUMAN   , "HumanRescuedTime"                , O.BOTH        , P.nHumanRescuedTime)
    R(C.HUMAN   , "HumanItemUsingTime"              , O.BOTH        , P.nHumanItemUsingTime)
    R(C.HUMAN   , "HumanListenRange"                , O.BOTH        , P.nHumanListenRange)
    R(C.HUMAN   , "HumanMoraleConsumedSpeed"        , O.MULTIPLY    , P.nHumanMoraleConsumedSpeed)
    R(C.HUMAN   , "HumanPickupRange"                , O.BOTH        , P.nHumanPickupRange)
    R(C.HUMAN   , "HumanDamageRatioToNpc"           , O.MULTIPLY    , P.nHumanDamageRatioToNpc)
    R(C.HUMAN   , "HumanDamageRatioFromNpc"         , O.MULTIPLY    , P.nHumanDamageRatioFromNpc)
    R(C.HUMAN   , "HumanDamageRatio"                , O.MULTIPLY    , P.nHumanDamageRatio)
    R(C.HUMAN   , "HumanDyingDamageRatio"           , O.MULTIPLY    , P.nHumanDamageRatio)
    R(C.HUMAN   , "DiamondRefreshTimeOnMap"         , O.BOTH        , P.nDiamondRefreshTimeOnMap)

    -- COMMON的内容先放在船身上
    R(C.SHIP    , "BuildingTime"                    , O.BOTH        , P.nBuildingTimeAddition)
    R(C.SHIP    , "PartBuildingTime"                , O.BOTH        , P.nPartBuildingTimeAddition)
    R(C.SHIP    , "WeaponBuildingTime"              , O.BOTH        , P.nWeaponBuildingTimeAddition)
    R(C.SHIP    , "ShipBuildingTime"                , O.BOTH        , P.nShipBuildingTimeAddition)
    R(C.SHIP    , "PartBuildingMaterial"            , O.MULTIPLY    , P.nPartBuildingMaterialRatio)
    R(C.SHIP    , "WeaponBuildingMaterial"          , O.MULTIPLY    , P.nWeaponBuildingMaterialRatio)
    R(C.SHIP    , "ShipBuildingMaterial"            , O.MULTIPLY    , P.nShipBuildingMaterialRatio)
end

local function RegisterCustomDescParser(self)
    tbCustomParserMap["DiamondRefreshTimeOnMap"]    =  PropertyComboDescParser.DiamondRefreshTimeOnMapParser
end

-- 根据PropertyComboDefineDataTable的编号对属性进行排序
local function SortDisplayInfoList(tbDisplayInfoList)
    table.sort(tbDisplayInfoList, function(A, B)
        local nIndexA = PropertyComboDefineDataTable:GetPropertyIndex(A.szKey)
        local nIndexB = PropertyComboDefineDataTable:GetPropertyIndex(B.szKey)
        if nIndexA ~= nIndexB then
            return nIndexA < nIndexB
        end
        return false
    end)
end

local function DefaultDescParser(tbReturnDisplayInfo, szKey, nOperationType, nValue)
    tbReturnDisplayInfo.szKey = szKey
    tbReturnDisplayInfo.l10nDisplayName = PropertyComboDefineDataTable:GetPropertyDisplayName(szKey)
    if nOperationType == PropertyComboOperationTypeDef.PLUS then
        if nValue % 1 == 0 then
            tbReturnDisplayInfo.szDisplayValue = string.format("%d", nValue)
        else
            tbReturnDisplayInfo.szDisplayValue = string.format("%.2f", nValue)
        end
    elseif nOperationType == PropertyComboOperationTypeDef.MULTIPLY then
        tbReturnDisplayInfo.szDisplayValue = string.format("%.2f%%", nValue * 100)
    end
    if nValue > 0 then
        tbReturnDisplayInfo.szDisplayValue = "+" .. tbReturnDisplayInfo.szDisplayValue
    end
end

-- 根据一条属性的具体字段获取展示数据
local function GetDisplayInfo(szKey, nOperationType, nValue)
    local tbDisplayInfo = {}
    
    local fnParserFunc = tbCustomParserMap[szKey]
    if fnParserFunc then
        fnParserFunc(tbDisplayInfo, szKey, nOperationType, nValue)
    else
        DefaultDescParser(tbDisplayInfo, szKey, nOperationType, nValue)
    end

    return tbDisplayInfo
end

-- 获取一组属性的展示数据
local function GetDisplayInfoList(tbProperties)
    local tbDisplayInfoList = {}
    for szKey, tbProperty in pairs(tbProperties) do
        for nOperationType, nValue in pairs(tbProperty) do
            table.insert(tbDisplayInfoList, GetDisplayInfo(szKey, nOperationType, nValue))
        end
    end
    SortDisplayInfoList(tbDisplayInfoList)
    return tbDisplayInfoList
end

function PropertyComboSystem:Init()
    tbRegisterInfos = {}
    tbCustomParserMap = {}
    RegisterProperty(self)
    RegisterCustomDescParser(self)
end

function PropertyComboSystem:Uninit()
    tbRegisterInfos = nil
    tbCustomParserMap = nil
end

---------------------------------------------------------------------------------------------
-- 用于直接获取数据的接口
---------------------------------------------------------------------------------------------
-- 用于获取PropCombo的注册信息
-- 目前应该只有PropertyComponent需要调用
function PropertyComboSystem:GetPropRegisterInfo(szKey)
    return tbRegisterInfos[szKey]
end

---------------------------------------------------------------------------------------------
-- 用于直接获取数据的接口
---------------------------------------------------------------------------------------------
-- 根据一组Id，获取最后累加的属性数据集合
-- @param tbComboIdWithCountMap
-- {
--     [nComboId] = nCount,
--     [nComboId] = nCount,
--     [nComboId] = nCount
-- }
function PropertyComboSystem:GetMultiPropertyComboProperties(tbComboIdWithCountMap)
    local tbProperties = {}
    for nComboId, nCount in pairs(tbComboIdWithCountMap) do
        local tbTemplate = PropertyComboDataTable:GetTemplate(nComboId)
        if tbTemplate then
            for szKey, tbProperty in pairs(tbTemplate.tbProperties) do
                tbProperties[szKey] = tbProperties[szKey] or {}
                for nOperationType, nValue in pairs(tbProperty) do
                    if tbProperties[szKey][nOperationType] then
                        tbProperties[szKey][nOperationType] = tbProperties[szKey][nOperationType] + nValue * nCount
                    else
                        tbProperties[szKey][nOperationType] = nValue * nCount
                    end
                end
            end
        end
    end
    return tbProperties
end

---------------------------------------------------------------------------------------------
-- 用于获取UI展示数据的接口
---------------------------------------------------------------------------------------------
-- 根据一条属性的Id获取展示数据列表
-- @param nComboId
function PropertyComboSystem:GetPropertyComboDisplayInfoList(nComboId)
    local tbTemplate = PropertyComboDataTable:GetTemplate(nComboId)
    if tbTemplate then
        return GetDisplayInfoList(tbTemplate.tbProperties)
    end
    return {}
end

-- 根据一条属性的Id获取拼接好的展示数据字符串
-- @param nComboId
function PropertyComboSystem:GetPropertyComboDisplayString(nComboId)
    local szDisplayString = ""
    local tbTemplate = PropertyComboDataTable:GetTemplate(nComboId)
    if tbTemplate then
        for _, tbDisplayInfo in ipairs(GetDisplayInfoList(tbTemplate.tbProperties)) do
            szDisplayString = szDisplayString .. L10N:ToString(tbDisplayInfo.l10nDisplayName)..tbDisplayInfo.szDisplayValue.."\n"
        end
    end
    return szDisplayString
end

--当需要给 数值设置不同颜色的时候 用这个
function PropertyComboSystem:GetPropertyComboDisplayStringWithColor(nComboId, szColor)
    local szDisplayString = ""
    local tbTemplate = PropertyComboDataTable:GetTemplate(nComboId)
    if tbTemplate then
        for _, tbDisplayInfo in ipairs(GetDisplayInfoList(tbTemplate.tbProperties)) do
            szDisplayString = szDisplayString .. L10N:ToString(tbDisplayInfo.l10nDisplayName).. 
            "<text color=\"#".. szColor .."\">" .. tbDisplayInfo.szDisplayValue.. "</>\n"
        end
    end
    return szDisplayString
end

-- 根据多组ComboId获取展示数据列表
-- @param tbComboIdWithCountMap
-- {
--     [nComboId] = nCount,
--     [nComboId] = nCount,
--     [nComboId] = nCount
-- }
function PropertyComboSystem:GetMultiPropertyComboDisplayInfoList(tbComboIdWithCountMap)
    local tbProperties = self:GetMultiPropertyComboProperties(tbComboIdWithCountMap)
    return GetDisplayInfoList(tbProperties)
end

return PropertyComboSystem
-----------------------------------------------------
--File Name    : HumanAvatarHelper.lua
--Author       : WuJizhou
--Create Time  : 4/30/2020, 3:58:27 PM
--Description  : HumanAvatarHelper
-----------------------------------------------------
local HumanAvatarHelper = {}


local ItemDataTable                     = require("ItemDataTable")
local HumanArmorDef                     = require("HumanArmorDef")
local HumanAvatarDef                    = require("HumanAvatarDef")
local ItemCategoryDef                   = require("ItemCategoryDef")
local DefaultAppearanceDataTable        = require("DefaultAppearanceDataTable")
local HumanArmorFashionDataTable        = require("HumanArmorFashionDataTable")
local HumanArmorDefaultFashionDataTable = require("HumanArmorDefaultFashionDataTable")
local AvatarDataTable                   = require("AvatarDataTable")
local HumanDataTable                    = require("HumanDataTable")
local Util                              = require("BaseUtil")

local ArmorType     = HumanArmorDef.ArmorType
local FashionType   = HumanAvatarDef.FashionType
local FashionSlotCategory   = HumanAvatarDef.FashionSlotCategory
local SlotTypeToPartType = HumanAvatarDef.SlotTypeToPartType

local tbFashionTypeToArmorType = {}
tbFashionTypeToArmorType[FashionType.Knight]  = ArmorType.Knight
tbFashionTypeToArmorType[FashionType.Light]   = ArmorType.Light
tbFashionTypeToArmorType[FashionType.Robe]    = ArmorType.Robe
tbFashionTypeToArmorType[FashionType.Stealth] = ArmorType.Stealth
HumanAvatarHelper.FashionTypeToArmorType = tbFashionTypeToArmorType

local tbArmorTypeToFashionType = {}

local function MapArmorTypeToFashionType()
    for nFashionType, nArmorType in pairs(tbFashionTypeToArmorType) do
        tbArmorTypeToFashionType[nArmorType] = nFashionType
    end
end

MapArmorTypeToFashionType()

local FashionFlagBitDefine = {}
FashionFlagBitDefine[FashionType.Knight]  = 0
FashionFlagBitDefine[FashionType.Light]   = 1
FashionFlagBitDefine[FashionType.Robe]    = 2
FashionFlagBitDefine[FashionType.Stealth] = 3

local bDebugFlag = false

local function LogDebugInternal(...)
    -- luacheck: push ignore 113
    if bDebugFlag then
        logdebug("HumanAvatarHelper", ...)
    end
    -- luacheck: pop
end

local function GetHumanTemplateByAvatarId(nAvatarId)
    local nHumanId = AvatarDataTable:GetHumanId(nAvatarId)
    local tbHumanResTemplate = HumanDataTable:GetResData(nHumanId)
    LogDebugInternal("GetHumanTemplateByAvatarId", nAvatarId, nHumanId)
    assert(tbHumanResTemplate)
    return tbHumanResTemplate
end

local function GetHumanTemplateByHumanId(nHumanId)
    local tbHumanResTemplate = HumanDataTable:GetResData(nHumanId)
    LogDebugInternal("GetHumanTemplateByHumanId", nHumanId)
    assert(tbHumanResTemplate)
    return tbHumanResTemplate
end

HumanAvatarHelper.PRIORITY_ORDER = 
{
    FashionSlotCategory.Upper,
    FashionSlotCategory.Lower,
    FashionSlotCategory.Hat,
    FashionSlotCategory.Shoe
}


local function PreProcessTemplates(tbTemplateIds, bProcessBasicFashion)
    local tbResultList = {}
    local tbCandiateTemplates = {}
    for _, nTemplateId in ipairs(tbTemplateIds) do
        local tbTemplate = ItemDataTable:GetTemplate(nTemplateId)
        if tbTemplate then
            local bSkip = false
            if tbTemplate.nFashionType ~= FashionType.Basic and bProcessBasicFashion then
                bSkip = true
            end
            if not bSkip then
                local nSubCategory = tbTemplate.nSubCategory
                tbCandiateTemplates[nSubCategory] = tbTemplate
            end
        end
    end

    local tbSlotOverlayState = {}
    for _, nSlotCatory in ipairs(HumanAvatarHelper.PRIORITY_ORDER) do
        if not tbSlotOverlayState[nSlotCatory] then
            local tbTemplate = tbCandiateTemplates[nSlotCatory]
            if tbTemplate then
                local tbOverlaySlots = tbTemplate.tbOverlaySlots
                for _, nOverlaySlot in ipairs(tbOverlaySlots) do
                    tbSlotOverlayState[nOverlaySlot] = true
                end
                table.insert(tbResultList, tbTemplate.nId)
            end
        end
    end
    return tbResultList, tbSlotOverlayState
end


function HumanAvatarHelper.LogDebugTable(szTag, tbData)
    if bDebugFlag then
        LogDebugInternal(szTag, "Begin")
        Util:PrintTable(tbData, 3)
        LogDebugInternal(szTag, "End")
    end
end

function HumanAvatarHelper.LogDebug(...)
    if bDebugFlag then
        LogDebugInternal(...)
    end
end


function HumanAvatarHelper.ParseToPartDataFromAppearance(tbAppearanceIds)
    local tbRet = {}
    for _, nAppearanceId in ipairs(tbAppearanceIds) do
        local tbPartData = DefaultAppearanceDataTable:GetPartDatas(nAppearanceId)
        if tbPartData then
            for nPartType, nPartValue in pairs(tbPartData) do
                if  nPartValue > 0 then
                    tbRet[nPartType] = nPartValue
                end
            end
        end
    end
    return tbRet
end


function HumanAvatarHelper.ParseToPartDataFromFashionItemTemplate(tbFashionTemplateIds)
    local tbArmorTemplateIds = {}
    local tbBasicTemplateIds = {}
    for _, nTemplateId in ipairs(tbFashionTemplateIds) do
        local tbTemplate = ItemDataTable:GetTemplate(nTemplateId)
        if tbTemplate then
            local nFashionType = tbTemplate.nFashionType
            -- local nFashionId = tbTemplate.nFashionId
            if nFashionType == FashionType.Basic then
                table.insert(tbBasicTemplateIds, nTemplateId)
            else
                table.insert(tbArmorTemplateIds, nTemplateId)
            end
        else
            logerror("HumanAvatarHelper.ParseToPartDataFromFashionItemTemplate, template id is invalid, id : ", nTemplateId)
        end
    end
    local tbArmorFashionPartData = HumanAvatarHelper.ParseToPartDataFromArmorFashionItemTemplate(tbArmorTemplateIds)
    local tbBasicFashionPartData = HumanAvatarHelper.ParseToPartDataFromBasicFashionItemTemplate(tbBasicTemplateIds)
    return tbBasicFashionPartData, tbArmorFashionPartData
end



function HumanAvatarHelper.ParseToPartDataFromArmorFashionItemTemplate(tbArmorFashionTemplateIds, bNotWithDefault)
    local tbArmorFashionIdMap = {}
    local tbArmorOverlayData = {}
    for szKey, nArmorType in pairs(ArmorType) do
        tbArmorFashionIdMap[nArmorType] = {}
        tbArmorOverlayData[nArmorType] = {}
    end

    -- 使用默认的fashion进行预设
    if not bNotWithDefault then
        for nArmorType, tbData in pairs(tbArmorFashionIdMap) do
            local tbDefault = HumanArmorDefaultFashionDataTable:GetFashions(nArmorType)
            for nSlotType, nFashionId in pairs(tbDefault) do
                tbData[nSlotType] = nFashionId
            end
        end
    end
    local tbTemplateMap = {}
    for _, nTemplateId in ipairs(tbArmorFashionTemplateIds) do
        local tbTemplate = ItemDataTable:GetTemplate(nTemplateId)
        if tbTemplate then
            if tbTemplate.nCategory == ItemCategoryDef.FASHION then
                local nFashionType = tbTemplate.nFashionType
                if nFashionType ~= FashionType.Basic then
                    local nArmorType = HumanAvatarHelper.FashionTypeToArmorType[nFashionType]
                    local tbMap = tbTemplateMap[nArmorType]
                    if not tbMap then
                        tbMap = {}
                        tbTemplateMap[nArmorType] = tbMap
                    end
                    table.insert(tbMap, nTemplateId)
                end
            end
        end
    end

    -- -- 使用时装对预设进行覆盖
    for nArmorType, tbArmorTemplateIds in pairs(tbTemplateMap) do
        local tbResultTemplateIds, tbOverlayData = PreProcessTemplates(tbArmorTemplateIds)
        local tbData = tbArmorFashionIdMap[nArmorType]
        tbArmorOverlayData[nArmorType] = tbOverlayData
        for _, nTemplateId in ipairs(tbResultTemplateIds) do
            local tbTemplate = ItemDataTable:GetTemplate(nTemplateId)
            local nFashionId = tbTemplate.nFashionId
            local nFashionSlotCategory = tbTemplate.nSubCategory
            tbData[nFashionSlotCategory] = nFashionId
        end
    end
    return HumanAvatarHelper.ParseToPartDataFromArmorFashionId(tbArmorFashionIdMap, tbArmorOverlayData)
end

function HumanAvatarHelper.ParseToPartDataFromBasicFashionItemTemplate(tbBasicFashionTemplateIds)
    local tbSlotOverlayData
    tbBasicFashionTemplateIds, tbSlotOverlayData = PreProcessTemplates(tbBasicFashionTemplateIds, true)
    local tbBasicFashionIds = {}
    for _, nTemplateId in ipairs(tbBasicFashionTemplateIds) do
        local tbTemplate = ItemDataTable:GetTemplate(nTemplateId)
        if tbTemplate then
            local nFashionType = tbTemplate.nFashionType
            local nFashionId = tbTemplate.nFashionId
            if nFashionType == FashionType.Basic then
                local nFashionSlotCategory = tbTemplate.nSubCategory
                tbBasicFashionIds[nFashionSlotCategory] = nFashionId
            end
        end
    end
    return HumanAvatarHelper.ParseToPartDataFromBasicFashionId(tbBasicFashionIds, tbSlotOverlayData)
end

local function ParseSlotOverlayDataToPartOverlayData(tbSlotOverlayData, tbOutOverlayPartData)
    if tbSlotOverlayData  then
        for nSlotType, _bOverlay in pairs(tbSlotOverlayData) do
            local tbPartType = SlotTypeToPartType[nSlotType]
            if tbPartType then
                for _, nPartType in ipairs(tbPartType) do
                    tbOutOverlayPartData[nPartType] = true
                end
            end
        end
    end
end

function HumanAvatarHelper.ParseToPartDataFromBasicFashionId(tbBasicFashionIds, tbExtraOverlayData)
    local tbBasicFashionPartData = {}
    local tbOverlayPartData = {}
    if tbExtraOverlayData then
        ParseSlotOverlayDataToPartOverlayData(tbExtraOverlayData, tbOverlayPartData)
    end    
    for nSlot, nFashionId in pairs(tbBasicFashionIds) do
        if not tbExtraOverlayData or not tbExtraOverlayData[nSlot] then
            local tbLevelConfigDatas = HumanArmorFashionDataTable:GetFashionDatas(nFashionId)
            local tbData = tbLevelConfigDatas[HumanArmorDef.MAX_LEVEL]
            for nPartType, nPartValue in pairs(tbData) do
                local bOverlay = tbOverlayPartData[nPartType]
                if bOverlay and nPartValue < 0 then
                    tbBasicFashionPartData[nPartType] = HumanAvatarDef.PLACE_HOLDER_PART_VALUE_INCLUDE_APPEARANCE
                elseif nPartValue >= 0 then
                    tbBasicFashionPartData[nPartType] = nPartValue
                end
            end
        end
    end
    return tbBasicFashionPartData
end


--tbArmorExtraOverlayData 可以为空，不为空时，标识着哪些slot被overlay
function HumanAvatarHelper.ParseToPartDataFromArmorFashionId(tbArmorFashionIdMap, tbArmorExtraOverlayData)
    local tbArmorFashionPartData = {}
    for nArmorType, tbFashionIds in pairs(tbArmorFashionIdMap) do
        local tbOverlayPartData = {}
        local tbOverlaySlotData
        if tbArmorExtraOverlayData and tbArmorExtraOverlayData[nArmorType] then
            ParseSlotOverlayDataToPartOverlayData(tbArmorExtraOverlayData[nArmorType], tbOverlayPartData)
            tbOverlaySlotData = tbArmorExtraOverlayData[nArmorType]
        end     
        local tbData = {} 
        tbArmorFashionPartData[nArmorType] = tbData
        for nSlotType, nFashionId in pairs(tbFashionIds) do
            local tbLevelConfigDatas = HumanArmorFashionDataTable:GetFashionDatas(nFashionId)
            if not tbOverlaySlotData or not tbOverlaySlotData[nSlotType] then
                for nLevel, tbPartData in pairs(tbLevelConfigDatas) do
                    local tbLevelDatas = tbData[nLevel]
                    if not tbLevelDatas then
                        tbLevelDatas = {}
                        tbData[nLevel] = tbLevelDatas
                    end
                    for nPartType, nPartValue in pairs(tbPartData) do
                        local bOverlay = tbOverlayPartData[nPartType]
                        if bOverlay and nPartValue < 0 then
                            tbLevelDatas[nPartType] = HumanAvatarDef.PLACE_HOLDER_PART_VALUE_INCLUDE_APPEARANCE
                        elseif nPartValue >= 0 then
                            tbLevelDatas[nPartType] = nPartValue
                        end
                    end
                end
            end
        end
    end
    return tbArmorFashionPartData
end



-------------------------------------------

--BattlePlayerPrepareInfo
function HumanAvatarHelper.MakeHumanAvatarComponentCreateParameterByPrepareInfo(tbPrepareInfo)
    local tbParameter = {}
    if not tbPrepareInfo.tbAppearancePartData or #tbPrepareInfo.tbAppearancePartData == 0 then
        local tbHumanResTemplate = GetHumanTemplateByHumanId(tbPrepareInfo.nHumanId)
        tbParameter.tbAppearancePartData = tbHumanResTemplate.tbAppearance
        tbParameter.tbFashionItemTemplateIds = tbHumanResTemplate.tbFashionTemplateIds
    else
        tbParameter.tbAppearancePartData = tbPrepareInfo.tbAppearancePartData
        tbParameter.tbFashionItemTemplateIds = tbPrepareInfo.tbFashionItemTemplateIds
    end
    tbParameter.nHumanFashionFlag = tbPrepareInfo.nHumanFashionFlag
    return tbParameter
end


function HumanAvatarHelper.MakeHumanAvatarComponentCreateParameterByHumanConfig(nHumanId)
    local tbParameter = {}
    local tbTemplate = GetHumanTemplateByHumanId(nHumanId)
    assert(tbTemplate)
    tbParameter.tbAppearancePartData = tbTemplate.tbAppearance
    tbParameter.tbFashionItemTemplateIds = tbTemplate.tbFashionTemplateIds
    tbParameter.nHumanFashionFlag = tbTemplate.nHumanOverrideFlag
    return tbParameter
end

--dungeon_common.proto里的PlayerActorInitData
-- function HumanAvatarHelper.MakeHumanAvatarComponentCreateParameterByPlayerActorInitData(tbPlayerActorInitData)
--     local tbParameter = {}
--     tbParameter.tbAppearanceIds = tbPlayerActorInitData.human_default_appearance_ids
--     tbParameter.tbFashionItemTemplateIds = tbPlayerActorInitData.human_fashion_template_ids
--     return tbParameter
-- end


--dungeon_common.proto里的NpcActorInitData
-- function HumanAvatarHelper.MakeHumanAvatarComponentCreateParameterByNpcActorInitData(tbNpcActorInitData)
--     local tbParameter = {}
--     local nNpcTemplateId = tbNpcActorInitData.template_id
--     local tbNpcTemplate = NPCDataTable:GetTemplate(nNpcTemplateId)
--     assert(tbNpcTemplate)

--     if tbNpcTemplate.nType == TemplateTypeDef.HUMAN then
--         local nHumanTemplateId = tbNpcTemplate.nTypeID
--         local tbAvatarComponentCreateParameter = HumanAvatarHelper.MakeHumanAvatarComponentCreateParameterByHumanConfig(nHumanTemplateId)
--         tbParameter.tbAppearancePartData = tbAvatarComponentCreateParameter.tbAppearancePartData
--         tbParameter.tbFashionItemTemplateIds = tbAvatarComponentCreateParameter.tbFashionItemTemplateIds
--     end
--     return tbParameter
-- end

--player.proto的Player
function HumanAvatarHelper.MakeHumanAvatarComponentCreateParameterByPlayerData(tbPlayerData)
    local tbParameter = {}
    local nAvatarId = tbPlayerData.avatar_id
    local tbHumanResTemplate = GetHumanTemplateByAvatarId(nAvatarId)
    local tbAppearance = tbPlayerData.appearance
    if not tbAppearance then
        tbParameter.tbAppearancePartData =  tbHumanResTemplate.tbAppearance
    else
        local tbTemplateIds = tbAppearance.template_id
        if not tbTemplateIds or #tbTemplateIds == 0 then
            tbParameter.tbAppearancePartData = tbHumanResTemplate.tbAppearance
        else
            tbParameter.tbAppearancePartData = HumanAvatarHelper.ParseToPartDataFromAppearance(tbTemplateIds)
            -- tbParameter.tbAppearanceIds = tbTemplateIds
        end
    end

    local tbItemDatas = tbPlayerData.item
    local tbWearDatas = tbPlayerData.wears
    local tbEquippedFashionItemInstanceIds = tbWearDatas.fashion
    local tbEquipedMap = {}
    for _, v in ipairs(tbEquippedFashionItemInstanceIds) do
        tbEquipedMap[v] = true
    end
    local tbFashionItemTemplateIds ={}
    for _, tbItemData in ipairs(tbItemDatas) do
        if tbEquipedMap[tbItemData.instance_id] then
            table.insert(tbFashionItemTemplateIds, tbItemData.template_id)
        end
    end
    tbParameter.tbFashionItemTemplateIds = tbFashionItemTemplateIds
    tbParameter.nHumanFashionFlag = tbWearDatas.dry_fashion_flag
    return tbParameter
end

-- hub player other
function HumanAvatarHelper.MakeHumanAvatarComponentCreateParameterForPlayerOtherInHub(tbData)
    local tbParameter = {}

    local tbAppearance = tbData.appearance
    if not tbAppearance or #tbAppearance == 0 then
        logerror("HumanAvatarHelper.MakeHumanAvatarComponentCreateParameterForPlayerOtherInHub Error, appearance is nil or empty")
        local nAvatarId = tbData.actor.template_id 
        local tbHumanResTemplate = GetHumanTemplateByAvatarId(nAvatarId)
        tbParameter.tbAppearancePartData = tbHumanResTemplate.tbAppearance
    else
        tbParameter.tbAppearancePartData = HumanAvatarHelper.ParseToPartDataFromAppearance(tbAppearance)
    end
    tbParameter.tbFashionItemTemplateIds = tbData.human_fashion_ids
    tbParameter.nHumanFashionFlag = 0
    return tbParameter
end

function HumanAvatarHelper.GetDefaultAppearancePartData(nAvatarId)
    local tbHumanResTemplate = GetHumanTemplateByAvatarId(nAvatarId)
    return tbHumanResTemplate.tbAppearance
end

--------------------------------------misc--------------------------------------

function HumanAvatarHelper.IsOverrideByBasicFashion(nFlag, nFashionType)
    if nFashionType == FashionType.Basic then
        return true
    end
    
    local nResult = nFlag & (1 << FashionFlagBitDefine[nFashionType])
    return nResult > 0
end

function HumanAvatarHelper.IsArmorOverrideByBasicFashion(nFlag, nArmorType)
    local nFashionType = tbArmorTypeToFashionType[nArmorType]
    return HumanAvatarHelper.IsOverrideByBasicFashion(nFlag, nFashionType)
end

function HumanAvatarHelper.ModifyFlagValue(nOriginValue, nFashionType, bOverride)
    if nFashionType == FashionType.Basic then
        return nOriginValue
    end
    local nFlag = 1 << FashionFlagBitDefine[nFashionType]
    local nResult
    if bOverride then
        nResult = nOriginValue | nFlag
    else
        nFlag = ~nFlag
        nResult = nOriginValue & nFlag
    end
    return nResult
end

function HumanAvatarHelper.GetArmorFlagTable(nFlag)
    local tbResult = {}
    for _, nArmorType in pairs(ArmorType) do
        local bResult = HumanAvatarHelper.IsArmorOverrideByBasicFashion(nFlag, nArmorType)
        tbResult[nArmorType] = bResult
    end
    return tbResult
end
--------------------------------------weapon---------------------------------------------


function HumanAvatarHelper.ParseToHumanWeaponFashionDataFromFashionTemplateIds(tbFashionItemTemplateIds)
    local tbFashionData = {}
    for _, nTemplateId in pairs(tbFashionItemTemplateIds) do
        local tbTemplate = ItemDataTable:GetTemplate(nTemplateId)
        local nWeaponGroup = tbTemplate.nSubCategory
        local nFashionId = tbTemplate.nFashionId
        tbFashionData[nWeaponGroup] = nFashionId
    end
    return tbFashionData
end


return HumanAvatarHelper
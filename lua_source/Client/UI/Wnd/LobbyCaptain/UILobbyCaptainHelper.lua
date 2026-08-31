
local ItemDataTable = require("ItemDataTable")
local ItemCategoryDef = require("ItemCategoryDef")
local ItemSystem = require("ItemSystem")
local LobbyCaptainMiscDef = require("LobbyCaptainMiscDef")
local GamePlayerSelfHelper = require("GamePlayerSelfHelper")
local HumanAvatarHelper = require("HumanAvatarHelper")
local LobbyArmorMiscDataTable = require("LobbyArmorMiscDataTable")
local LobbyCaptainMiscIni = require("LobbyCaptainMiscIni")
local HumanAvatarDef = require("HumanAvatarDef")
local ItemResDataTable = require("ItemResDataTable")
local FashionType = HumanAvatarDef.FashionType

local UILobbyCaptainHelper = {}

local BASE_LEVEL = 1
local NOT_IN_BAG_ID = -1
local BASE_GROUP = 1

UILobbyCaptainHelper.DecorationUIType = 
{
    MAIN = 1,
    SHOW = 2, 
    GET  = 3
}

UILobbyCaptainHelper.tbCaptainItemState =
{
    UNGET = 1,
    GET = 2,
    EQUIP = 3,
}

local function IsDecorationExistSameGroupInBag(nGroupId)
    local tbDecorationsInBag = ItemSystem:GetItemsByCategory(ItemCategoryDef.DECORATION)
    for _, item in pairs(tbDecorationsInBag) do
        if item:GetTemplate().nGroupId == nGroupId then
            return true
        end
    end
    return false
end

function UILobbyCaptainHelper.GetAllDecorations()
    local tbDatas = {}

    local fnCommonSort = function(tbData1, tbData2)
        if tbData1.tbTemplate.nGrade > tbData2.tbTemplate.nGrade then
            return true
        elseif tbData1.tbTemplate.nGrade < tbData2.tbTemplate.nGrade then
            return false
        else
            return tbData1.tbTemplate.nGroupId > tbData2.tbTemplate.nGroupId
        end
    end

    --已装备的
    local tbEquipDecoration = ItemSystem:GetEquippedDecorationItem()
    local nId, nEquipDecorationInsId = NOT_IN_BAG_ID, NOT_IN_BAG_ID
    if tbEquipDecoration then
        nId, nEquipDecorationInsId = tbEquipDecoration:GetTemplateId(), tbEquipDecoration:GetInstanceId()
        table.insert(tbDatas, {
            nTemplateId = nId, tbTemplate = tbEquipDecoration:GetTemplate(),
            tbResTemplate = ItemDataTable:GetResTemplate(nId), nEquipState = UILobbyCaptainHelper.tbCaptainItemState.EQUIP,
            nInstanceId = nEquipDecorationInsId
        })
    end
    --已解锁的, 排除掉已装备
    local tbDecorationsInBag = ItemSystem:GetItemsByCategory(ItemCategoryDef.DECORATION)
    for _, item in pairs(tbDecorationsInBag) do
        if nEquipDecorationInsId ~= item:GetInstanceId() then
            nId = item:GetTemplateId()
            table.insert(tbDatas, {
                nTemplateId = nId, tbTemplate = item:GetTemplate(),
                tbResTemplate = ItemDataTable:GetResTemplate(nId), nEquipState = UILobbyCaptainHelper.tbCaptainItemState.GET,
                nInstanceId = item:GetInstanceId()
            })
        end
    end
    table.sort(tbDatas, fnCommonSort)
    --没解锁的
    local tbAllDecorationsTemplates = ItemDataTable:GetTemplatesByCategory(ItemCategoryDef.DECORATION)
    local tbUnlockDatas = {}
    for nTemplateId, tbTemplate in pairs(tbAllDecorationsTemplates) do
        if tbTemplate.nLevel == BASE_LEVEL then
            if not IsDecorationExistSameGroupInBag(tbTemplate.nGroupId) then
                table.insert(tbUnlockDatas, {
                    nTemplateId = nTemplateId, tbTemplate = tbTemplate,
                    tbResTemplate = ItemDataTable:GetResTemplate(nTemplateId), nEquipState = UILobbyCaptainHelper.tbCaptainItemState.UNGET,
                    nInstanceId = NOT_IN_BAG_ID
                })
            end
        end
    end
    table.sort(tbUnlockDatas, fnCommonSort)

    for _, v in pairs(tbUnlockDatas) do
        table.insert(tbDatas, v)
    end

    return tbDatas
end

function UILobbyCaptainHelper.GetRemainingTime(nItemInstanceId)
    local tbItem = ItemSystem:GetItem(nItemInstanceId)
    if tbItem and tbItem:HasExpiration() then
        return tbItem:GetRemainCanUseSeconds()
    end
    return nil
end

function UILobbyCaptainHelper.GetMaxUpGradeLevel()
    local nMax = 0
    local tbAllDecorationsTemplates = ItemDataTable:GetTemplatesByCategory(ItemCategoryDef.DECORATION)
    for nTemplateId, tbTemplate in pairs(tbAllDecorationsTemplates) do
        if BASE_GROUP == tbTemplate.nGroupId and tbTemplate.nLevel > nMax then
            nMax = tbTemplate.nLevel
        end
    end
    return nMax
end



local function CheckDataMatch(tbItemTemplate, tbItemTemplateFieldFilterData)
    local bMatch = true
    for szTemplateField, nTemplateFieldValue in pairs(tbItemTemplateFieldFilterData) do
        if szTemplateField == "nUseGender" then
            if tbItemTemplate.nUseGender ~= nTemplateFieldValue and tbItemTemplate.nUseGender ~= 0 then
                bMatch = false
                break
            end
        else
            if tbItemTemplate[szTemplateField] ~= nTemplateFieldValue then
                bMatch = false
                break
            end
        end
    end
    return bMatch
end


function UILobbyCaptainHelper.CreateCandidateTemplates(tbOutDatas, nCategory, tbItemTemplateFieldFilterData)
    local tbAllTemplate = ItemSystem:GetItemTemplatesByCategory(nCategory)
    for nTemplateId, tbTemplate in pairs(tbAllTemplate) do
        if CheckDataMatch(tbTemplate, tbItemTemplateFieldFilterData) then
            local tbData= {}
            tbData.nTemplateId = nTemplateId
            tbData.tbTemplate = tbTemplate
            local tbResTemplate = ItemResDataTable:GetTemplate(tbTemplate.nResId)

            tbData.szIcon = tbResTemplate.szIconPath
            tbData.nGrade = tbTemplate.nGrade
            tbData.l10nFirstName = tbTemplate.l10nName

            table.insert(tbOutDatas, tbData)
        end
    end
end

-- tbOutDatas: 创建的数据存入此数组
-- nCategory: 物品道具大类
-- tbItemTemplateFieldFilterData: 匹配参数，会根据此匹配参数，过滤出于template一致的数据
-- fnCreateData: 调用该函数创建具体的一个data，fnCreateData(tbItemTemplate, nInstanceId, bOwned, nRemainingTime)
--                  @Param tbItemTemplate : 道具配置表中的模板
--                  @Param nInstanceId :    如果拥有则是此道具的instanceid，如果不存在或者是default item，比如默认时装 则会传入-1
--                  @Param bOwned :         是否拥有
--                  @Param nRemainingTime : 对于有时效的物品，传入具体剩余时间，秒，否则nil
-- fnSortData: 可以为nil
function UILobbyCaptainHelper.CreateCandidateDatas(tbOutDatas, nCategory, tbItemTemplateFieldFilterData, fnCreateData, fnSortData, bIncludeNotOwned)
    local tbOwnedFashionItems = ItemSystem:GetItemsByCategory(nCategory)
    local tbOwnedItemGroups = {}
    for _, tbItem in ipairs(tbOwnedFashionItems) do
        local tbItemTemplate = tbItem:GetTemplate()
        local bMatch = CheckDataMatch(tbItemTemplate, tbItemTemplateFieldFilterData)
        if bMatch then
            local bHasExpiration = tbItem:HasExpiration()
            local nRemainTime
            if bHasExpiration then
                nRemainTime = tbItem:GetRemainCanUseSeconds()
            end
            if not bHasExpiration or nRemainTime > 0 then
                tbOwnedItemGroups[tbItemTemplate.nId] = true
                local nInstanceId = tbItem:GetInstanceId()
                local nTime = nil
                if bHasExpiration then
                    nTime = nRemainTime
                end
                local bEquiped = ItemSystem:IsEquiped(nInstanceId)
                local tbData = fnCreateData(tbItemTemplate, nInstanceId, true, nTime, bEquiped)
                table.insert(tbOutDatas, tbData)
            end
        end
    end

    if bIncludeNotOwned then
        local tbAllFashionTemplates = ItemDataTable:GetTemplatesByCategory(nCategory)
        for nTemplateId, tbItemTemplate in pairs(tbAllFashionTemplates) do

            if not tbOwnedItemGroups[tbItemTemplate.nId] then
                local bMatch = CheckDataMatch(tbItemTemplate, tbItemTemplateFieldFilterData)
                if bMatch then
                    local nInstanceId = LobbyCaptainMiscDef.NOT_IN_BAG_ID
                    local tbData = fnCreateData(tbItemTemplate, nInstanceId, false)
                    table.insert(tbOutDatas, tbData)
                end
            end
        end
    end
    if fnSortData then
        table.sort(tbOutDatas, fnSortData)
    end
end

local function GetPlayerNewItemRecordComponent()
    local PlayerSelf = GamePlayerSelfHelper:Get()
    local Component = PlayerSelf.PlayerNewItemRecordComponent
    return Component
end


function UILobbyCaptainHelper.HasNewHumanWeaponFashion()
    local Component = GetPlayerNewItemRecordComponent()
    return Component:HasNewHumanWeaponFashion()
end

function UILobbyCaptainHelper.HasNewHumanWeaponFashionByRangeType(nRangeType)
    local Component = GetPlayerNewItemRecordComponent()
    return Component:HasNewHumanWeaponFashionByRangeType(nRangeType)
end

function UILobbyCaptainHelper.HasNewHumanWeaponFashionByInstanceType(nInstanceType)
    local Component = GetPlayerNewItemRecordComponent()
    return Component:HasNewHumanWeaponFashionByInstanceType(nInstanceType)
end

function UILobbyCaptainHelper.IsNewHumanWeaponFashion(nInstanceId)
    local Component = GetPlayerNewItemRecordComponent()
    return Component:IsNewHumanWeaponFashion(nInstanceId)
end

function UILobbyCaptainHelper.HasNewHumanFashionByFashionType(nFashionType)
    local Component = GetPlayerNewItemRecordComponent()
    return Component:HasNewHumanFashionByFashionType(nFashionType)
end

function UILobbyCaptainHelper.HasNewHumanFashion()
    local Component = GetPlayerNewItemRecordComponent()
    return Component:HasNewHumanFashion()
end

function UILobbyCaptainHelper.HasNewHumanFashionByFashionAndSlotType(nFashionType, nSlotType)
    local Component = GetPlayerNewItemRecordComponent()
    return Component:HasNewHumanFashionByFashionAndSlotType(nFashionType, nSlotType)
end


function UILobbyCaptainHelper.HasNewHumanSuitByFashionType(nFashionType)
    local Component = GetPlayerNewItemRecordComponent()
    return Component:HasNewHumanSuitByFashionType(nFashionType)

end

function UILobbyCaptainHelper.IsNewHumanFashion(nInstanceId)
    local Component = GetPlayerNewItemRecordComponent()
    return Component:IsNewHumanFashion(nInstanceId)
end

function UILobbyCaptainHelper.GetHumanAnimationByFashionType(nFashionType)
    local szAnimKey
    if nFashionType ~= FashionType.Basic then
        local nArmorType = HumanAvatarHelper.FashionTypeToArmorType[nFashionType]
        local tbTemplate = LobbyArmorMiscDataTable:GetTemplate(nArmorType)
        szAnimKey = tbTemplate.szAnimKey
    else
        szAnimKey = LobbyCaptainMiscIni.nBasicFashionAnimKey
    end
    return szAnimKey
end

function UILobbyCaptainHelper.GetHumanAnimationByFashionTemplateId(nTemplateId)
    local tbTemplate = ItemSystem:GetItemTemplate(nTemplateId)
    local nFashionType = tbTemplate.nFashionType
    return UILobbyCaptainHelper.GetHumanAnimationByFashionType(nFashionType)
end


function UILobbyCaptainHelper.HasNewHumanVisualItem()
    return UILobbyCaptainHelper.HasNewHumanWeaponFashion() or UILobbyCaptainHelper.HasNewHumanFashion()
end


function UILobbyCaptainHelper.CheckDataMatch(tbInstanceIds, nItemCategory)
    if tbInstanceIds and #tbInstanceIds > 0 then
        local nInstanceId = tbInstanceIds[1]
        local tbItem = ItemSystem:GetItem(nInstanceId)
        if tbItem and tbItem:GetCategory() == nItemCategory then
            return true
        end
    end
    return false
end

return UILobbyCaptainHelper
local luaclass = require("luaclass")
local LobbyCaptainTabViewFilter = require("LobbyCaptainTabViewFilter")

local LobbyCaptainHumanFashionFilterImpl = luaclass("LobbyCaptainHumanFashionFilterImpl", LobbyCaptainTabViewFilter)

local HumanAvatarDef                = require("HumanAvatarDef")
local ItemCategoryDef               = require("ItemCategoryDef")
local LobbyCaptainMiscDef           = require("LobbyCaptainMiscDef")
local LobbyCaptainTabViewMiscDef    = require("LobbyCaptainTabViewMiscDef")
local UILobbyCaptainHelper          = require("UILobbyCaptainHelper")
local UIResourceDef                 = require("UIResourceDef")
local UITextDef                     = require("UITextDef")
local ItemSystem                    = require("ItemSystem")

local FashionType = HumanAvatarDef.FashionType
local FASHION_ARMOR_NAME = UITextDef.FASHION_ARMOR_NAME
local FashionSlotCategoryExtend = HumanAvatarDef.FashionSlotCategoryExtend
local TabIndexToFashionSlotCategoryExtend = LobbyCaptainMiscDef.TabIndexToFashionSlotCategoryExtend
local FashionSlotCategoryExtendToTabIndex = LobbyCaptainMiscDef.FashionSlotCategoryExtendToTabIndex

local NOT_ACTIVE = 
{
    [FashionType.Knight] = true
}

local function GetRemainCanUseSeconds(tbItem)
    if tbItem:HasExpiration() then
        return true, tbItem:GetRemainCanUseSeconds()
    else
        return false
    end 
end


local function DecorateData(tbOutData)
    for _, tbData in pairs(tbOutData) do
        local tbTemplate = tbData.tbTemplate
        local bSuit = tbTemplate.nCategory == ItemCategoryDef.SUIT
        local nTemplateId = tbData.nTemplateId
        local bOwned, tbItems = ItemSystem:HasFashionItem(nTemplateId)
        tbData.bOwned = bOwned
        if bOwned then
            if bSuit then
                local bEquiped = true
                local bNew = true
                for _, tbItem in ipairs(tbItems) do
                    local nItemInstanceId = tbItem:GetInstanceId()
                    if not ItemSystem:IsEquiped(nItemInstanceId) then
                        bEquiped = false
                    end

                    if not UILobbyCaptainHelper.IsNewHumanFashion(nItemInstanceId) then
                        bNew = false
                    end
                end
                tbData.bEquiped = bEquiped
                tbData.bRedDot = bNew
                local nRemainTime
                for _, tbItem in ipairs(tbItems) do
                    local bHas, nTempTime = GetRemainCanUseSeconds(tbItem)
                    if bHas then
                        if not nRemainTime then
                            nRemainTime = nTempTime
                        else
                            nRemainTime = math.min(nRemainTime, nTempTime)
                        end
                    end
                end
                tbData.nRemainTime = nRemainTime
                
            else
                local tbItem = tbItems[1]
                local nItemInstanceId = tbItem:GetInstanceId()
                tbData.bRedDot = UILobbyCaptainHelper.IsNewHumanFashion(nItemInstanceId)
                tbData.bEquiped = ItemSystem:IsEquiped(nItemInstanceId)

                local _, nRemainTime = GetRemainCanUseSeconds(tbItem)
                tbData.nRemainTime = nRemainTime
            end
        else
            tbData.bEquiped = false
        end
    end
end

local GRADE_WEIGHT = 10000000
local OWN_WEIGHT = 100000000

local function CalWeight(tbData)
    local nWeight
    if tbData.bEquiped then
        nWeight = math.maxinteger
    else
        local nItemTemplateId = tbData.nTemplateId
        local tbTemplate = ItemSystem:GetItemTemplate(nItemTemplateId)
        local nGrade = tbTemplate.nGrade
        nWeight = nGrade * GRADE_WEIGHT  + nItemTemplateId

        if tbData.bOwned then
            nWeight = OWN_WEIGHT + nWeight
        end
    end
    return nWeight
end

local function SortData(tbDataA, tbDataB)
    local nWeightA = CalWeight(tbDataA)
    local nWeightB = CalWeight(tbDataB)
    return nWeightA > nWeightB
end


--@Return {nFashion : l10nFashionName}
function LobbyCaptainHumanFashionFilterImpl:GetCategoryInfos()
    local tbCategoryInfo = {}
    for _, nType in pairs(FashionType) do
        if not NOT_ACTIVE[nType] then
            local tbData = {}
            tbData[LobbyCaptainTabViewMiscDef.KEY_DESC] = FASHION_ARMOR_NAME[nType]
            tbCategoryInfo[nType] = tbData
        end
    end
    return tbCategoryInfo
end

--@Return {nSlotType : szSlotDefaultIcon}
function LobbyCaptainHumanFashionFilterImpl:GetSubCategoryInfos()
    local tbDefaultIcons = UIResourceDef.LOBBY_HUMAN_SLOT_ICON
    local tbSubcategoryInfo = {}
    for _, nSubType in pairs(FashionSlotCategoryExtend) do
        local tbData = {}
        local nTabIndex = FashionSlotCategoryExtendToTabIndex[nSubType]
        tbData[LobbyCaptainTabViewMiscDef.KEY_ICON_SELECTED] = tbDefaultIcons[nSubType][1]
        tbData[LobbyCaptainTabViewMiscDef.KEY_ICON_UNSELECTED] = tbDefaultIcons[nSubType][2]
        tbSubcategoryInfo[nTabIndex] = tbData
    end
    return tbSubcategoryInfo
end

function LobbyCaptainHumanFashionFilterImpl:FilterData(nTabCategory, nSubTabCategory)
    local nSlotCategoryExtend = TabIndexToFashionSlotCategoryExtend[nSubTabCategory]
    local tbOutDatas = {}
    if nSlotCategoryExtend == FashionSlotCategoryExtend.Suit then
        local tbItemTemplateFieldFilterData = {}
        tbItemTemplateFieldFilterData.nFashionType = nTabCategory
        UILobbyCaptainHelper.CreateCandidateTemplates(tbOutDatas, ItemCategoryDef.SUIT, tbItemTemplateFieldFilterData)
    else
        local tbItemTemplateFieldFilterData = {}
        tbItemTemplateFieldFilterData.nFashionType = nTabCategory
        tbItemTemplateFieldFilterData.nSubCategory = nSlotCategoryExtend
        UILobbyCaptainHelper.CreateCandidateTemplates(tbOutDatas, ItemCategoryDef.FASHION, tbItemTemplateFieldFilterData)
    end
    DecorateData(tbOutDatas)
    table.sort(tbOutDatas, SortData)
    self.tbCacheData = tbOutDatas
    return tbOutDatas
end

function LobbyCaptainHumanFashionFilterImpl:UpdateCurrentDatas()
    if self.tbCacheData then
        DecorateData(self.tbCacheData)
    end
    return self.tbCacheData
end

return LobbyCaptainHumanFashionFilterImpl
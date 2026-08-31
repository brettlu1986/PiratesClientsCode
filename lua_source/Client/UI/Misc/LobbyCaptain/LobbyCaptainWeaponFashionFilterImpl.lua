local luaclass = require("luaclass")
local LobbyCaptainTabViewFilter = require("LobbyCaptainTabViewFilter")

local LobbyCaptainWeaponFashionFilterImpl = luaclass("LobbyCaptainWeaponFashionFilterImpl", LobbyCaptainTabViewFilter)

local LobbyWeaponMiscDataTable = require("LobbyWeaponMiscDataTable")
local ItemSystem = require("ItemSystem")
local ItemCategoryDef = require("ItemCategoryDef")
local UILobbyCaptainHelper = require("UILobbyCaptainHelper")
local LobbyCaptainTabViewMiscDef = require("LobbyCaptainTabViewMiscDef")

local function DecorateData(tbOutData)
    for _, tbData in pairs(tbOutData) do
        local tbTemplate = tbData.tbTemplate
        local nItemTemplateId = tbData.nTemplateId
        tbData.nWeaponInstanceType = tbTemplate.nSubCategory
        local tbItems = ItemSystem:GetItemsByTemplateId(nItemTemplateId)
        tbData.bOwned = #tbItems > 0
        if tbData.bOwned then
            local tbItem = tbItems[1]
            local nItemInstanceId = tbItem:GetInstanceId()
            tbData.nInstanceId = nItemInstanceId
            tbData.bEquiped = ItemSystem:IsEquiped(nItemInstanceId)
            tbData.bRedDot = UILobbyCaptainHelper.IsNewHumanWeaponFashion(nItemInstanceId)
            if tbItem:HasExpiration() then
                tbData.nRemainTime = tbItem:GetRemainCanUseSeconds()
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
        nWeight = nGrade * GRADE_WEIGHT + nItemTemplateId

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
function LobbyCaptainWeaponFashionFilterImpl:GetCategoryInfos()
    local tbCategoryInfo = {}
    local tbTemplates = LobbyWeaponMiscDataTable:GetAllTemplates()
    for nInstanceType, tbTemplate in pairs(tbTemplates) do
        if tbTemplate.bActive then
            local tbData = {}
            tbData[LobbyCaptainTabViewMiscDef.KEY_DESC] = tbTemplate.l10nDesc
            tbCategoryInfo[nInstanceType] = tbData
        end
    end
    return tbCategoryInfo
end

function LobbyCaptainWeaponFashionFilterImpl:GetSubCategoryInfos()
    return nil
end


function LobbyCaptainWeaponFashionFilterImpl:FilterData(nTabCategory, _nSubTabCategory)
    local tbOutDatas = {}
    local tbItemTemplateFieldFilterData = {}
    tbItemTemplateFieldFilterData.nSubCategory = nTabCategory
    UILobbyCaptainHelper.CreateCandidateTemplates(tbOutDatas, ItemCategoryDef.HUMAN_WEAPON_FASHION, tbItemTemplateFieldFilterData)
    DecorateData(tbOutDatas)
    table.sort(tbOutDatas, SortData)
    self.tbCacheData = tbOutDatas
    return tbOutDatas
end


function LobbyCaptainWeaponFashionFilterImpl:UpdateCurrentDatas()
    if self.tbCacheData then
        DecorateData(self.tbCacheData)
    end
    return self.tbCacheData
end



return LobbyCaptainWeaponFashionFilterImpl
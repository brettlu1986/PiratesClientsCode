--[[
    DataTable类中必须有的成员变量与函数
    szFileName : 文件名，不包含路径
    Container: table
    OnEditorParseLine： 解析函数，参数Parser

    可选的变量与函数
    OnEditorParseFinished: 参数无，本DataTable读取完毕后触发
    OnGameRequired: 参数无，游戏运行时第一次require时触发
    OnEditorDefine: 定义导出参数    自定义导出标签：
         导出单行：-- [EXPORT]
         导出多行：-- [EXPORT BEGIN] 和 -- [EXPORT END]
--]]
local BattleItemBuildDataTable = {}

local BattleItemDataTable = require("BattleItemDataTable")
local BattleItemCategoryDef = require("BattleItemCategoryDef")

local ProgressBarTableNew = require("ProgressBarTableNew")

BattleItemBuildDataTable.szFileName = "common/ffa/item/item_build.tab"

-- [EXPORT]
BattleItemBuildDataTable.tbCategoryDefaultItemBuildInfos = {}

-- [EXPORT]
BattleItemBuildDataTable.tbSameBaseItemBuildInfos = {}

-- [EXPORT]
BattleItemBuildDataTable.tbItemBuildKeyInfos = {}

function BattleItemBuildDataTable:OnEditorDefine(Parser)
    Parser:Define("nId", "id", -1, Parser.TypeInt)
    Parser:Define("nPrerequisiteId", "prerequisite_id", -1, Parser.TypeInt)
    Parser:Define("tbKeyItemIds", "key_item_ids", nil, Parser.TypeArrayInt)
    Parser:Define("tbCosts", "costs", nil, Parser.TypeArrayInt)
    Parser:Define("nProgressBar", "progress_bar", 0, Parser.TypeInt)
    Parser:Define("bIsDefault", "is_default", false, Parser.TypeBool)
    Parser:Define("nQuickBuildWeight", "quick_build_weight", -1, Parser.TypeInt)
end

local function CheckItemTemplateId(tbNewTemplate)
    local nItemTemplateId = tbNewTemplate.nId
    local tbItemTemplate = BattleItemDataTable:GetTemplate(nItemTemplateId)
    if tbItemTemplate == nil then
        error("Parse item_build.tab failed! tbItemTemplate is nil!"..nItemTemplateId)
    end
end

local function CheckPrerequisiteId(tbNewTemplate)
    local nItemTemplateId = tbNewTemplate.nId
    local nPrerequisiteId = tbNewTemplate.nPrerequisiteId
    if nPrerequisiteId > 0 then
        local tbPrerequisiteItemTemplate = BattleItemDataTable:GetTemplate(nPrerequisiteId)
        if tbPrerequisiteItemTemplate == nil then
            error("Parse item_build.tab failed! tbPrerequisiteItemTemplate is nil!nItemTemplateId "..nItemTemplateId.." ,nPrerequisiteId "..nPrerequisiteId)
        end
    end
end

local function FillBuildKeyItemData(self, tbNewTemplate)
    local nItemTemplateId = tbNewTemplate.nId
    local tbKeyItemIds = tbNewTemplate.tbKeyItemIds
    if tbKeyItemIds and #tbKeyItemIds > 0 then
        for _, v in ipairs(tbKeyItemIds) do
            if self.tbItemBuildKeyInfos[v] == nil then
                self.tbItemBuildKeyInfos[v] = nItemTemplateId
            end
        end
    end
end

local function CheckKeyItemId(tbNewTemplate)
    local nItemTemplateId = tbNewTemplate.nId
    local tbKeyItemIds = tbNewTemplate.tbKeyItemIds
    if tbKeyItemIds and #tbKeyItemIds > 0 then
        for _, v in ipairs(tbKeyItemIds) do
            local tbKeyItemTemplate = BattleItemDataTable:GetTemplate(v)
            if tbKeyItemTemplate == nil then
                error("Parse item_build.tab failed! tbKeyItemTemplate is nil!nItemTemplateId "..nItemTemplateId.." ,keyid "..v)
            end
        end
    end
end

local function CheckMaterialCost(tbNewTemplate)
    local nItemTemplateId = tbNewTemplate.nId
    local tbCostItemTemplates = BattleItemDataTable:GetTemplatesByCategory(BattleItemCategoryDef.MATERIAL)
    local nMaterialTypeCount = 0
    for _, v in pairs(tbCostItemTemplates) do
        nMaterialTypeCount = nMaterialTypeCount + 1
    end
    local tbCosts = tbNewTemplate.tbCosts
    if tbCosts and #tbCosts ~= nMaterialTypeCount then
        error("Parse item_build.tab failed! cost type not equal to nMaterialTypeCount!nItemTemplateId ".. nItemTemplateId
              ..", #tbCosts "..#tbCosts..", nMaterialTypeCount "..nMaterialTypeCount)
    end
end

local function CheckProgressBar(tbNewTemplate)
    local nItemTemplateId = tbNewTemplate.nId
    local nProgressBar = tbNewTemplate.nProgressBar
    local tbProgressBarTemplate = ProgressBarTableNew:GetTemplate(nProgressBar)
    if not tbProgressBarTemplate then
        error("Parse item_build.tab failed! Cannot find  nProgressBar! nItemTemplateId ".. nItemTemplateId ..", nProgressBar "..nProgressBar)
    end
end

function BattleItemBuildDataTable:OnEditorParseLine(Parser, tbContainer, tbNewTemplate)

    CheckItemTemplateId(tbNewTemplate)
    CheckPrerequisiteId(tbNewTemplate)
    CheckKeyItemId(tbNewTemplate)
    CheckMaterialCost(tbNewTemplate)
    CheckProgressBar(tbNewTemplate)

    local nItemTemplateId = tbNewTemplate.nId
    self.tbContainer[nItemTemplateId] = tbNewTemplate

    FillBuildKeyItemData(self, tbNewTemplate)
    if tbNewTemplate.bIsDefault then
        local tbItemTemplate = BattleItemDataTable:GetTemplate(nItemTemplateId)
        local nCategory = tbItemTemplate.nCategory
        local tbCategoryDefaultItemBuildInfos = self.tbCategoryDefaultItemBuildInfos
        local tbItemBuildInfos = tbCategoryDefaultItemBuildInfos[nCategory]
        if tbItemBuildInfos == nil then
            tbCategoryDefaultItemBuildInfos[nCategory] = {}
            tbItemBuildInfos = tbCategoryDefaultItemBuildInfos[nCategory]
        end
        table.insert(tbItemBuildInfos, tbNewTemplate)
    end
    return true
end

local function GetBaseItemTemplateId(self, tbTemplate)
    local nPrerequisiteId = tbTemplate.nPrerequisiteId
    if nPrerequisiteId > 0 then
        local tbPrerequisiteBuildTemplate = self.tbContainer[nPrerequisiteId]
        if tbPrerequisiteBuildTemplate then
            return GetBaseItemTemplateId(self, tbPrerequisiteBuildTemplate)
        else
            return nPrerequisiteId
        end
    else
        return nil
    end
end

function BattleItemBuildDataTable:OnEditorParseFinished()
    for _, v1 in pairs(self.tbCategoryDefaultItemBuildInfos) do
        for _, v2 in pairs(v1) do
            local nBaseItemTemplateId = GetBaseItemTemplateId(self, v2)
            if nBaseItemTemplateId ~= nil then
                v2.nBaseItemTemplateId = nBaseItemTemplateId
                local tbInfos = self.tbSameBaseItemBuildInfos[nBaseItemTemplateId]
                if tbInfos == nil then
                    self.tbSameBaseItemBuildInfos[nBaseItemTemplateId] = {}
                    tbInfos = self.tbSameBaseItemBuildInfos[nBaseItemTemplateId]
                end
                table.insert(tbInfos, v2)
            end
        end
    end

    local tbItemTemplates = BattleItemDataTable:GetTemplatesByCategory(BattleItemCategoryDef.BUILD_KEY_ITEM)
    for _, v in pairs(tbItemTemplates) do
        local nBuildItemTemplateId = self:GetKeyItemBuildItemTemplateId(v.nId)
        if nBuildItemTemplateId == nil then
            error("Cannot find key item build item!"..v.nId)
        end
    end
end

-- [EXPORT BEGIN]
function BattleItemBuildDataTable:GetBuildTemplate(nId)
    return self.tbContainer[nId]
end
-- [EXPORT END]

-- [EXPORT BEGIN]
function BattleItemBuildDataTable:GetDefaultBuildTemplatesByCategory(nCategory)
    return self.tbCategoryDefaultItemBuildInfos[nCategory]
end
-- [EXPORT END]

-- [EXPORT BEGIN]
function BattleItemBuildDataTable:GetKeyItemBuildItemTemplateId(nKeyItemTemplateId)
    return self.tbItemBuildKeyInfos[nKeyItemTemplateId]
end
-- [EXPORT END]

-- [EXPORT BEGIN]
function BattleItemBuildDataTable:GetSameBaseBuildItemTemplates(nItemTemplateId)
    local tbBuildTemplate = self.tbContainer[nItemTemplateId]
    if tbBuildTemplate then
        if tbBuildTemplate.nBaseItemTemplateId then
            return self.tbSameBaseItemBuildInfos[tbBuildTemplate.nBaseItemTemplateId]
        else
            return {}
        end
    else
        local tbSameBaseTemplates = self.tbSameBaseItemBuildInfos[nItemTemplateId]
        if tbSameBaseTemplates then
            return tbSameBaseTemplates
        else
            return {}
        end
    end
end
-- [EXPORT END]

-- [EXPORT BEGIN]
function BattleItemBuildDataTable:IsSameBaseItemTemplateIds(nItemTemplateId1, nItemTemplateId2)
    if nItemTemplateId1 == nil or nItemTemplateId2 == nil then
        error("Param is nil!")
    end
    if nItemTemplateId1 == nItemTemplateId2 then
        return true
    end
    local tbSameBaseBuildItemTemplates1 = self:GetSameBaseBuildItemTemplates(nItemTemplateId1)
    local tbSameBaseBuildItemTemplates2 = self:GetSameBaseBuildItemTemplates(nItemTemplateId2)
    if tbSameBaseBuildItemTemplates1 == nil or tbSameBaseBuildItemTemplates2 == nil or #tbSameBaseBuildItemTemplates1 == 0 or #tbSameBaseBuildItemTemplates2 == 0 then
        return false
    end
    if tbSameBaseBuildItemTemplates1[1].nBaseItemTemplateId == tbSameBaseBuildItemTemplates2[1].nBaseItemTemplateId then
        return true
    end
    return false
end
-- [EXPORT END]

return BattleItemBuildDataTable

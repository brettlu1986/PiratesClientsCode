--[[
    DataTable类中必须有的成员变量与函数
    szFileName : 文件名，不包含路径
    tbContainer: table
    OnEditorParseLine： 解析函数，参数Parser

    可选的变量与函数
    OnEditorParseFinished: 参数无，本DataTable读取完毕后触发
    OnGameRequired: 参数无，游戏运行时第一次require时触发
    OnEditorDefine: 定义导出参数    自定义导出标签：
         导出单行：-- [EXPORT]
         导出多行：-- [EXPORT BEGIN] 和 -- [EXPORT END]
--]]
local BattleItemDataTable = {}

local L10N = require("L10N")
local DataTableExporter = require("DataTableExporter")
-- [EXPORT]
local BattleItemResDataTable = require("BattleItemResDataTable")
BattleItemDataTable.szFileName = "common/ffa/item/item_sub_category.tab"

local bLoadingSubFile = false

local nCurrentMinId = -1
local nCurrentMaxId = -1
local nCurrentCategory = -1
local nCurrentSubCategory = -1
local szCurrentExtraDataHelper = nil

-- [EXPORT]
BattleItemDataTable.tbCategoryInfoTable = {}

-- [EXPORT]
BattleItemDataTable.tbCategoryTemplates = {}

-- 根据配置表里配置的helper文件来读取不同物品类型额外的属性
local function OnEditorParseSubTableExtraData(self, Parser, tbNewTemplate)
    if szCurrentExtraDataHelper ~= nil and szCurrentExtraDataHelper ~= "" then
        require(szCurrentExtraDataHelper).ParseExtraAttriLine(Parser, tbNewTemplate)
    end
end

local function ValidateAttriLine(self, tbNewTemplate)
    if szCurrentExtraDataHelper ~= nil and szCurrentExtraDataHelper ~= "" then
        local tbDataHelper = require(szCurrentExtraDataHelper)
        if tbDataHelper.ValidateAttriLine then
            tbDataHelper.ValidateAttriLine(tbNewTemplate)
        end
    end
end

function BattleItemDataTable:OnEditorDefine(Parser)
    Parser:Define("nCategory", "category", -1, Parser.TypeInt)
    Parser:Define("nSubCategory", "sub_category", -1, Parser.TypeInt)
    Parser:Define("szSubCategoryName", "sub_category_name", L10N.NullString, Parser.TypeL10N)
    Parser:Define("nMinId", "min_id", -1, Parser.TypeInt)
    Parser:Define("nMaxId", "max_id", -1, Parser.TypeInt)
    Parser:Define("szPath", "path", nil, Parser.TypeString)
    Parser:Define("szExtraDataHelper", "extra_data_helper", nil, Parser.TypeString)
    Parser:Define("szItemClass", "item_class", nil, Parser.TypeString)
end

function BattleItemDataTable:OnEditorParseLine(Parser, tbContainer, tbNewTemplate)
    local tbCategoryInfoTable = self.tbCategoryInfoTable
    local tbInfos = tbCategoryInfoTable[tbNewTemplate.nCategory]
    if tbInfos == nil then
        tbCategoryInfoTable[tbNewTemplate.nCategory] = {}
        tbInfos = tbCategoryInfoTable[tbNewTemplate.nCategory]
    end
    tbInfos[tbNewTemplate.nSubCategory] = tbNewTemplate
    return true
end

function BattleItemDataTable:OnEditorParseSubLine(Parser, tbContainer, tbNewTemplate)
    local nId = tbNewTemplate.nId
    if nId < nCurrentMinId or nId > nCurrentMaxId then
        error("Parse Item Id Not Valid! Category:"..nCurrentCategory
        ..", SubCategory:".. nCurrentSubCategory
        ..", minId:".. nCurrentMinId..", maxId:"..nCurrentMaxId..",invalid id:"..nId)
    end
    tbNewTemplate.nCategory = nCurrentCategory
    tbNewTemplate.nSubCategory = nCurrentSubCategory

    OnEditorParseSubTableExtraData(self, Parser, tbNewTemplate)

    local nStackLimit = tbNewTemplate.nStackLimit

    if nStackLimit ~= nil and nStackLimit > 1 then
        tbNewTemplate.bStackable = true
    else
        tbNewTemplate.bStackable = false
    end

    self.tbContainer[nId] = tbNewTemplate

    local tbTemplates = self.tbCategoryTemplates[nCurrentCategory]
    if tbTemplates == nil then
        self.tbCategoryTemplates[nCurrentCategory] = {}
        tbTemplates = self.tbCategoryTemplates[nCurrentCategory]
    end
    tbTemplates[nId] = tbNewTemplate

    ValidateAttriLine(self, tbNewTemplate)

    return true
end

function BattleItemDataTable:OnEditorSubTableDefine(Parser)
    Parser:Define("nId", "id", -1, Parser.TypeInt)
    Parser:Define("l10nName", "name", L10N.NullString, Parser.TypeL10N)
    Parser:Define("l10nDesc", "desc", L10N.NullString, Parser.TypeL10N)
    Parser:Define("l10nDetailedDesc", "detailed_desc", L10N.NullString, Parser.TypeL10N)

    -- 根据物品需求来决定是否在配置表里有这些列
    Parser:Define("nResId", "res_id", -1, Parser.TypeInt, false)
    Parser:Define("nColorGrade", "color_grade", 0, Parser.TypeInt, false)
    Parser:Define("nGrade", "grade", 0, Parser.TypeInt, false)
    Parser:Define("nWeight", "weight", 0, Parser.TypeFloat, false)
    Parser:Define("nStackLimit", "stack_limit", 0, Parser.TypeInt, false)
    Parser:Define("nBattleScore", "battle_score", 0, Parser.TypeInt, false)
end

function BattleItemDataTable:OnEditorParseFinished()
    if bLoadingSubFile then
        return
    end
    local szOldPath = self.szFileName
    bLoadingSubFile = true
    local fnOldDefine = self.OnEditorDefine
    local fnOldParseLine = self.OnEditorParseLine

    for k1, v1 in pairs(self.tbCategoryInfoTable) do
        for k2, v2 in pairs(v1) do
            self.szFileName = v2.szPath
            self.OnEditorDefine = self.OnEditorSubTableDefine
            self.OnEditorParseLine = self.OnEditorParseSubLine
            nCurrentMinId = v2.nMinId
            nCurrentMaxId = v2.nMaxId
            nCurrentCategory = v2.nCategory
            nCurrentSubCategory = v2.nSubCategory
            szCurrentExtraDataHelper = v2.szExtraDataHelper
            if not DataTableExporter:Load(self) then
                logerror("BattleItemDataTable load sub table failed", self.szFileName)
                assert(false)
            end
        end
    end

    bLoadingSubFile = false
    self.OnEditorDefine = fnOldDefine
    self.OnEditorParseLine = fnOldParseLine
    self.szFileName = szOldPath
end

-- [EXPORT BEGIN]
function BattleItemDataTable:GetTemplate(nTemplateId)
    return self.tbContainer[nTemplateId]
end
-- [EXPORT END]

-- [EXPORT BEGIN]
function BattleItemDataTable:GetResTemplate(nTemplateId)
    local tbTemplate = self.tbContainer[nTemplateId]
    if tbTemplate then
        return BattleItemResDataTable:GetTemplate(tbTemplate.nResId)
    end
    return nil
end
-- [EXPORT END]

-- [EXPORT BEGIN]
function BattleItemDataTable:GetColorGrade(nTemplateId)
    local tbTemplate = self.tbContainer[nTemplateId]
    return tbTemplate.nColorGrade
end

function BattleItemDataTable:GetGrade(nTemplateId)
    local tbTemplate = self.tbContainer[nTemplateId]
    return tbTemplate.nGrade
end
-- [EXPORT END]

-- [EXPORT BEGIN]
function BattleItemDataTable:GetTemplatesByCategory(nCategory)
    return self.tbCategoryTemplates[nCategory]
end
-- [EXPORT END]

-- [EXPORT BEGIN]
function BattleItemDataTable:GetAllCategoryInfoTable()
    return self.tbCategoryInfoTable
end
-- [EXPORT END]

-- [EXPORT BEGIN]
function BattleItemDataTable:GetItemClass(nCategory, nSubCategory)
    local tbSubInfos = self.tbCategoryInfoTable[nCategory]
    if tbSubInfos == nil then
        error("BattleItemDataTable:GetItemClass failed! category:"..nCategory..", nSubCategory:"..nSubCategory)
    end
    local tbInfo = tbSubInfos[nSubCategory]
    if tbInfo == nil then
        error("BattleItemDataTable:GetItemClass failed! category:"..nCategory..", nSubCategory:"..nSubCategory)
    end
    return tbInfo.szItemClass
end
-- [EXPORT END]

-- [EXPORT BEGIN]
function BattleItemDataTable:GetSubCategoryName(nCategory, nSubCategory)
    local tbSubInfos = self.tbCategoryInfoTable[nCategory]
    if tbSubInfos == nil then
        error("BattleItemDataTable:GetSubCategoryName failed! category:"..nCategory..", nSubCategory:"..nSubCategory)
    end
    local tbInfo = tbSubInfos[nSubCategory]
    if tbInfo == nil then
        error("BattleItemDataTable:GetSubCategoryName failed! category:"..nCategory..", nSubCategory:"..nSubCategory)
    end
    return tbInfo.szSubCategoryName
end
-- [EXPORT END]

return BattleItemDataTable

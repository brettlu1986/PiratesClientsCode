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
local ItemDataTable = {}

local L10N = require("L10N")
local DataTableExporter = require("DataTableExporter")
-- local ItemCategoryDef = require("ItemCategoryDef")
local ItemExpireDef = require("ItemExpireDef")

-- [EXPORT]
local ItemResDataTable = require("ItemResDataTable")
ItemDataTable.szFileName = "common/item2/item_category.tab"

local bLoadingSubFile = false

local nCurrentMinId = -1
local nCurrentMaxId = -1
local nCurrentCategory = -1
local nCurrentExpireType = -1
local szCurrentExtraDataHelper = nil

-- [EXPORT]
ItemDataTable.tbCategoryInfoTable = {}

-- [EXPORT]
ItemDataTable.tbCategoryTemplates = {}

-- [EXPORT]
ItemDataTable.tbBattleItemIdToLobbyItemId = {}

-- 根据配置表里配置的helper文件来读取不同物品类型额外的属性
local function OnEditorParseSubTableExtraData(self, Parser, tbNewTemplate)
    if szCurrentExtraDataHelper ~= nil and szCurrentExtraDataHelper ~= "" then
        require(szCurrentExtraDataHelper).ParseExtraAttriLine(Parser, tbNewTemplate)
    end
end

function ItemDataTable:OnEditorDefine(Parser)
    Parser:Define("nCategory", "category", -1, Parser.TypeInt)
    Parser:Define("szCategoryName", "category_name", L10N.NullString, Parser.TypeL10N)
    Parser:Define("nMinId", "min_id", -1, Parser.TypeInt)
    Parser:Define("nMaxId", "max_id", -1, Parser.TypeInt)
    Parser:Define("nSortValue", "sort_value", -1, Parser.TypeInt)
    Parser:Define("szPath", "path", nil, Parser.TypeString)
    Parser:Define("szExtraDataHelper", "extra_data_helper", nil, Parser.TypeString)
    Parser:Define("szExpireType", "expire_type", nil, Parser.TypeString)
end

function ItemDataTable:OnEditorParseLine(Parser, tbContainer, tbNewTemplate)
    tbNewTemplate.nExpireType = ItemExpireDef.GetExpireType(tbNewTemplate.szExpireType)
    self.tbCategoryInfoTable[tbNewTemplate.nCategory] = tbNewTemplate
    return true
end

function ItemDataTable:OnEditorParseSubLine(Parser, tbContainer, tbNewTemplate)
    local nId = tbNewTemplate.nId
    if nId < nCurrentMinId or nId > nCurrentMaxId then
        error("Parse Item Id Not Valid! Category:"..nCurrentCategory
            ..", minId:".. nCurrentMinId..", maxId:"..nCurrentMaxId..",invalid id:"..nId)
    end
    tbNewTemplate.nCategory = nCurrentCategory
    tbNewTemplate.nExpireType = nCurrentExpireType

    OnEditorParseSubTableExtraData(self, Parser, tbNewTemplate)

    local nStackLimit = tbNewTemplate.nStackLimit

    if nStackLimit ~= nil and nStackLimit > 1 then
        tbNewTemplate.bStackable = true
    else
        tbNewTemplate.bStackable = false
    end

    local nExpirationSeconds = tbNewTemplate.nExpirationSeconds
    if nExpirationSeconds ~= nil and nExpirationSeconds > 0 then
        tbNewTemplate.bHasExpiration = true
    else
        tbNewTemplate.bHasExpiration = false
    end

    local nSellPrice = tbNewTemplate.nSellPrice
    if nSellPrice ~= nil and nSellPrice > 0 then
        tbNewTemplate.bCanSell = true
    else
        tbNewTemplate.bCanSell = false
    end

    if tbNewTemplate.bCanSell then
        if tbNewTemplate.nCurrencyId <= 0 then
            error("Item can sell but cannot find sell currency id!".. tbNewTemplate.nId)
        end
    end

    if tbNewTemplate.bHasExpiration and (not tbNewTemplate.bCanSell) then
        error("Item has expiration but cannot sell!".. tbNewTemplate.nId)
    end

    if ItemResDataTable:GetTemplate(tbNewTemplate.nResId) == nil then
        error("Item cannot find res id!".. tbNewTemplate.nId..","..tbNewTemplate.nResId)
    end

    local nHoldLimit = tbNewTemplate.nHoldLimit
    if nHoldLimit ~= nil and nHoldLimit > 0 then
        tbNewTemplate.bHasHoldLimit = true
        if nHoldLimit ~= tbNewTemplate.nStackLimit then
            error("Item has hold limit! But hold limit not equip to stack limit!".. tbNewTemplate.nId)
        end
    else
        tbNewTemplate.bHasHoldLimit = false
    end

    self.tbContainer[nId] = tbNewTemplate

    local tbTemplates = self.tbCategoryTemplates[nCurrentCategory]
    if tbTemplates == nil then
        self.tbCategoryTemplates[nCurrentCategory] = {}
        tbTemplates = self.tbCategoryTemplates[nCurrentCategory]
    end
    tbTemplates[nId] = tbNewTemplate

    return true
end

function ItemDataTable:OnEditorSubTableDefine(Parser)
    Parser:Define("nId", "id", -1, Parser.TypeInt)

    Parser:Define("nSubCategory", "sub_category", -1, Parser.TypeInt)

    Parser:Define("l10nName", "name", L10N.NullString, Parser.TypeL10N)
    Parser:Define("l10nIntro", "intro", L10N.NullString, Parser.TypeL10N)

    Parser:Define("nGrade", "grade", 0, Parser.TypeInt)

    Parser:Define("nResId", "res_id", -1, Parser.TypeInt)

    Parser:Define("nCurrencyId", "currency_id", 0, Parser.TypeInt)
    Parser:Define("nSellPrice", "sell_price", 0, Parser.TypeInt)

    Parser:Define("nHoldLimit", "hold_limit", 0, Parser.TypeInt)
    Parser:Define("nStackLimit", "stack_limit", 0, Parser.TypeInt)

    Parser:Define("nUseLevel", "use_level", 0, Parser.TypeInt)
    Parser:Define("nUseGender", "use_gender", 0, Parser.TypeInt)

    Parser:Define("nExpirationSeconds", "expiration", 0, Parser.TypeInt)

end

function ItemDataTable:OnEditorParseFinished()
    if bLoadingSubFile then
        return
    end
    local szOldPath = self.szFileName
    bLoadingSubFile = true
    local fnOldDefine = self.OnEditorDefine
    local fnOldParseLine = self.OnEditorParseLine

    for k, v in pairs(self.tbCategoryInfoTable) do
        self.szFileName = v.szPath
        self.OnEditorDefine = self.OnEditorSubTableDefine
        self.OnEditorParseLine = self.OnEditorParseSubLine
        nCurrentMinId = v.nMinId
        nCurrentMaxId = v.nMaxId
        nCurrentCategory = v.nCategory
        nCurrentExpireType = v.nExpireType
        szCurrentExtraDataHelper = v.szExtraDataHelper
        if not DataTableExporter:Load(self) then
            error("ItemDataTable load sub table failed".. self.szFileName)
        end
    end

    bLoadingSubFile = false
    self.OnEditorDefine = fnOldDefine
    self.OnEditorParseLine = fnOldParseLine
    self.szFileName = szOldPath

    local tbBlackboardData = {}

    for k, v in pairs(self.tbCategoryInfoTable) do
        local szExtraDataHelper = v.szExtraDataHelper
        if szExtraDataHelper ~= nil and szExtraDataHelper ~= "" then
            local tbDataHelper = require(szExtraDataHelper)
            if tbDataHelper.OnEditorParseFinished then
                tbDataHelper.OnEditorParseFinished(self.tbCategoryTemplates[k], tbBlackboardData) --有跨表操作需求 故增加第二个参数
            end
            if tbDataHelper.FillBattleItemIdToLobbyItemId then
                tbDataHelper.FillBattleItemIdToLobbyItemId(self.tbCategoryTemplates[k], self.tbBattleItemIdToLobbyItemId)
            end
        end
    end

    for k, v in pairs(self.tbCategoryInfoTable) do
        local szExtraDataHelper = v.szExtraDataHelper
        if szExtraDataHelper ~= nil and szExtraDataHelper ~= "" then
            local tbDataHelper = require(szExtraDataHelper)
            if tbDataHelper.PostProcessBlackboardData then
                tbDataHelper.PostProcessBlackboardData(self.tbCategoryTemplates[k], tbBlackboardData) --有跨表操作需求 故增加第二个参数
            end
        end
    end
end

-- [EXPORT BEGIN]
function ItemDataTable:GetSortValue(nCategory)
    local tbTemplate = self.tbCategoryInfoTable[nCategory]
    if tbTemplate == nil then
        error("ItemDataTable:GetSortValue failed! category:"..nCategory)
    end
    return tbTemplate.nSortValue
end
-- [EXPORT END]

-- [EXPORT BEGIN]
function ItemDataTable:GetTemplate(nTemplateId)
    return self.tbContainer[nTemplateId]
end
-- [EXPORT END]

-- [EXPORT BEGIN]
function ItemDataTable:GetResTemplate(nTemplateId)
    local tbTemplate = self.tbContainer[nTemplateId]
    if tbTemplate then
        return ItemResDataTable:GetTemplate(tbTemplate.nResId)
    end
    return nil
end
-- [EXPORT END]

-- [EXPORT BEGIN]
function ItemDataTable:GetTemplatesByCategory(nCategory)
    return self.tbCategoryTemplates[nCategory]
end
-- [EXPORT END]

-- [EXPORT BEGIN]
function ItemDataTable:GetLobbyItemId(nBattleItemId)
    return self.tbBattleItemIdToLobbyItemId[nBattleItemId]
end
-- [EXPORT END]

return ItemDataTable

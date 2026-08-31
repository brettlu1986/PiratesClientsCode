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
local ShopDataTable = {}

local DataTableExporter = require("DataTableExporter")
local L10N = require("L10N")
local ItemDataTable = require("ItemDataTable")
local TimeUtil = require("TimeUtil")
local ItemCategoryDef = require("ItemCategoryDef")

ShopDataTable.szFileName = "common/shop/shop.tab"

local bLoadingSubFile = false

local nCurrentMinId = -1
local nCurrentMaxId = -1
local nCurrentShopId = -1

local TAB_MAX = 6
local COMMON_CURRENCY_IDS = {1400000, 1400001, 1400002}

-- [EXPORT]
ShopDataTable.tbShopInfos = {}

-- [EXPORT]
ShopDataTable.tbShopGoods = {}

-- [EXPORT]
ShopDataTable.tbItemToGoods = {}

-- [EXPORT]
ShopDataTable.tbItemToGoodsGiftBox = {}

local function IsCommonCurrencyId(nCurrencyId)
    for _, v in ipairs(COMMON_CURRENCY_IDS) do
        if v == nCurrencyId then
            return true
        end
    end
    return false
end

function ShopDataTable:OnEditorDefine(Parser)
    Parser:Define("nShopId", "id", -1, Parser.TypeInt)
    Parser:Define("l10nName", "name", L10N.NullString, Parser.TypeL10N)

    for i = 1, TAB_MAX do
        Parser:Define("l10nTabName"..i, "tab_name"..i, nil, Parser.TypeL10N)
    end

    Parser:Define("nMinId", "min_id", -1, Parser.TypeInt)
    Parser:Define("nMaxId", "max_id", -1, Parser.TypeInt)
    Parser:Define("szPath", "path", nil, Parser.TypeString)
end

function ShopDataTable:OnEditorParseLine(Parser, tbContainer, tbNewTemplate)
    local tbNames = {}
    for i = 1, TAB_MAX do
        local l10nName = tbNewTemplate["l10nTabName"..i]
        if l10nName ~= nil then
            table.insert(tbNames, l10nName)
        end
    end
    tbNewTemplate.tbNames = tbNames
    table.insert(self.tbShopInfos, tbNewTemplate)
    return true
end

function ShopDataTable:OnEditorParseSubLine(Parser, tbContainer, tbNewTemplate)
    local nId = tbNewTemplate.nId
    if nId < nCurrentMinId or nId > nCurrentMaxId then
        error("Parse Goods Id Not Valid! ShopId:"..nCurrentShopId
            ..", minId:".. nCurrentMinId..", maxId:"..nCurrentMaxId..",invalid id:"..nId)
    end
    tbNewTemplate.nShopId = nCurrentShopId

    local tbTabIds = tbNewTemplate.tbTabIds
    if tbTabIds == nil or #tbTabIds <= 0 then
        error("Goods tab id is empty！ShopId:"..nCurrentShopId..",Goods id:"..nId)
    end

    local bIsCommonCurrencyGoods = true
    local nCurrencyId1 = tbNewTemplate.nCurrencyId1
    local nCurrencyCount1 = tbNewTemplate.nCurrencyCount1
    if nCurrencyId1 <= 0 or nCurrencyCount1 < 0
        or ItemDataTable:GetTemplate(nCurrencyId1) == nil then
        error("Goods currency1 invalid！ShopId:"..nCurrentShopId..",Goods id:"..nId
            ..", nCurrencyId1:"..nCurrencyId1, ", nCurrencyCount1:"..nCurrencyCount1)
    end

    if nCurrencyCount1 == 0 then
        tbNewTemplate.bIsFree = true
    end

    if not IsCommonCurrencyId(nCurrencyId1) then
        bIsCommonCurrencyGoods = false
    end

    local nItemTemplateId = tbNewTemplate.nItemTemplateId
    local tbItemTemplate = ItemDataTable:GetTemplate(nItemTemplateId)
    if tbItemTemplate == nil then
        error("Goods item cannot find!ShopId:"..nCurrentShopId..",Goods id:"..nId..", item_id:"..nItemTemplateId)
    end

    tbNewTemplate.bHasSecondCurrencyPrice = false
    local nCurrencyId2 = tbNewTemplate.nCurrencyId2
    if nCurrencyId2 > 0 and tbNewTemplate.nCurrencyCount2 >= 0 then
        tbNewTemplate.bHasSecondCurrencyPrice = true
        if ItemDataTable:GetTemplate(nCurrencyId2) == nil then
            error("nCurrencyId2 invalid!ShopId:"..nCurrentShopId..",Goods id:"..nId..", nCurrencyId2:"..nCurrencyId2)
        end
        if not IsCommonCurrencyId(nCurrencyId2) then
            bIsCommonCurrencyGoods = false
        end
    end

    tbNewTemplate.bHasBuyLimit = false
    if tbNewTemplate.nBuyLimit > 0 then
        tbNewTemplate.bHasBuyLimit = true
    end

    tbNewTemplate.bHasBuyLimitRefreshMinute = false
    if tbNewTemplate.nBuyLimitRefreshMinute > 0 then
        tbNewTemplate.bHasBuyLimitRefreshMinute = true
        tbNewTemplate.nBuyLimitRefreshSeconds = tbNewTemplate.nBuyLimitRefreshMinute * 60
    end

    local szShelfTime = tbNewTemplate.szShelfTime
    tbNewTemplate.bHasShelfTime = false
    if szShelfTime then
        tbNewTemplate.bHasShelfTime = true
        local nTime, szError = TimeUtil.GetTimeByString(szShelfTime)

        if nTime == nil then
            error("parse shelf time failed!ShopId:"..nCurrentShopId..",Goods id:"..nId..", error:"..szError)
            return false
        end
        tbNewTemplate.nShelfTime = nTime

        if tbNewTemplate.nDurationMinutes == 0 then
            error("Goods has shelf_time! But do not has duration_minutes!ShopId:"..nCurrentShopId..",Goods id:"..nId)
        end
        tbNewTemplate.nDurationSeconds = tbNewTemplate.nDurationMinutes * 60
    end

    --discount time   
    local szDiscountTime = tbNewTemplate.szDiscountTime
    tbNewTemplate.bHasDiscountTime = false
    if szDiscountTime then
        tbNewTemplate.bHasDiscountTime = true
        local nTime, szError = TimeUtil.GetTimeByString(szDiscountTime)

        if nTime == nil then
            error("parse discount time failed!ShopId:"..nCurrentShopId..",Goods id:"..nId..", error:"..szError)
            return false
        end
        tbNewTemplate.nDiscountTime = nTime

        if tbNewTemplate.nDiscountDurationMins == 0 then
            error("Goods has discount time! But do not has discount duration_minutes!ShopId:"..nCurrentShopId..",Goods id:"..nId)
        end
        tbNewTemplate.nDiscountDurationSeconds = tbNewTemplate.nDiscountDurationMins * 60
        
    end

    if bIsCommonCurrencyGoods then
        self.tbItemToGoods[nItemTemplateId] = tbNewTemplate
    end

    if bIsCommonCurrencyGoods and tbItemTemplate.nCategory == ItemCategoryDef.GIFT_BOX then  
        self.tbItemToGoodsGiftBox[nItemTemplateId] = tbNewTemplate
    end

    self.tbContainer[nId] = tbNewTemplate

    local tbShopTemplates = self.tbShopGoods[nCurrentShopId]
    if tbShopTemplates == nil then
        self.tbShopGoods[nCurrentShopId] = {}
        tbShopTemplates = self.tbShopGoods[nCurrentShopId]
    end

    for _, v in ipairs(tbTabIds) do
        local tbTabTemplates = tbShopTemplates[v]
        if tbTabTemplates == nil then
            tbShopTemplates[v] = {}
            tbTabTemplates = tbShopTemplates[v]
        end
        table.insert(tbTabTemplates, tbNewTemplate)
    end

    return true
end

function ShopDataTable:OnEditorSubTableDefine(Parser)
    Parser:Define("nId", "id", -1, Parser.TypeInt)
    Parser:Define("tbTabIds", "tab_ids", {}, Parser.TypeArrayInt)
    Parser:Define("nCurrencyId1", "currency_id_1", 0, Parser.TypeInt)
    Parser:Define("nCurrencyCount1", "currency_count_1", -1, Parser.TypeInt)
    Parser:Define("nCurrencyId2", "currency_id_2", 0, Parser.TypeInt)
    Parser:Define("nCurrencyCount2", "currency_count_2", 0, Parser.TypeInt)
    Parser:Define("nItemTemplateId", "item_id", 0, Parser.TypeInt)
    Parser:Define("nBuyLimit", "buy_limit", 0, Parser.TypeInt)

    Parser:Define("nBuyLimitRefreshMinute", "buy_limit_refresh_minute", 0, Parser.TypeInt, false)
    Parser:Define("szShelfTime", "shelf_time", nil, Parser.TypeString, false)
    Parser:Define("nDurationMinutes", "duration_minutes", 0, Parser.TypeInt, false)

    Parser:Define("szDiscountTime", "discount_time", nil, Parser.TypeString, false)
    Parser:Define("nDiscountDurationMins", "discount_duration_minutes", 0, Parser.TypeInt, false)
    Parser:Define("nDiscountCurrencyId", "discount_currency_id", 0, Parser.TypeInt, false)
    Parser:Define("nDiscountRate", "discount", 0, Parser.TypeFloat, false)
    Parser:Define("bCompensation", "compensation", false, Parser.TypeBool, false)

    Parser:Define("nSortWeight", "sort_weight", 0, Parser.TypeInt)
end

function ShopDataTable:OnEditorParseFinished()
    if bLoadingSubFile then
        return
    end
    local szOldPath = self.szFileName
    bLoadingSubFile = true
    local fnOldDefine = self.OnEditorDefine
    local fnOldParseLine = self.OnEditorParseLine

    for _, v in ipairs(self.tbShopInfos) do
        self.szFileName = v.szPath
        self.OnEditorDefine = self.OnEditorSubTableDefine
        self.OnEditorParseLine = self.OnEditorParseSubLine
        nCurrentMinId = v.nMinId
        nCurrentMaxId = v.nMaxId
        nCurrentShopId = v.nShopId
        if not DataTableExporter:Load(self) then
            error("ShopDataTable load sub table failed".. self.szFileName)
        end
    end

    bLoadingSubFile = false
    self.OnEditorDefine = fnOldDefine
    self.OnEditorParseLine = fnOldParseLine
    self.szFileName = szOldPath
end

-- [EXPORT BEGIN]
function ShopDataTable:GetAllShopInfoArray()
    return self.tbShopInfos
end
-- [EXPORT END]

-- [EXPORT BEGIN]
function ShopDataTable:GetShopTabNames(nShopId)
    local tbShopTemplate = nil
    for _, v in ipairs(self.tbShopInfos) do
        if v.nShopId == nShopId then
            tbShopTemplate = v
            break
        end
    end
    if tbShopTemplate == nil then
        error("Cannot find tab names!ShopId:"..nShopId)
    end
    return tbShopTemplate.tbNames
end
-- [EXPORT END]

-- [EXPORT BEGIN]
function ShopDataTable:GetTemplate(nGoodsId)
    return self.tbContainer[nGoodsId]
end
-- [EXPORT END]

-- [EXPORT BEGIN]
function ShopDataTable:GetAllGoodsTemplate()
    return self.tbContainer
end
-- [EXPORT END]

-- [EXPORT BEGIN]
function ShopDataTable:GetTemplatesByShopIdAndTabId(nShopId, nTabId)
    local tbShopTemplates = self.tbShopGoods[nShopId]
    if tbShopTemplates == nil then
        error("Cannot find shop templates!ShopId:"..nShopId..", nTabId:"..nTabId)
    end
    local tbTabTemplates = tbShopTemplates[nTabId]
    if tbTabTemplates == nil then
        return {}
    end
    return tbTabTemplates
end
-- [EXPORT END]

-- [EXPORT BEGIN]
function ShopDataTable:GetItemGoodsTemplate(nItemTemplateId)
    return self.tbItemToGoods[nItemTemplateId]
end

function ShopDataTable:GetItemGiftBoxGoods()
    return self.tbItemToGoodsGiftBox
end
-- [EXPORT END]


return ShopDataTable

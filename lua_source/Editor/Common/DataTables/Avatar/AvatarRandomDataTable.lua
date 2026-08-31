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

local AvatarRandomDataTable = {}

local DataTableExporter = require("DataTableExporter")
local HumanAvatarDef = require("HumanAvatarDef")
local ItemDataTable = require("ItemDataTable")

local FILE_RELATIVE_DIR = "common/ffa/avatar/sub"
local FILE_NAME = "common/ffa/avatar/avatar_random.tab"

AvatarRandomDataTable.szFileName = FILE_NAME


local szContentDir = getcontentdir()
local SOURCE_ROOT_DIR = szContentDir.."GameData/"

local FashionSlotCategoryExtend = HumanAvatarDef.FashionSlotCategoryExtend
local tbTemp = {}
local tbCache = {}

local nTempSlotType = nil

local TOTAL_WEIGHT = 10000
local GENERATE_COUNT = 100

local tbSortedSlotTypes = nil

local function GetSortedSlotType()
    if not tbSortedSlotTypes then
        tbSortedSlotTypes = {}
        for _, nSlotType in pairs(FashionSlotCategoryExtend) do
            table.insert(tbSortedSlotTypes, nSlotType)
        end
        table.sort(tbSortedSlotTypes, function(nSlotType1, nSlotType2) return nSlotType1 < nSlotType2 end )
    end
    return tbSortedSlotTypes
end

local function ParseSubFile(self)
    for nSlotType, szFilePath in pairs(tbTemp) do
        nTempSlotType = nSlotType
        self.szFileName = szFilePath
        self.OnEditorDefine = self.OnEditorDefineSub
        self.OnEditorParseLine = self.OnEditorParseLineSub
        self.OnEditorParseFinished = nil
        local bLoadResult = DataTableExporter:Load(self)
        if not bLoadResult then
            error("AvatarRandomDataTable load sub table failed: "..szFilePath)
        end
    end
end

local function GenerateRandomSeed()
    local nResult = 0
    local szDir = SOURCE_ROOT_DIR..FILE_RELATIVE_DIR
    local tbPaths = EditorExtendFunctions.CollectPaths(szDir, ".tab", false)
    for _, szPath in ipairs(tbPaths) do
        local bResult, szHash = EditorExtendFunctions.GetFileMD5HashString(szPath)
        if bResult then
            local nValue = tonumber("0x"..szHash)
            nResult = nResult + nValue
        end
    end
    return nResult
end

local function SetRandomSeed()
    local nRandomSeed = GenerateRandomSeed()
    math.randomseed(nRandomSeed)
end


local function RandomOne(tbCandidates)
    local nResult
    if tbCandidates then
        local nRandom = math.random(0, TOTAL_WEIGHT)
        local nSumWeight = 0
        local nAverageWeight = nil
        local nRemainingCount = #tbCandidates
        for _, tbData in ipairs(tbCandidates) do
            local nWeight = tbData.nWeight
            if not nWeight then
                if not nAverageWeight or nRemainingCount == 1 then
                    nAverageWeight = (TOTAL_WEIGHT - nSumWeight) / nRemainingCount
                end
                nWeight = nAverageWeight
            end
            nSumWeight = nSumWeight + nWeight
            nRandom = nRandom - nWeight
            if nRandom <= 0 then
                nResult = tbData.nItemTemplateId
                break
            end
            nRemainingCount = nRemainingCount - 1
        end
    end
    return nResult
end

local function GenerateTableData(self)
    SetRandomSeed()
    local tbContainer = self.tbContainer
    for nPoolId, tbPoolData in pairs(tbCache) do
        local tbExportData = tbContainer[nPoolId]
        if not tbExportData then
            tbExportData = {}
            tbContainer[nPoolId] = tbExportData
        end
        local nRemainingCount = GENERATE_COUNT
        while(nRemainingCount > 0) do
            local tbTemplateList = {}
            for nFashionType, tbFashionCandidateData in pairs(tbPoolData) do
                -- 先随套装
                local tbSlotNoNeedRandom = {}
                tbSlotNoNeedRandom[FashionSlotCategoryExtend.Suit] = true
                local tbSuitSlotCandidates = tbFashionCandidateData[FashionSlotCategoryExtend.Suit]
                local nItemTemplateId = RandomOne(tbSuitSlotCandidates)
                if nItemTemplateId and nItemTemplateId > 0 then
                    local tbTemplate = ItemDataTable:GetTemplate(nItemTemplateId)
                    if not tbTemplate then
                        error("AvatarRandomDataTable error, suit item template id is illegal, id is " .. nItemTemplateId)
                    end
                    local tbPartItemList = tbTemplate.tbSubItemTemplateIds
                    for _, nPartItemTemplateId in ipairs(tbPartItemList) do
                        local tbPartItemTemplate = ItemDataTable:GetTemplate(nPartItemTemplateId)
                        if not tbPartItemTemplate then
                            error("AvatarRandomDataTable error, part of suit item template id is illegal, id is " .. nPartItemTemplateId)
                        end
                        tbSlotNoNeedRandom[tbPartItemTemplate.nSubCategory] = true
                        local tbOverlaySlots = tbPartItemTemplate.tbOverlaySlots
                        for _, nOverlaySlot in ipairs(tbOverlaySlots) do
                            tbSlotNoNeedRandom[tbPartItemTemplate.nSubCategory] = true
                        end
                        table.insert(tbTemplateList, nPartItemTemplateId)
                    end
                end

                -- 根据套装包含的散件部位以及散件部位的补集来随散件
                local SortedSlotTypes = GetSortedSlotType()
                for _, nSlotType in ipairs(SortedSlotTypes) do
                    if nSlotType ~= FashionSlotCategoryExtend.Suit then
                        local tbSlotCandidateData = tbFashionCandidateData[nSlotType]
                        if tbSlotCandidateData then
                            if not tbSlotNoNeedRandom[nSlotType] then
                                nItemTemplateId = RandomOne(tbSlotCandidateData)
                                if nItemTemplateId and nItemTemplateId > 0 then
                                    table.insert(tbTemplateList, nItemTemplateId)
                                end
                            end
                        end
                    end
                end
            end
            table.insert(tbExportData, tbTemplateList)
            nRemainingCount = nRemainingCount - 1
        end
    end
end

function AvatarRandomDataTable:OnEditorDefine(Parser)
    Parser:Define("nSlotType",  "slot_type",  -1, Parser.TypeInt)
    Parser:Define("szFilePath", "file_path", nil, Parser.TypeString)
end

function AvatarRandomDataTable:OnEditorParseLine(Parser, tbContainer, tbNewTemplate)
    tbTemp[tbNewTemplate.nSlotType] = tbNewTemplate.szFilePath
    return true
end

function AvatarRandomDataTable:OnEditorParseFinished()
    ParseSubFile(self)
    GenerateTableData(self)
end

function AvatarRandomDataTable:OnEditorDefineSub(Parser)
    Parser:Define("nId",              "id",               -1, Parser.TypeInt)
    Parser:Define("nFashionType",     "fashion_type",     -1, Parser.TypeInt)
    Parser:Define("nItemTemplateId",  "item_template_id", -1, Parser.TypeInt)
    Parser:Define("nWeight",          "weight",           -1, Parser.TypeInt)
end


function AvatarRandomDataTable:OnEditorParseLineSub(Parser, tbContainer, tbNewTemplate)
    local nPoolId = tbNewTemplate.nId
    local tbDataForPool = tbCache[nPoolId]
    if not tbDataForPool then
        tbDataForPool = {}
        tbCache[nPoolId] = tbDataForPool
    end

    local nFashionType = tbNewTemplate.nFashionType
    local tbDataForFashionType = tbDataForPool[nFashionType]
    if not tbDataForFashionType then
        tbDataForFashionType = {}
        tbDataForPool[nFashionType] = tbDataForFashionType
    end

    local tbDataForSlot = tbDataForFashionType[nTempSlotType]
    if not tbDataForSlot then
        tbDataForSlot = {}
        tbDataForFashionType[nTempSlotType] = tbDataForSlot
    end

    local tbData = {}
    tbData.nItemTemplateId = tbNewTemplate.nItemTemplateId
    local nWeight = tbNewTemplate.nWeight
    if nWeight > 0 then
        table.insert(tbDataForSlot, 1, tbData)
        tbData.nWeight = nWeight
    else
        table.insert(tbDataForSlot, tbData)
    end
    return true
end

-- [EXPORT BEGIN]
-- 返回随机出的时装道具列表 {itemTemplateId1, itemTemplateId2, ...}
function AvatarRandomDataTable:RandomAvatar(nId)
    local tbPoolData = self.tbContainer[nId]
    if tbPoolData then
        local nCount = #tbPoolData
        if nCount > 0 then
            local nIndex = math.random(0, nCount)
            return tbPoolData[nIndex]
        end
    end
    return {}
end

-- [EXPORT END]

return AvatarRandomDataTable
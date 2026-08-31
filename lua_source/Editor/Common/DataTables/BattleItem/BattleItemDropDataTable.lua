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
local BattleItemDropGroupDataTable = require("BattleItemDropGroupDataTable")
local BattleItemDataTable = require("BattleItemDataTable")
local BattleItemCategoryDef = require("BattleItemCategoryDef")

local BattleItemDropDataTable = {}

local DataTableExporter = require("DataTableExporter")

BattleItemDropDataTable.szFileName = "common/ffa/item/item_drop/item_drop.tab"

local bLoadingSubFile = false

local nCurrentMinId = -1
local nCurrentMaxId = -1
local nCurrentItemDropId = -1
local bCurrentReplacement = true
local bCurrentMerge = false

-- [EXPORT]
BattleItemDropDataTable.tbItemDropInfoTable = {}

function BattleItemDropDataTable:OnEditorDefine(Parser)
    Parser:Define("nId", "id", -1, Parser.TypeInt)
    Parser:Define("bReplacement", "replacement", true, Parser.TypeBool)
    Parser:Define("bMerge", "merge", false, Parser.TypeBool)
    Parser:Define("nMinId", "min_id", -1, Parser.TypeInt)
    Parser:Define("nMaxId", "max_id", -1, Parser.TypeInt)
    Parser:Define("szPath", "path", nil, Parser.TypeString)
end

function BattleItemDropDataTable:OnEditorParseLine(Parser, tbContainer, tbNewTemplate)
    local tbItemDropInfoTable = self.tbItemDropInfoTable
    if tbItemDropInfoTable[tbNewTemplate.nId] ~= nil then
        error("BattleItemDropDataTable "..self.szFileName.." contains dup key: "..tbNewTemplate.nId)
        return false
    end
    tbItemDropInfoTable[tbNewTemplate.nId] = tbNewTemplate
    return true
end

function BattleItemDropDataTable:OnEditorSubTableDefine(Parser)
    Parser:Define("nDropId", "drop_id", -1, Parser.TypeInt)
    Parser:Define("nDropGroupId", "drop_group_id", -1, Parser.TypeInt)
    Parser:Define("nMinCount", "min_count", -1, Parser.TypeInt)
    Parser:Define("nMaxCount", "max_count", -1, Parser.TypeInt)
    Parser:Define("nSceneItemPackage", "scene_item_package", -1, Parser.TypeInt)
end

function BattleItemDropDataTable:OnEditorParseSubLine(Parser, tbContainer, tbNewTemplate)
    local nDropId = tbNewTemplate.nDropId
    if nDropId < nCurrentMinId or nDropId > nCurrentMaxId then
        error("Parse Drop Id Not Valid! Table:"..self.szFileName
        ..", Id:".. nCurrentItemDropId
        ..", minId:".. nCurrentMinId..", maxId:"..nCurrentMaxId..",invalid drop id:"..nDropId)
    end

    local tbDrop = self.tbContainer[nDropId]
    if tbDrop and tbDrop.nSceneItemPackage ~= tbNewTemplate.nSceneItemPackage then
        error("scene_item_package collision ! Table:"..self.szFileName
        ..", scene_item_package1:".. tbDrop.nSceneItemPackage
        ..", scene_item_package2:".. tbNewTemplate.nSceneItemPackage..",invalid drop id:"..nDropId)
    end
    if not tbDrop then
        self.tbContainer[nDropId] = {}
        tbDrop = self.tbContainer[nDropId]
        tbDrop.nItemDropId = nCurrentItemDropId
        tbDrop.bReplacement = bCurrentReplacement
        tbDrop.bMerge = bCurrentMerge
        tbDrop.nSceneItemPackage = tbNewTemplate.nSceneItemPackage
        tbDrop.tbDropGroups = {}
    end
    table.insert(tbDrop.tbDropGroups, tbNewTemplate)
    return true
end

local function Validate(self)
    local tbContainer = self.tbContainer
    for _, tbDrop in pairs(tbContainer) do
        for _, tbGroup in ipairs(tbDrop.tbDropGroups) do
            local tbDropGroup = BattleItemDropGroupDataTable:GetDropGroup(tbGroup.nDropGroupId)
            if not tbDropGroup then
                error(self.szFileName.." configure error. DropGroupId: "..tbGroup.nDropGroupId.." not found in drop group tab file.")
                return false
            end
            if not tbDrop.bReplacement then
                if tbGroup.nMaxCount > #tbDropGroup then
                    error(self.szFileName.." configure error. DropGroupId: "..tbGroup.nDropGroupId.." non-replacement drop's max-count exceed the count of drop group choices in drop group tab file.")
                    return false
                end
            end
        end
        local nSceneItemPackage = tbDrop.nSceneItemPackage
        if nSceneItemPackage and nSceneItemPackage > 0 then
            local tbSceneItemPackage = BattleItemDataTable:GetTemplate(nSceneItemPackage)
            if (not tbSceneItemPackage) or (tbSceneItemPackage.nCategory ~= BattleItemCategoryDef.SCENE_ITEM_PACKAGE) then
                error(self.szFileName.." configure error. nDropId: "..tbDrop.nItemDropId..". Invalid scene_item_package: "..nSceneItemPackage)
            end
        end
    end
    return true
end

function BattleItemDropDataTable:OnEditorParseFinished()
    if bLoadingSubFile then
        return
    end
    local szOldPath = self.szFileName
    bLoadingSubFile = true
    local fnOldDefine = self.OnEditorDefine
    local fnOldParseLine = self.OnEditorParseLine

    for _, value in pairs(self.tbItemDropInfoTable) do
        self.szFileName = value.szPath
        self.OnEditorDefine = self.OnEditorSubTableDefine
        self.OnEditorParseLine = self.OnEditorParseSubLine
        nCurrentMinId = value.nMinId
        nCurrentMaxId = value.nMaxId
        nCurrentItemDropId = value.nId
        bCurrentReplacement = value.bReplacement
        bCurrentMerge = value.bMerge
        if not DataTableExporter:Load(self) then
            logerror("BattleItemDropDataTable load sub table failed", self.szFileName)
            assert(false)
        end
    end

    bLoadingSubFile = false
    self.OnEditorDefine = fnOldDefine
    self.OnEditorParseLine = fnOldParseLine
    self.szFileName = szOldPath

    Validate(self)
end

-- {
--     nItemDropId,
--     bReplacement,
--     bMerge,
--     tbDropGroups {
--         {
--             nDropId,
--             nDropGroupId,
--             nMinCount,
--             nMaxCount
--         },
--         ...
--     }
-- }
-- [EXPORT BEGIN]
function BattleItemDropDataTable:GetDropRule(nDropId)
    return self.tbContainer[nDropId]
end
-- [EXPORT END]

return BattleItemDropDataTable

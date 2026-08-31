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

local HomelandSceneDataTable = {}

local L10N = require("L10N")
local DataTableExporter = require("DataTableExporter")
local DescriptorExporter = require("DescriptorExporter")
local LandmarkBuildingTypeDataTable = require("LandmarkBuildingTypeDataTable")
local RegionDataTable = require("RegionDataTable")
local BlockTypeDataTable = require("BlockTypeDataTable")

HomelandSceneDataTable.szFileName = "common/homeland/homeland_scene.tab"

-- [EXPORT]
HomelandSceneDataTable.tbSceneTemplates = {}

-- [EXPORT]
HomelandSceneDataTable.tbSceneBlockTemplates = {}

local bLoadingSubFile = false

local nCurrentMinId = -1
local nCurrentMaxId = -1
local nCurrentSceneId = -1

function HomelandSceneDataTable:OnEditorDefine(Parser)
    Parser:Define("nId", "id", -1, Parser.TypeInt)
    Parser:Define("l10nName", "name", L10N.NullString, Parser.TypeL10N)
    Parser:Define("l10nDesc", "desc", L10N.NullString, Parser.TypeL10N)
    Parser:Define("szSceneBlockPath", "scene_block_path", nil, Parser.TypeString)
    Parser:Define("nMinId", "block_id_min", -1, Parser.TypeInt)
    Parser:Define("nMaxId", "block_id_max", -1, Parser.TypeInt)
    Parser:Define("nResId", "res_id", -1, Parser.TypeInt)
    Parser:Define("szIcon", "icon", "", Parser.TypeString)
    Parser:Define("szBackground", "big_image", "", Parser.TypeString)
    Parser:Define("nSubLevelResId", "sublevel_res_id", -1, Parser.TypeInt)
    Parser:Define("szLogicLevelName", "logic_level_name", "", Parser.TypeString)
    Parser:Define("nUnlockLandmarkType", "unlock_landmark_type", -1, Parser.TypeInt)
    Parser:Define("nUnlockLandmarkGrade", "unlock_landmark_grade", -1, Parser.TypeInt)
    Parser:Define("nCurrencyId", "currency_id", -1, Parser.TypeInt)
    Parser:Define("nPrice", "price", 0, Parser.TypeInt)
end

function HomelandSceneDataTable:OnEditorParseLine(Parser, tbContainer, tbNewTemplate)
    self.tbSceneTemplates[tbNewTemplate.nId] = tbNewTemplate
    return true
end

function HomelandSceneDataTable:OnEditorParseSubLine(Parser, tbContainer, tbNewTemplate)
    local nId = tbNewTemplate.nId
    if nId < nCurrentMinId or nId > nCurrentMaxId then
        error("Parse Homeland block Id Not Valid! nSceneId:"..nCurrentSceneId
            ..", minId:".. nCurrentMinId..", maxId:"..nCurrentMaxId..",invalid id:"..nId)
    end

    tbNewTemplate.nSceneId = nCurrentSceneId

    tbNewTemplate.bHasDefaultLandmark = false
    local nDefaultLandmarkType = tbNewTemplate.nDefaultLandmarkType
    if nDefaultLandmarkType ~= nil and nDefaultLandmarkType > 0 then
        tbNewTemplate.bHasDefaultLandmark = true
        if not LandmarkBuildingTypeDataTable:GetTemplate(nDefaultLandmarkType) then
            error("Cannot find nDefaultLandmarkType! nSceneId: "..nCurrentSceneId.. ", nId: "..nId.. ", nDefaultLandmarkType,"..nDefaultLandmarkType)
        end
    end

    local nUnlockLandmarkType = tbNewTemplate.nUnlockLandmarkType
    local nUnlockLandmarkGrade = tbNewTemplate.nUnlockLandmarkGrade
    tbNewTemplate.bNeedUnlock = false
    if nUnlockLandmarkGrade ~= nil and nUnlockLandmarkGrade > 0 then
        tbNewTemplate.bNeedUnlock = true
        if nUnlockLandmarkType == nil then
            error("nUnlockLandmarkType is nil! nSceneId: "..nCurrentSceneId.. ", nId: "..nId)
        end
        if not LandmarkBuildingTypeDataTable:GetTemplate(nUnlockLandmarkType) then
            error("Cannot find nUnlockLandmarkType! nSceneId: "..nCurrentSceneId.. ", nId: "..nId.. ", nUnlockLandmarkType,"..nUnlockLandmarkType)
        end
    end

    tbNewTemplate.bNeedBuy = false
    local nPrice = tbNewTemplate.nPrice
    if nPrice ~= nil and nPrice > 0 then
        tbNewTemplate.bNeedBuy = true
        local nCurrencyId = tbNewTemplate.nCurrencyId
        if nCurrencyId == nil or nCurrencyId <= 0 then
            error("block need buy!but cannot find currency id! nSceneId:"..nCurrentSceneId..",invalid id:"..nId)
        end
    end

    local nBlockType = tbNewTemplate.nBlockType

    if nBlockType == nil or not BlockTypeDataTable:GetTemplate(nBlockType) then
        error("Cannot find nBlockType! nSceneId: "..nCurrentSceneId.. ", nId: "..nId.. ", nBlockType,"..nBlockType)
    end

    local nRegionId = tbNewTemplate.nRegionId
    if nRegionId == nil or not RegionDataTable:GetTemplate(nRegionId) then
        error("Cannot find nRegionId! nSceneId: "..nCurrentSceneId.. ", nId: "..nId.. ", nRegionId,"..nRegionId)
    end

    self.tbContainer[nId] = tbNewTemplate

    local tbBlockTemplates = self.tbSceneBlockTemplates[nCurrentSceneId]
    if tbBlockTemplates == nil then
        self.tbSceneBlockTemplates[nCurrentSceneId] = {}
        tbBlockTemplates = self.tbSceneBlockTemplates[nCurrentSceneId]
    end
    table.insert(tbBlockTemplates, tbNewTemplate)
    return true
end

function HomelandSceneDataTable:OnEditorSubTableDefine(Parser)
    Parser:Define("nId", "id", -1, Parser.TypeInt)

    Parser:Define("nBlockType", "block_type", -1, Parser.TypeInt)
    Parser:Define("nDefaultLandmarkType", "default_landmark_type", -1, Parser.TypeInt)
    Parser:Define("nRegionId", "region_id", -1, Parser.TypeInt)
    Parser:Define("nUnlockLandmarkType", "unlock_landmark_type", -1, Parser.TypeInt)
    Parser:Define("nUnlockLandmarkGrade", "unlock_landmark_grade", -1, Parser.TypeInt)
    Parser:Define("nCurrencyId", "currency_id", -1, Parser.TypeInt)
    Parser:Define("nPrice", "price", 0, Parser.TypeInt)
end

function HomelandSceneDataTable:OnEditorParseFinished()
    if bLoadingSubFile then
        return
    end
    local szOldPath = self.szFileName
    bLoadingSubFile = true
    local fnOldDefine = self.OnEditorDefine
    local fnOldParseLine = self.OnEditorParseLine

    for k, v in pairs(self.tbSceneTemplates) do
        self.szFileName = v.szSceneBlockPath
        self.OnEditorDefine = self.OnEditorSubTableDefine
        self.OnEditorParseLine = self.OnEditorParseSubLine
        nCurrentMinId = v.nMinId
        nCurrentMaxId = v.nMaxId
        nCurrentSceneId = v.nId
        if not DataTableExporter:Load(self) then
            error("ItemDataTable load sub table failed".. self.szFileName)
        end
    end

    bLoadingSubFile = false
    self.OnEditorDefine = fnOldDefine
    self.OnEditorParseLine = fnOldParseLine
    self.szFileName = szOldPath

    local tbAllDescriptors = {}
    for _, tbTemplate in pairs(self.tbSceneTemplates) do
        DescriptorExporter:ExportSingleSceneData(tbAllDescriptors, tbTemplate, tbTemplate.nResId, tbTemplate.szLogicLevelName, tbTemplate.szLogicLevelName)
    end
end

-- [EXPORT BEGIN]
function HomelandSceneDataTable:GetAllSceneTemplates()
    return self.tbSceneTemplates
end
-- [EXPORT END]

-- [EXPORT BEGIN]
function HomelandSceneDataTable:GetSceneTemplate(nSceneId)
    return self.tbSceneTemplates[nSceneId]
end
-- [EXPORT END]

-- [EXPORT BEGIN]
function HomelandSceneDataTable:GetSceneBlockTemplates(nSceneId)
    return self.tbSceneBlockTemplates[nSceneId]
end
-- [EXPORT END]

-- [EXPORT BEGIN]
function HomelandSceneDataTable:GetAllSceneBlockTemplates()
    return self.tbSceneBlockTemplates
end
-- [EXPORT END]

-- [EXPORT BEGIN]
function HomelandSceneDataTable:GetBlockTemplate(nBlockId)
    return self.tbContainer[nBlockId]
end
-- [EXPORT END]

-- [EXPORT BEGIN]
function HomelandSceneDataTable:GetSceneDescriptor(nId)
    local tbData = self.tbSceneTemplates[nId]
    if(tbData == nil or tbData.szLogicLevelName == nil) then
        return nil
    end
    local tbRet = tbData.tbDescriptor
    if(tbRet == nil) then
        tbRet = require(tbData.szLogicLevelName)
        tbData.tbDescriptor = tbRet
    end
    return tbRet
end
-- [EXPORT END]

return HomelandSceneDataTable

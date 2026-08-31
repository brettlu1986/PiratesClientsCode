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
local BuildingDataTable = {}

local LandmarkBuildingTypeDataTable = require("LandmarkBuildingTypeDataTable")
local HomelandSceneDataTable = require("HomelandSceneDataTable")
local HomelandResDataTable = require("HomelandResDataTable")

BuildingDataTable.szFileName = "common/homeland/building.tab"

-- [EXPORT]
BuildingDataTable.tbSceneLandmarks = {}

function BuildingDataTable:OnEditorDefine(Parser)
    Parser:SetKey("nId")
    Parser:Define("nId"                  , "id"                     , -1, Parser.TypeInt)
    Parser:Define("nSceneId"             , "scene_id"               , -1, Parser.TypeInt)
    Parser:Define("nLandmarkType"        , "landmark_type"          , -1, Parser.TypeInt)
    Parser:Define("nGrade"               , "grade"                  , -1, Parser.TypeInt)
    Parser:Define("nDefaultRotation"     , "default_rotation"       , -1, Parser.TypeInt)
    Parser:Define("nResId"               , "res_id"                 , -1, Parser.TypeInt)
    Parser:Define("nLength"              , "length"                 , -1, Parser.TypeInt)
    Parser:Define("nWidth"               , "width"                  , -1, Parser.TypeInt)
end

function BuildingDataTable:OnEditorParseLine(Parser, tbContainer, tbNewTemplate)
    local nId = tbNewTemplate.nId
    local nSceneId = tbNewTemplate.nSceneId
    local nLandmarkType = tbNewTemplate.nLandmarkType

    if nLandmarkType ~= nil and nLandmarkType > 0 then
        if not LandmarkBuildingTypeDataTable:GetTemplate(nLandmarkType) then
            error("Cannot find nLandmarkType!nId: "..nId.. ",nLandmarkType,"..nLandmarkType)
        end
        if nSceneId == nil or nSceneId < 0 then
            error("LandMark building nSceneId is nil or less then 0!"..nId..", nSceneId:"..nSceneId)
        end
        if not HomelandSceneDataTable:GetSceneTemplate(nSceneId) then
            error("LandMark building cannot find sceneid!"..nId..", nSceneId:"..nSceneId)
        end

        local nGrade = tbNewTemplate.nGrade
        if nGrade == nil or nGrade < 0 then
            error("LandMark building grade error!"..nId..", nGrade:"..nGrade)
        end

        local tbSceneData = self.tbSceneLandmarks[nSceneId]
        if tbSceneData == nil then
            self.tbSceneLandmarks[nSceneId] = {}
            tbSceneData = self.tbSceneLandmarks[nSceneId]
        end
        local tbLandmardDatas = tbSceneData[nLandmarkType]
        if tbLandmardDatas == nil then
            tbSceneData[nLandmarkType] = {}
            tbLandmardDatas = tbSceneData[nLandmarkType]
        end
        tbLandmardDatas[nGrade] = tbNewTemplate
    end

    local nLength = tbNewTemplate.nLength
    local nWidth = tbNewTemplate.nWidth
    if nLength == nil or nLength <= 0 or nWidth == nil or nWidth <= 0 then
        error("length or width less than 0!nId: "..nId..", nLength:"..nLength..", nWidth:"..nWidth)
    end
    local tbHomelandResTemplate = HomelandResDataTable:GetTemplate(tbNewTemplate.nResId)
    if not tbHomelandResTemplate then
        error("Cannot find HomelandResTemplate!nId: "..nId.. ",nResId,"..tbNewTemplate.nResId)
    end
    tbNewTemplate.szModelRes = tbHomelandResTemplate.szModelPath
    tbNewTemplate.szIcon = tbHomelandResTemplate.szIcon
    return true
end

-- [EXPORT BEGIN]
function BuildingDataTable:GetTemplate(nId)
    return self.tbContainer[nId]
end
-- [EXPORT END]

-- [EXPORT BEGIN]
function BuildingDataTable:GetLandmarkTemplate(nSceneId, nLandmarkType, nGrade)
    local tbSceneData = self.tbSceneLandmarks[nSceneId]
    if tbSceneData == nil then
        error("Cannot find scene landmark!nSceneId"..nSceneId..", nLandmarkType"..nLandmarkType..", nGrade"..nGrade)
    end
    local tbLandmardData = tbSceneData[nLandmarkType]
    if tbLandmardData == nil then
        error("Cannot find scene landmark!nSceneId"..nSceneId..", nLandmarkType"..nLandmarkType..", nGrade"..nGrade)
    end
    local tbTemplate = tbLandmardData[nGrade]
    if tbTemplate == nil then
        error("Cannot find scene landmark!nSceneId"..nSceneId..", nLandmarkType"..nLandmarkType..", nGrade"..nGrade)
    end
    return tbTemplate
end
-- [EXPORT END]

return BuildingDataTable

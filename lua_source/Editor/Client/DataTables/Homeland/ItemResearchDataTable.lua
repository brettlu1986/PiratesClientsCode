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
local ItemResearchDataTable = {}

local LandmarkBuildingTypeDataTable = require("LandmarkBuildingTypeDataTable")

ItemResearchDataTable.szFileName = "common/homeland/research/item_research.tab"

-- [EXPORT]
ItemResearchDataTable.tbSceneLandmarks = {}

function ItemResearchDataTable:OnEditorDefine(Parser)
    Parser:SetKey("nItemId")
    Parser:Define("nItemId"              , "item_id"                     , -1, Parser.TypeInt)
    Parser:Define("nUnlockLandmarkType"  , "unlock_landmark_type"        , -1, Parser.TypeInt)
    Parser:Define("nUnlockLandmarkGrade" , "unlock_landmark_grade"       , -1, Parser.TypeInt)
    Parser:Define("nCurrencyId"          , "currency_id"                 , -1, Parser.TypeInt)
    Parser:Define("nCurrencyCost"        , "currency_cost"               , -1, Parser.TypeInt)
    Parser:Define("nTimeCost"            , "time_cost"                   , -1, Parser.TypeInt)
end

function ItemResearchDataTable:OnEditorParseLine(Parser, tbContainer, tbNewTemplate)
    local nItemId = tbNewTemplate.nItemId
    local nUnlockLandmarkType = tbNewTemplate.nUnlockLandmarkType

    if nUnlockLandmarkType ~= nil and nUnlockLandmarkType > 0 then
        if not LandmarkBuildingTypeDataTable:GetTemplate(nUnlockLandmarkType) then
            error("Cannot find nUnlockLandmarkType!nItemId: "..nItemId.. ",nUnlockLandmarkType,"..nUnlockLandmarkType)
        end
        local nUnlockLandmarkGrade = tbNewTemplate.nUnlockLandmarkGrade
        if nUnlockLandmarkGrade == nil or nUnlockLandmarkGrade <= 0 then
            error("LandMark building grade error!"..nItemId..", nGrade:"..nUnlockLandmarkGrade)
        end
    end
    return true
end

-- [EXPORT BEGIN]
function ItemResearchDataTable:GetTemplate(nId)
    return self.tbContainer[nId]
end
-- [EXPORT END]

return ItemResearchDataTable

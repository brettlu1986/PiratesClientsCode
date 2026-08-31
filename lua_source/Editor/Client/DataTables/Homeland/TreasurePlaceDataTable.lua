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
local TreasurePlaceDataTable = {}

TreasurePlaceDataTable.szFileName = "client/homeland/treasure_place.tab"


function TreasurePlaceDataTable:OnEditorDefine(Parser)
    Parser:Define("nSceneId"            , "scene_id"              , -1, Parser.TypeInt)
    Parser:Define("nMinValue"            , "min_value"              , -1, Parser.TypeInt)
    Parser:Define("szResPath"            , "res_path"               , "", Parser.TypeString)
end

function TreasurePlaceDataTable:OnEditorParseLine(Parser, tbContainer, tbNewTemplate)
    local nSceneId = tbNewTemplate.nSceneId
    local tbData = tbContainer[nSceneId]
    if not tbData then
        tbData = {}
        tbContainer[nSceneId] = tbData
    end
    table.insert(tbData, tbNewTemplate)
    return true
end

function TreasurePlaceDataTable:OnEditorParseFinished()
    for nSceneId, tbDatas in pairs(self.tbContainer) do
        table.sort(tbDatas, function(v1, v2) return v1.nMinValue > v2.nMinValue end)
    end
end

-- [EXPORT BEGIN]
-- 按nMinValue从大到小
function TreasurePlaceDataTable:GetAllTemplates(nSceneId)
    return self.tbContainer[nSceneId]
end
-- [EXPORT END]

return TreasurePlaceDataTable
